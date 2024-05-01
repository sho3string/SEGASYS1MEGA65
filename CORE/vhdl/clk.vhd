-------------------------------------------------------------------------------------------------------------
-- Wonderboy Arcade Core for the MEGA65 
--
-- Clock Generator using the Xilinx specific MMCME2_ADV:
--
-- The MiSTer Wonderboy core needs these clocks:
--
--    48.4 MHz video clock
--
-- Wonderboy port done by Samuel P ( Muse ) in 2024
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
-------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity clk is
   port (
      sys_clk_i       : in  std_logic;   -- expects 100 MHz
      sys_rstn_i      : in  std_logic;   -- Asynchronous, asserted low

      main_clk_o      : out std_logic;   -- 48.4 MHz main clock
      main_rst_o      : out std_logic    -- reset, synchronized
     
   );
end entity clk;

architecture rtl of clk is

signal clkfb_main         : std_logic;
signal clkfb_main_mmcm    : std_logic;
signal main_clk_mmcm      : std_logic;
signal main_locked        : std_logic;

begin

   -------------------------------------------------------------------------------------
   -- Generate QNICE and HyperRAM clock
   -------------------------------------------------------------------------------------

   i_clk_main : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 5,
         CLKFBOUT_MULT_F      => 45.375,     -- (100 MHz x 45.375) / 5 = 907.5 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 18.750,     -- 907.5 MHz / 18.750 = 48.4 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb_main_mmcm,
         CLKOUT0             => main_clk_mmcm,
         -- Input clock control
         CLKFBIN             => clkfb_main,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => main_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_clk_main

   -------------------------------------------------------------------------------------
   -- Output buffering
   -------------------------------------------------------------------------------------

   mainfb_bufg : BUFG
      port map (
         I => clkfb_main_mmcm,
         O => clkfb_main
      );

   main_clk_bufg : BUFG
      port map (
         I => main_clk_mmcm,
         O => main_clk_o
      );
      
   -------------------------------------
   -- Reset generation
   -------------------------------------

   i_xpm_cdc_async_rst_main : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1,
         DEST_SYNC_FF    => 10
      )
      port map (
         src_arst  => not (main_locked and sys_rstn_i),   -- 1-bit input: Source reset signal.
         dest_clk  => main_clk_o,       -- 1-bit input: Destination clock.
         dest_arst => main_rst_o        -- 1-bit output: src_rst synchronized to the destination clock domain.
                                        -- This output is registered.
      );
        
end architecture rtl;

