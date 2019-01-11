
# How to prepare an Antsle for BCM deployment

1. First, have Ubuntu Server 18.04 Server installed on a USB thumb drive. Ensure the drive is plugged into the Antsle before powering it on. Ensure the Antsle is plugged into the network. Plug your CAT6 cable into the LOWER_LEFT ethernet receptical.
2. Boot to the USB medium. You may have to press F11 at boot to ensure the device boots from the USB thumb drive.
3. Press enter to accept the defaults regarding keyboard layout (US English).
4. Press Enter to select the default option of "Install Ubuntu"
5. Ensure interface 'enp0s20f0' has an IP address from the network. Press Done to proceed.
6. Leave the proxy address field EMPTY and click Done to continue.
7. Leave the Mirror address at its default, then press Enter (Done) to continue.
8. Next, ensure the default "Use Entire Disk" is select and press ENTER.
9. Ensure the first drive is selected and press enter.
10. On the File System Summary page, press the DOWN arrow until [ partition 2 ] is highlighted. Press enter, DOWN to Edit, ENTER.
11. On the "Editing partition 2 of..." page, ensure 'Format' is 'btrfs', "mount at" says '/'.  
12. Press Enter to Save, which should leave you at the File System Summary page again.  Press DOWN until "Done" is highlighted.
13. Select 'Yes' to the 'Are you sure you want to continue page.


# Desktop 18.10

Install as regular. Create a swap partition on DISK0 that's TWICE the amount of RAM. Create a root partition of type BTRFS.
