SEGASYS1MEGA65 - ( Wonderboy ) for the MEGA65
=============================================

Wonder Boy is a classic arcade game released in 1986 by Sega. In the game, players control a character named Tom-Tom, who must navigate through various levels filled with enemies and obstacles to rescue his girlfriend Tanya from the clutches of the evil king. The game features side-scrolling platformer gameplay with vibrant and colorful graphics, along with catchy music and sound effects. Tom-Tom has the ability to jump and wield a variety of weapons to defeat enemies, including axes and boomerangs. Along the way, he can also collect fruit to replenish health and other power-ups to aid him on his quest. "Wonder Boy" is known for its challenging gameplay and has become a beloved classic among retro gaming enthusiasts.

This core is based on the
[MiSTer](https://github.com/MiSTer-devel/Arcade-SEGASYS1_MiSTer)
SEGASYS1 core which itself is based on the work of [many others](AUTHORS).

[Muse aka sho3string](https://github.com/sho3string)
ported the core to the MEGA65 in 2024.

The core uses the [MiSTer2MEGA65](https://github.com/sy2002/MiSTer2MEGA65)
framework and [QNICE-FPGA](https://github.com/sy2002/QNICE-FPGA) for
FAT32 support (loading ROMs, mounting disks) and for the
on-screen-menu.

How to install Wonderboy on your MEGA65
---------------------------------------

Download from here - [Download link #1](https://github.com/sho3string/SEGASYS1MEGA65/releases/download/v0.5.0/WonderboyMEGA65_r3_r6.zip) or [Download link #2](https://files.mega65.org?id=7365cb17-4375-45d3-a833-a89a38266c5e)

See [this site](https://sy2002.github.io/m65cores/) to understand how to install and run the core on your MEGA65.  

This core supports R3 and R6 revision boards, the zip file contains the approproiate .bit and .cor files for these revisions.  

Download ROM: Download the MAME ROM ZIP file ( wboy.zip [set 1] )  
Download the powershell or shell script depending on your preferred platform ( Windows, Linux/Unix and MacOS supported ).  

The install scripts are provided on the Github main page and in the WonderboyMEGA65_r3_r6.zip file.

Run the script:  
a) First extract all the files within the zip to any working folder.  
b) Copy the powershell or shell script to the same folder and execute it to create the following files.  

The following files are produced  

![image](https://github.com/sho3string/SEGASYS1MEGA65/assets/36328867/97e705d9-ad64-46ab-904c-0bc355623940)

Windows: run "wboy_rom_installer.ps1" via powershell  

Unix/Linux/MacOS: run "./wboy_rom_installer.sh" via bash  


The script will automatically create the /arcade/wboy folder where the generated ROMs will reside.

Copy or move the arcade/wboy folder to your MEGA65 SD card: You may either use the bottom SD card tray of the MEGA65 or the tray at the backside of the computer (the latter has precedence over the first).  

Default DIP switch positions:  

![image](https://github.com/sho3string/SEGASYS1MEGA65/assets/36328867/b007c91d-b4c5-43d2-8701-cc5908213c3f)
 
The above DIP configurations are the defaults used in the MEGA65 Core, so there is no need to configure these for the first time to start playing

For a description of DIPs see the following page.  

https://www.arcade-museum.com/dipswitch-settings/wonder-boy

This core has the potential to run other games on Sega System1 hardware, for now only Wonderboy is supported and tested.


