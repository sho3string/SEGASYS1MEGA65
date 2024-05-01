----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.video_modes_pkg.all;

entity main is
   generic (
      G_VDNUM                 : natural                     -- amount of virtual drives
   );
   port (
      clk_main_i              : in  std_logic;
      reset_soft_i            : in  std_logic;
      reset_hard_i            : in  std_logic;
      pause_i                 : in  std_logic;
      dim_video_o             : out std_logic;

      -- MiSTer core main clock speed:
      -- Make sure you pass very exact numbers here, because they are used for avoiding clock drift at derived clocks
      clk_main_speed_i        : in  natural;

      -- Video output
      video_ce_o              : out std_logic;
      video_ce_ovl_o          : out std_logic;
      video_red_o             : out std_logic_vector(2 downto 0);
      video_green_o           : out std_logic_vector(2 downto 0);
      video_blue_o            : out std_logic_vector(1 downto 0);
      video_vs_o              : out std_logic;
      video_hs_o              : out std_logic;
      video_hblank_o          : out std_logic;
      video_vblank_o          : out std_logic;

      -- Audio output (Signed PCM)
      audio_left_o            : out signed(15 downto 0);
      audio_right_o           : out signed(15 downto 0);

      -- M2M Keyboard interface
      kb_key_num_i            : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i      : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?

      -- MEGA65 joysticks and paddles/mouse/potentiometers
      joy_1_up_n_i            : in  std_logic;
      joy_1_down_n_i          : in  std_logic;
      joy_1_left_n_i          : in  std_logic;
      joy_1_right_n_i         : in  std_logic;
      joy_1_fire_n_i          : in  std_logic;

      joy_2_up_n_i            : in  std_logic;
      joy_2_down_n_i          : in  std_logic;
      joy_2_left_n_i          : in  std_logic;
      joy_2_right_n_i         : in  std_logic;
      joy_2_fire_n_i          : in  std_logic;

      pot1_x_i                : in  std_logic_vector(7 downto 0);
      pot1_y_i                : in  std_logic_vector(7 downto 0);
      pot2_x_i                : in  std_logic_vector(7 downto 0);
      pot2_y_i                : in  std_logic_vector(7 downto 0);
      
       -- Dipswitches
      dsw_a_i                 : in  std_logic_vector(7 downto 0);
      dsw_b_i                 : in  std_logic_vector(7 downto 0);

      dn_clk_i                : in  std_logic;
      dn_addr_i               : in  std_logic_vector(17 downto 0);
      dn_data_i               : in  std_logic_vector(7 downto 0);
      dn_wr_i                 : in  std_logic;

      
      osm_control_i      : in  std_logic_vector(255 downto 0)
      
   );
end entity main;

architecture synthesis of main is

signal keyboard_n        : std_logic_vector(79 downto 0);
signal pause_cpu         : std_logic;
signal status            : signed(31 downto 0);
signal flip_screen       : std_logic;
signal flip              : std_logic := '0';
signal forced_scandoubler: std_logic;
signal gamma_bus         : std_logic_vector(21 downto 0);
signal audio             : std_logic_vector(15 downto 0);


-- I/O board button press simulation ( active high )
-- b[1]: user button
-- b[0]: osd button

signal buttons           : std_logic_vector(1 downto 0);
signal reset             : std_logic  := reset_hard_i or reset_soft_i;

-- highscore system
signal hs_address       : std_logic_vector(15 downto 0);
signal hs_data_in       : std_logic_vector(7 downto 0);
signal hs_data_out      : std_logic_vector(7 downto 0);
signal hs_write_enable  : std_logic;

signal hs_pause         : std_logic;
signal options          : std_logic_vector(1 downto 0);
signal self_test        : std_logic;

-- Game player inputs
constant m65_1             : integer := 56; --Player 1 Start
constant m65_2             : integer := 59; --Player 2 Start
constant m65_5             : integer := 16; --Insert coin 1
constant m65_6             : integer := 19; --Insert coin 2

-- Offer some keyboard controls in addition to Joy 1 Controls
constant m65_up_crsr       : integer := 73; --Player up
constant m65_vert_crsr     : integer := 7;  --Player down
constant m65_left_crsr     : integer := 74; --Player left
constant m65_horz_crsr     : integer := 2;  --Player right
constant m65_left_shift    : integer := 15; --Trigger 1
constant m65_mega          : integer := 61; --Trigger 2
constant m65_p             : integer := 41; --Pause button
constant m65_s             : integer := 13; --Service 1
constant m65_d             : integer := 18; --Service Mode
constant m65_help          : integer := 67; --Help key

-- Menu controls

constant C_MENU_OSMPAUSE     : natural := 2;
constant C_MENU_OSMDIM       : natural := 3;
constant C_MENU_FLIP         : natural := 9;

constant C_MENU_SEGAWB_H1  : integer := 32;
constant C_MENU_SEGAWB_H2  : integer := 33;
constant C_MENU_SEGAWB_H4  : integer := 34;
constant C_MENU_SEGAWB_H8  : integer := 35;
constant C_MENU_SEGAWB_H16 : integer := 36;

constant C_MENU_SEGAWB_V1  : integer := 42;
constant C_MENU_SEGAWB_V2  : integer := 43;
constant C_MENU_SEGAWB_V4  : integer := 44;

signal PCLK_EN             : std_logic;
signal HPOS,VPOS           : std_logic_vector(8 downto 0);
signal POUT                : std_logic_vector(7 downto 0);
signal oRGB                : std_logic_vector(7 downto 0);
signal HOFFS               : std_logic_vector(4 downto 0);
signal VOFFS               : std_logic_vector(2 downto 0);

-- pause related logic
signal dim_video           : std_logic := '0';


begin
   
    audio_left_o(15) <= not audio(15);
    audio_left_o(14 downto 0) <= signed(audio(14 downto 0));
    audio_right_o(15) <= not audio(15);
    audio_right_o(14 downto 0) <= signed(audio(14 downto 0));
   
    options(0)  <= osm_control_i(C_MENU_OSMPAUSE);
    options(1)  <= osm_control_i(C_MENU_OSMDIM);
    flip_screen <= osm_control_i(C_MENU_FLIP);

    -- video
    PCLK_EN     <=  video_ce_o;
    oRGB        <=  video_blue_o & video_green_o & video_red_o;
    
    -- video crt offsets
    HOFFS <=   osm_control_i(C_MENU_SEGAWB_H16)  &
               osm_control_i(C_MENU_SEGAWB_H8)   &
               osm_control_i(C_MENU_SEGAWB_H4)   &
               osm_control_i(C_MENU_SEGAWB_H2)   &
               osm_control_i(C_MENU_SEGAWB_H1);
               
    VOFFS <=   osm_control_i(C_MENU_SEGAWB_V4)   &
               osm_control_i(C_MENU_SEGAWB_V2)   &
               osm_control_i(C_MENU_SEGAWB_V1);
              
    
    
    i_hvgen : entity work.hvgen
      port map (
         HPOS       => HPOS,
         VPOS       => VPOS,
         CLK        => clk_main_i,
         PCLK_EN    => PCLK_EN,
         iRGB       => POUT,
         oRGB       => oRGB,
         HBLK       => video_hblank_o,
         VBLK       => video_vblank_o,
         HSYN       => video_hs_o,
         VSYN       => video_vs_o,
         H240       => '0',
         HOFFS      => "000"   & HOFFS,
         VOFFS      => "00000" & VOFFS 
     );
      
    i_GameCore : entity work.segasystem1
    port map (
    
    clk48M     => clk_main_i,
    reset      => reset,
    
    INP0(7)    => keyboard_n(m65_left_crsr)  and joy_1_left_n_i, -- left
    INP0(6)    => keyboard_n(m65_horz_crsr)  and joy_1_right_n_i,-- right      
    INP0(5)    => keyboard_n(m65_up_crsr),                       -- up        
    INP0(4)    => keyboard_n(m65_vert_crsr),                     -- down    
    INP0(3)    => '1',
    INP0(2)    => keyboard_n(m65_left_shift) and joy_1_up_n_i,   -- trigger 2
    INP0(1)    => keyboard_n(m65_mega)       and joy_1_fire_n_i, -- trigger 1   
    INP0(0)    => '1',                                           -- trigger 3
    
    INP1(7)    => keyboard_n(m65_left_crsr)  and joy_2_left_n_i,  -- left
    INP1(6)    => keyboard_n(m65_horz_crsr)  and joy_2_right_n_i, -- right      
    INP1(5)    => keyboard_n(m65_up_crsr),                        -- up        
    INP1(4)    => keyboard_n(m65_vert_crsr),                      -- down    
    INP1(3)    => '1',
    INP1(2)    => keyboard_n(m65_left_shift) and joy_2_up_n_i,    -- trigger 2
    INP1(1)    => keyboard_n(m65_mega)       and joy_2_fire_n_i,  -- trigger 1   
    INP1(0)    => '1',                                            -- trigger 3
   
    INP2(7)    => '1',                       -- unknown
    INP2(6)    => '1',                       -- unknown
    INP2(5)    => keyboard_n(m65_2),         -- start 2
    INP2(4)    => keyboard_n(m65_1),         -- start 1                           
    INP2(3)    => keyboard_n(m65_s),         -- service button
    INP2(2)    => keyboard_n(m65_d),         -- service mode
    INP2(1)    => keyboard_n(m65_6),         -- coin 2
    INP2(0)    => keyboard_n(m65_5),         -- coin 1
    
    DSW0       => not dsw_a_i,
    DSW1       => not dsw_b_i,
    
    PH         => HPOS,
    PV         => VPOS,
    PCLK_EN    => PCLK_EN,
    POUT       => POUT,
    SOUT       => audio,

    ROMCL      => dn_clk_i,
    ROMAD      => dn_addr_i,
    ROMDT      => dn_data_i,
    ROMEN      => dn_wr_i,
    
    PAUSE_N    => not (pause_cpu or pause_i),
    HSAD       => hs_address,
    HSDO       => hs_data_out,
    HSDI       => hs_data_in,
    HSWE       => hs_write_enable
 
 );

      
   -- @TODO: Keyboard mapping and keyboard behavior
   -- Each core is treating the keyboard in a different way: Some need low-active "matrices", some
   -- might need small high-active keyboard memories, etc. This is why the MiSTer2MEGA65 framework
   -- lets you define literally everything and only provides a minimal abstraction layer to the keyboard.
   -- You need to adjust keyboard.vhd to your needs
   i_keyboard : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,

         -- Interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,

         keyboard_n_o          => keyboard_n
      ); -- i_keyboard

end architecture synthesis;

