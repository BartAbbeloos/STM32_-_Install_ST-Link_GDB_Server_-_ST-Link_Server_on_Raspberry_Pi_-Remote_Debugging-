# STM32 - Install ST-Link GDB Server / ST-LINK Server on Raspberry Pi (Remote Debugging)
<div style="text-align: right;">
  <span style="font-size: 10px;">#RemoteDebugging #STM32CubeIDE #STM32CubeCLT #RaspberryPi</span>
</div>

## Preface

This document is still “under construction”, but the basic functionality is already described.<br>
Over time, extra features, tests with different models, handy tricks, and so on will be added. But if I wait to release this document after all of that is finished, AI will probably have taken over the world by then, making this document obsolete.
So forgive me if not everything is 100% complete. The core functionality should be working though.


## Main Goal

My goal is to successfully upload and debug projects from STM32CubeIDE to a STM32 development board over the network.
I believe most people connect their development board directly to the USB of their PC with or without an extra separate powered USB hub for some electrical protection.
This is a somewhat bulky solution as you always need the USB port of your PC/laptop directly connected.
In case something goes electrically wrong, you are at risk of damaging the internal USB port of your PC/laptop.<br>
I think it would be nice/handy if you could connect the STM32 development board in some way to your local network and use STM32CubeIDE, that is installed on your development PC, to connect remotly over the LAN, to that STM32 development board to upload and debug your projects. That all without connecting any extra hardware directly to your PC over USB.

Sure, there are probably many easy ways to accomplish this, like installing STM32CubeCLT to a dedicated old x64 PC you might have laying around, gathering dust in the corner. But I recently bought a RaspBerry Pi 5 (RP5) 8GB and was wondering if I could use this instead. Not much memory is used during operation. Later on, I've even managed to get it also working on the RaspBerry Pi Zero 2W with only 512MB SDRAM. But some extra steps are required to get the installation process working (which is also described furhter on in this document).<br>
A RP is relative cheap (especially the RaspBerry Pi Zero 2W), small and consumes almost no power compared to a dedicated PC. It also has 5v and 3.3v output pins you can directly use to power your development board etc and it also has some extra onboard GPIO pins you can play around with if you ever feel the need for it (more like an optional bonus for free that comes along with it). If something goes wrong in your project, like a short circuit that releases the 'magic smoke', only your RP is at risk and this is relative cheap to replace compared to a PC.
So, let's give it a shot...

> [!WARNING]
> First of all, at the time of writing this document, I could not find much info (other than 'It is not supported') on the subject of installing STM32 developing software on a RP, so this is my own solution to get it workng. This is by no means an official work instruction nor (probably) the most recommended way to do it. Just sharing some info here that others might find useful, or give people idea's to find other, better ways to accomplish this conform to their own needs. So use it how you please and share your insights to inspire and help others.<br>
I'm also not professional Embedded Systems Engineer, just a humble wannabe who is playing around after hours out of interest in the matter. So take it with a grain of salt if not all terminology etc. is 100% correct.<br>
> Use it at your own risk. (If there would be any...)

## An overview of the final setup

The STM32 development board (eg the Blue Pill, Black Pill or whatever) is connected through an ST-Link V2 or ST-Link V3 MINIE to the USB port of the RP. Other debuggers or programmers might also work but I've not tested them yet.<br>
On the RP, the official Raspberry Pi OS Lite (64-bit) is installed. It will also work with the Raspberry Pi OS Full (64-bit) version (and probably with other Linux distro's too). But as a Linux newbee, I like the challenge to use the Lite version, that is without the desktop, just for the fun of it. (Or to keep the setup minimal and lean, if you do not see the 'fun' in this part.) By using the official Raspberry Pi OS (Debian based as far as I know), I'm sure that all the RP hardware is (or should be) fully supported.<br>
The RP is connected to the network over Wifi or by using an UTP Cable directly connected. I prefer a wired connection, so that is what I used.
We need to install some extra software from ST on this RP to be able to connect to this RP over the network from the STM32CubeIDE installed on our laptop. All the required software needed on the RP is bundled in one, free to download official package called STM32CubeCLT.<br>
Now, there is good news and some... not so good news about this.<br>
The good news is, there is a Linux (deb) version available.<br>
The 'not so good' news is that it is only available for x64 CPU architecture and my RP5 has a quad-core 64-bit Arm Cortex-A76 processor clocked at 2.4GHz (RP Zero 2W has a quad-core 64-bit ARM Cortex-A53 processor clocked at 1GHz) which uses the AArch64 / ARM64 CPU architecture. (It looks like all RP's till now uses this architecture too.)<br>
As I found in several forums, ST is not planning to publish ARM64 releases of their developing software any time soon. So this is an issue as ARM64 is not compatible with software compiled for x64 CPU's. But only at first sight... It seems that you can emulate a x64 environment to run x64 applications within an ARM64 CPU architecture with BOX64. So all hope is not lost.<br>
After all software is installed, you need to start the ST-Link GDB Server environment on the RP. This is, in short, the environment the STM32CubeIDE, installed on your computer, will connect to to upload and debug your project. I would prefer to connect all hardware to the RP, power it up and that's it. So after the installation I will configure Linux to automatically start the ST-Link GDB Server. This way, no manual intervention (except the power-on of the RP) is needed anymore.

## Difference between ST-LINK Server and ST-Link GDB Server
When I initially started with this setup I didn't realise there was a difference between ST-LINK Server and ST-Link GDB Server which was quite confusing.
Here's is the distinction between them as I understand it:

### ST-Link GDB Server
This is the software where your STM32CubeIDE connects to in order to upload the code through the programmer (in both the debug and release modes) to your development board and to debug your project if needed. The ST-Link GDB Server communicates with your debugger hardware (eg the ST-LINK v2) that is connected to the MCU. This way the programmer can be invoked from your RP to upload your code into the MCU and the ST-Link GDB Server can instruct the MCU to start or halt execution, pause on breakpoints and retrieve live data like variable values etc. from inside your MCU that can later be used in STM32CubeIDE to debug any issues with your code. 
It also supports SWO/SWV (Serial Wire Output/Viewer) if your debugger supports it. (The clone version of ST-LINK v2 does not support SWO/SWV out of the box, the official ST-LINK v3 does support it out of the box)
Without any additional software, the debugger can only maintain one active session at a time including the SWO/SWV functionality.

### ST-Link Server
The ST-Link Server is an application that allows you to share the debug interface of a single ST-LINK probe between multiple host applications, typically between a debugger and a monitoring tool.
Without this optional component, you can either debug your code with STM32CubeIDE or monitor real-time data using STM32CubeMonitor, but not simultaneously. With ST-Link Server, both tools can interact with the same ST-LINK probe concurrently.
This act as an extra layer between the ST-Link GDB server and the ST-LINK probe and needs to be enabled in both STM32CubeIDE (checkmark in GUI) as in the config file that is used on the RP to startup the ST-Link GDB Server. As this enables, next to extra functionality, also an extra layer, this might also cause a marginal extra delay. So I guess it's recommended to only enable this feature when necessary. 

Enabling or disabling this feature is done in the `config.txt` file by the use of the -t parameter als later explained.
```
###############################################################
#  -t                 : Shared mode using ST-LINK server
###############################################################
#-t
```

## Overview of Basic Installation Steps

1. Install STM32CubeIDE on your Desktop/Laptop
2. Install Raspberry Pi OS Lite (64-bit) on RP
3. Install BOX64
4. Install STM32CubeCLT, Configure ST-Link GDB server / ST-LINK Server
5. Configure Linux to autostart ST-Link GDB Server
6. Cleanup

## Installation steps

### 1. Install STM32CubeIDE on your Desktop/Laptop

On your laptop, you need the STM32CubeIDE software.<br>
You can download it on:
(https://www.st.com/en/development-tools/stm32cubeide.html)<br>
You need an account to be able to download it, but the registration is all at no cost.
STM32CubeIDE has the ability to remotely upload and debug your project already built-in. There is a lot of info available on how to install and use STM32CubeIDE so I'm not going to focus on that part in here.
That is all you need on your PC.

### 2. Install Raspberry Pi OS Lite (64-bit) on RP
I'm using an RP5 8GB with the official Raspberry Pi OS Lite (64-bit) (Released : 2025-05-13 at time of writing).
You can find instructions on how to install the OS on the RP5 on their official site:<br>
(https://www.raspberrypi.com/documentation/computers/getting-started.html)<br>
I've used the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to install the OS.<br>
I've enabled SSH in the RP Imager software and selected "Use password authentication". This way, when we later enable logging on using public-key authentication, we can, by default, still use a username and password to logon if we choose to.

#### 2.1 Configure SSH to authenticate by using the key-pair (Optional)

##### 2.1.1 Generate a key-pair on your PC
I've generated a ECDSA key-pair on my Windows PC. You only need one such key-pair per PC.<br>
In PowerShell (PC):
```powershell
ssh-keygen -b 521 -t ecdsa
```
This will store a new key-pair in your profile on `$env:USERPROFILE\.ssh`.

##### 2.1.2 Copy the public key to the RP
Next you need to copy the public part of this key-pair to your RP so you can use this key to configure your RP to trust this key-pair.<br>
In PowerShell (PC):
```powershell
scp $env:USERPROFILE\.ssh\id_ecdsa.pub pi@raspberrypi01:~/
```
pi is here the username, raspberrypi01 is the name of your RP. Replace this with your own values. You can also use the IP instead of the name of the RP.
You will be asked to enter the password of the RP pi user.

##### 2.1.3 Trust the public key on the RP
Connect to the RP using the password.<br>
In PowerShell (PC):
```powershell
ssh pi@raspberrypi01
```
You will be asked to enter the password of the RP pi user.<br>

Configure the RP to trust the public key.<br>
On RP:
```bash
sudo ssh-copy-id -f -i ~/id_ecdsa.pub pi@localhost
```
You will be asked to enter the password of the RP pi user.
I'm using the -f parameter here (forced mode) so that the private key part is not checked. I am the owner of this key pair and I know this is the correct public key of it that is not yet trusted on this newly installed RP OS. So I see no big issue in this. I prefer to keep the private key part on my pc so I know that I do not have any copies of it wandering around on other systems.

##### 2.1.4 Cleanup unneeded files
The public key file we copied over to the RP is now not needed anymore We can remove it and then exit the SSH session so we can test the SSH connection.<br>
On RP:
```bash
rm id_ecdsa.pub
exit
```

##### 2.1.5 Test the SSH connection
From now on you should be able to logon to the RP over SSH without the need to enter a password.<br>
In PowerShell (PC):
```powershell
ssh pi@raspberrypi01
```
You will not be asked anymore to enter a password.

#### 2.2 Raspberry Pi Connect (Optional)
This is a nice feature to access your RP from everywhere by logging on to:
[RaspBerry Pi Connect](https://connect.raspberrypi.com/sign-in)
For the Lite OS, we need to install rpi-connect-lite.<br>
On RP:
```bash
sudo apt install rpi-connect-lite
```
To allow the Raspberry Pi Connect service to connect to the RP even when there is no user logged in we have to enable 'linger' mode for the pi user (the user we are currently logged on with.)<br>
On RP:
```bash
loginctl enable-linger
```

Then we have to enable the service.<br>
On RP:
```bash
rpi-connect on
```

As a final step we have to register the RP to the Raspberry Pi Connect portal
On RP:
```bash
rpi-connect signin
```
Follow the provided instructions after entering the command.

#### 2.3 Update Raspberry Pi OS
To be sure your OS is fully up-to-date run:<br>
On RP:
```bash
sudo apt update && sudo apt full-upgrade
```
or if you want to automatically confirm the process
```bash
sudo apt update && sudo apt full-upgrade -y
```
Reboot the RP after the RP update/full-upgrade completes
```bash
sudo reboot
```

### 3. Install BOX64
I followed the instructions on [Run x64 Software on a Raspberry Pi using Box64](https://pimylifeup.com/raspberry-pi-x64/) using the latest version (v0.3.4) at the time of writing.<br>
These instructions are tested on a RP5 / 8GB.
> [!NOTE]
>The RP Zero 2W only has 512MB SDRAM which seems to be too less to get BOX64 compiled and/or installed without some extra tweaks.<br>
>I will add extra instructions on how I got it working, on the end of this chapter.

#### 3.1 Installing requirements
You need the git, build-essental and cmake package.
While executing:
```bash
sudo apt install git build-essential cmake
```
you get the info that the build-essential package is already installed by default on the Raspberry Pi OS Lite (64-bit). So only git and cmake are installed.
After the installation of BOX64 is completed, they are not needed anymore and you can remove git and cmake if you do not want to have any unneeded extra packages installed. This will be handled in chapter; 'Remove git and cmake (Optional)' later on.

#### 3.2 Download the source files of BOX64
Download the latest version of BOX64 from GitHub.
```bash
git clone https://github.com/ptitSeb/box64.git
```
#### 3.3 Prepare the directory structure for the compilation
```bash
cd ~/box64
mkdir build
cd build
```
#### 3.4 Generate configuration files for the compilation of BOX64
For RP5 (Using 16k Page Size = preferred)<br> 
```bash
cmake .. -DRPI5ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
```
(For RP4/RP5 (Using 4k Page Size))
```bash
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
```
(For RP3 / RP Zero 2W)
```bash
cmake .. -DRPI3ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
```

#### 3.5 Start the compilation of BOX64
```bash
make -j$(nproc)
```

#### 3.6 Install BOX64
Start the actual installation of BOX64
```bash
sudo make install
```
You need to make your RP aware of the presence of the installation of BOX64 by restarting the 'systemd-binfmt' service
```bash
sudo systemctl restart systemd-binfmt
```
or just reboot your RP
```bash
sudo reboot
```
> [!CAUTION]
If you receive the following error message when you reinstalled the OS using the previous compiled files of BOX64 and you want to continue the installation with `sudo make install`:
>```
>make: /usr/bin/cmake: No such file or directory
>make: *** [Makefile:11108: cmake_check_build_system] Error 127
>```
>then cmake is not installed.
>Install it again by running:
>```bash
>sudo apt install cmake
>```

#### 3.7 Copy the compiled files to PC for later usage (Optional)
If you want to, you can copy the compiled files to your pc for later usage so that if you want to install BOX64 again on the same type of RP, you do not need to install git and do the whole download and compilation process all over.
This can be done in several ways eg:

##### 3.7.1 Copy the BOX64 dir over to your PC (Optional)
Copy the BOX64 directory on the RP home dir to your PC:<br>
In PowerShell (PC):
```powershell
scp -r pi@raspberrypi01:~/box64 c:\temp
```
Use quotes if you have a space in your path. Eg:<br>
In PowerShell (PC):
```powershell
scp -r pi@raspberrypi01:~/box64 "C:\temp\Raspberry Pi\RP5"
```

To copy it back to the RP.<br>
In PowerShell (PC):
```powershell
scp -r "C:\temp\Raspberry Pi\RP5\box64" pi@raspberrypi01:~/
```
##### 3.7.2 Compress the BOX64 dir and copy it over to your PC (Optional)
You can also compress the BOX64 directory and all its contents first and then copy that compressed file over to your PC
```bash
cd ~
7z a -r -mmt=on box64.7z ~/box64/*
```
Then copy that file over to your PC
In PowerShell (PC):
```powershell
scp pi@raspberrypi01:/home/pi/box64.7z "C:\temp\Raspberry Pi\box64\RP5"
```

To copy it back to the RP.
In PowerShell (PC):
```powershell
scp "C:\temp\Raspberry Pi\box64\RP5\box64.7z" pi@raspberrypi01:~/ 
```
Then uncompress the file
```bash
7z x ./box64.7z -o/home/pi/box64
rm box64.7z
```
#### 3.8 Remove git and cmake (Optional) 
After the installation of BOX64, git and cmake are not needed anymore and you can remove them if you do not want to have any unneeded extra packages installed.
```bash
sudo apt purge git cmake
sudo apt autoremove
sudo apt clean
```
#### 3.9 Remove the source and compiled BOX64 files (Optional) 
After the installation of BOX64 is completed, you can remove the directory /home/pi/box64 and its contents
```bash
cd ~
sudo rm -r box64
```
#### 3.10 Extra steps for RaspBerry Pi Zero 2W
I was not able to compile and install BOX64 out of the box on a RP Zero 2W. It seems to have way to less SDRAM (512MB) to get this done.<br>

##### On a RP5
To get the compilation step done, I've used an RP5 with 8GB of SDRAM. On this RP5 I followed the above procedure to get BOX64 installed with some exceptions.<br>
In short, I've:
- Cloned a fresh copy of BOX64 from GitHub.
- Created the directory structure as described.
- Generated the configuraton files and used the RP Zero 2W setting
```bash
cmake .. -DRPI3ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
```
- Started the compilation process for the Raspbery Pi Zero 2W CPU on the RP5.
- Copied the ~/box64 (containting the compiled files) over the the Raspberry Pi Zero 2W

##### Install ZRAM on Raspberry Pi Zero 2W
Then on the Raspberry Pi Zero 2W, I've installed ZRAM on the RaspBerry Pi Zero 2W to squeeze some more memory usage out of those 512MB SDRAM.
```bash
sudo apt install zram-tools
```
you can change the compression algorithm in the `zramswap` file, but in the end I left everything default.
```bash
sudo nano /etc/default/zramswap
```
If you made any changes on the compression algorith, you have to make those active by restarting `zramswap`
```bash
sudo zramswap restart
```
You can check which algorithm is active while the ZRAM module is loaded, in the comp_algorithm file. The active algorithm is within []. 
```bash
nano /sys/block/zram0/comp_algorithm
```
ZRAM is used next to the default swap files.
to check if ZRAM has an higher priority thant the swap file, use:
```bash
swapon --show
```
The default settings should be fine. That is ZRAM should have a higher priority (default 100) then the swap file (default -2).

##### Temp increase the swapfile size on the Raspberry Pi Zero 2W
By default, the swap file is set to 512MB. I've increased the size to 2048MB by

###### Turn off the current swap file
```bash
sudo dphys-swapfile swapoff
```
###### Edit the swap configuration file
```bash
sudo nano /etc/dphys-swapfile
```
- Look for the line:
  ```bash
  CONF_SWAPSIZE=512
  ```
- Change `512` to `2048` (e.g., `CONF_SWAPSIZE=2048` for 2GB)

###### Save and exit
- Press `CTRL + X`, then `Y`, then `Enter`

###### Reinitialize the swap file
```bash
sudo dphys-swapfile setup
```

###### Turn swap back on
```bash
sudo dphys-swapfile swapon
```

###### Reboot (Optional)
```bash
sudo reboot
```
##### Install BOX64
Use the same isntructions as described above.
The installation process may take a few hours. If you do this over SSH and your connection might be interrupted, then all processes started from that ssh sesson are also terminated. So be sure you check the power settings of your computer on which you initiated the SSH session that it will not shut down after X hours.
You can also try to run it on your RP Zero 2W with a keyboard and HDMI screen directly connected so you might not have the SSH session disconnect issue as everything is done directly in tty in this way.
> [!TIP]
> If this process might fail, you can restart it and it will continue at the latest reached 'checkpoint' it previously made.

> [!TIP]
> If it fails due to an 'out of memory' issue you can check it after the failure (without rebooting the RP) by typing:<br>
>```bash
>dmesg | tail
>```
>This then gives the 'out of memory' message if it was the cause of the failure.

##### Set swap file size back to default.
The same way as you increased the swap file, but now set it from 2048 back to 512



### 4. Install STM32CubeCLT, Configure ST-Link GDB server / ST-LINK Server

#### 4.1 Download STMCubeCLT
You can download the latest version of STMCubeCLT on:<br>
https://www.st.com/en/development-tools/stm32cubeclt.html<br>
Be sure you download the Debian version (STM32CubeCLT-DEB).<br>
STM32CubeCLT contains:<br>
-STM32CubeProgrammer (STM32CubeProg) utility<br>
-ST-Link GDB Server<br>
-ST-Link Server (required for multiple simultaneous connections to the ST-link debugger hardware)

#### 4.2 Extract the program files

This download is not meant for the ARM64 CPU architecture. So we cannot just run the installation process and hope that it gets installed without any issue. To get it installed you need to retrieve the program files from the installation package in some way.<br>
The following steps describe how to accomplish this.

##### 4.2.1 Extract the downloaded file
Extract the downloaded file (eg `en.st-stm32cubeclt_1.18.0_24403_20250225_1636_amd64.deb_bundle.sh.zip`) in Windows. (Just easier to do in Windows.)<br>
You now have an `st-stm32cubeclt_1.18.0_24403_20250225_1636_amd64.deb_bundle.sh` file.<br>
I opened this file with Visual Studio Code (ignoring any messages on opening) and I got something that looked like the installation script. In there I found some parameters you can use like `--target` and `--noexec`. Those will become handy for extracting the contents out of this .sh file
>MS_Help()
{  
    cat << EOH >&2  
${helpheader}Makeself version 2.3.0  
> 1) Getting help or info about $0 :  
  $0 --help   Print this message  
  $0 --info   Print embedded info : title, default target directory, embedded script ...  
  $0 --lsm    Print embedded lsm entry (or no LSM)  
  $0 --list   Print the list of files in the archive  
  $0 --check  Checks integrity of the archive  
>  
 >2) Running $0 :  
  $0 [options] [--] [additional arguments to embedded script]  
  with following options (in that order)  
  --confirm             Ask before running embedded script  
  --quiet		Do not print anything except error messages  
  ***--noexec***        Do not run embedded script  
  --keep                Do not erase target directory after running  
			the embedded script  
  --noprogress          Do not show the progress during the decompression  
  --nox11               Do not spawn an xterm  
  --nochown             Do not give the extracted files to the current user  
  ***--target dir***    Extract directly to a target directory  
                        directory path can be either absolute or relative  
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command  
  --                    Following arguments will be passed to the embedded script  
EOH  
}  

##### 4.2.2 Copy the extracted .sh file to RP
Copy this .sh file over to the home directory of the RP.<br>
In PowerShell (PC):
```powershell
scp "$env:USERPROFILE\Downloads\st-stm32cubeclt_1.18.0_24403_20250225_1636_amd64.deb_bundle.sh" pi@raspberrypi01:~/
```

##### 4.2.3 Extract the contents from the .sh file
Extract the contents from the .sh file into a directory named extracted and do not run the embedded script. I use the previous discovered options to do this.
```bash
sh st-stm32cubeclt_1.18.0_24403_20250225_1636_amd64.deb_bundle.sh --target extracted --noexec
cd extracted
```
Now we have the program files we need (captured in .deb files) in `~/extracted`.<br>
This directory contains 3 .deb files that we now have to unzip

##### 4.2.4 Unzip the extracted .deb files
Starting from within `~/extracted` extract the .deb files by running:

```bash
7z x st-stlink-server-2.1.1-1-linux-amd64.deb -ost-stlink-server-2.1.1-1-linux-amd64
7z x st-stm32cubeclt-1.18.0-24403-20250225-1636_amd64.deb -ost-stm32cubeclt-1.18.0-24403-20250225-1636_amd64
7z x st-stlink-udev-rules-1.0.3-2-linux-all.deb -ost-stlink-udev-rules-1.0.3-2-linux-all
```
This will result in 3 .tar files.

##### 4.2.5 Untar the extracted files from the .deb files
Untar those files, each in its own directory underneath a newly created directory `~/stsources`.
```bash
mkdir ~/stsources
mkdir ~/stsources/st-stlink-server-2.1.1-1
tar -xvf st-stlink-server-2.1.1-1-linux-amd64/data.tar -C /home/pi/stsources/st-stlink-server-2.1.1-1

mkdir ~/stsources/st-stm32cubeclt-1.18.0
tar -xvf st-stm32cubeclt-1.18.0-24403-20250225-1636_amd64/data.tar -C /home/pi/stsources/st-stm32cubeclt-1.18.0

mkdir ~/stsources/st-stlink-udev-rules-1.0.3-2
tar -xvf st-stlink-udev-rules-1.0.3-2-linux-all/data.tar -C /home/pi/stsources/st-stlink-udev-rules-1.0.3-2
```

##### 4.2.6 Cleanup unneeded files
Remove unneeded files to keep an overview.
```bash
cd ..
rm st-stm32cubeclt_1.18.0_24403_20250225_1636_amd64.deb_bundle.sh
rm -r extracted
```
You now have the required program files extracted in `~/stsources`.
Those files will be later used to get the program installed. (The installation is done as part of a copy of specific directories to a more suited location.)

##### 4.2.7 Copy the extracted program files to PC (Optional)
You can create a copy of those extracted files to your PC for later usage if you want to do the installation on other RP's without the need of going through this whole extraction process again.<br>
In PowerShell (PC):
```powershell
scp -r pi@raspberry01:~/stsources "C:\temp\Raspberry Pi\RP5"
```
You can copy the files from your PC back to your RP
In PowerShell (PC):
```powershell
scp -r "C:\temp\Raspberry Pi\RP5\stsources" pi@raspberrypi01:~/
```

##### 4.2.8 Copy extra supporting files from my GitHub repository

You can find some extra files in this GitHub repository:<br>
- `ST-LINK_gdbserver.sh` (optional): A script to manually start the ST-Link GDB server.<br>
- `config.txt`: A configuration file where we configure several options on how the ST-Link GDB Server behaves. You may need to make some changes in here depending on your specific project.<br>
- `stlink-gdb-server.service`: This is used by systemd to automatically start the ST-Link_gdbserver when the RP starts up and restarts the ST-Link_gdbserver when a debug session ends.<br>
- `adjust-config.txt.sh` (optional): a script that makes it more easy to make the manual changes to the config.txt file, especially when the Overlay File System is active, and makes the changes active afterwards.

Download those files to your PC in eg `C:\temp\RaspBerry Pi\RP5\stsources\config_ST-Link_gdbserver`.<br>
Copy them over to your RP using:<br>
In PowerShell (PC):
```powershell
scp -r "C:\temp\RaspBerry Pi\RP5\stsources\config_ST-Link_gdbserver" pi@raspberrypi01:~/stsources/
```

#### 4.3 Copy the program files to final destination
Copy the program files of STM32CubeCLT to a more suited location

```bash
sudo cp -r ~/stsources/st-stm32cubeclt-1.18.0/opt/st /opt
```

Check if all settings in the following files are correct: 
```bash
nano ~/stsources/config_ST-Link_gdbserver/config.txt
nano ~/stsources/config_ST-Link_gdbserver/ST-LINK_gdbserver.sh
nano ~/stsources/config_ST-Link_gdbserver/stlink-gdb-server.service
nano ~/stsources/config_ST-Link_gdbserver/adjust-config.txt.sh
```
Maybe you need to adjust the software version number in the directory structure.

**Config.txt**:
```
###############################################################
#  -cp <path>         : Path to STM32CubeProgrammer
#                       Modify to correct path
#                       for STM32_Programmer_CLI executable
###############################################################
-cp /opt/st/stm32cubeclt_1.18.0/STM32CubeProgrammer/bin
```
**ST-LINK_gdbserver.sh**:
```bash
#!/bin/bash
ST_LINK_GDBserverPath="/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin"
ST_LINK_GDBserverConfigPath="/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin"
```

**stlink-gdb-server.service**:
```
[Service]
WorkingDirectory=/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin
ExecStart=/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver -c config.txt
```

**adjust-config.txt.sh**:
```
# Make the required adjustments in the config.txt file
sudo nano /media/root-ro/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt
```

For now, disable 'Shared mode' by replacing `-t` into `#-t` in the `config.txt` file so we can do a test during the installation process without ST-Link Server installed.
```
###############################################################
#  -t                 : Shared mode using ST-LINK server
###############################################################
#-t
```

>[!NOTE]
If you prefer to edit those files in Windows using Notepad, you might introduce some issues because Notepad can insert some hidden characters that are not supported by Linux Shell scripting.
Eg: When you get an error message when executing a .sh script that is edited in Windows Notepad that contains `syntax error: unexpected end of file`, then Notepad might have inserted some unsupported line endings.
You can use the dos2unix command to correct this.
>```bash
>dos2unix ST-LINK_gdbserver.sh
>```
>You do not have this issue when adjusting it directly in Linux using nano.

Then copy those files to the correct location:
```bash
sudo cp ~/stsources/config_ST-Link_gdbserver/config.txt /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin
sudo cp ~/stsources/config_ST-Link_gdbserver/ST-LINK_gdbserver.sh /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin
sudo cp ~/stsources/config_ST-Link_gdbserver/adjust-config.txt.sh ~/
```
We will copy the `~/stsources/config_ST-Link_gdbserver/stlink-gdb-server.service` file to the correct location later on when we configure systemd.

It looks like the USB connected debugger hardware (eg the ST-LINK v2, ST-Link V3 MINIE, ...) also need some drivers. You can copy them from the extracted files to the correct location.
```
sudo cp ~/stsources/st-stm32cubeclt-1.18.0/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/*.rules /etc/udev/rules.d/
```
You need to reboot the RP to get the drivers active but this will be done in a moment.

>[!NOTE] 
After you copied those files to the correct location and you want to make some adjustments using `nano`, you need to use `sudo` in front of the command to be able to save those changes.<br>
Eg:<br>
>```bash
>sudo nano /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt
>```

Check if the `ST-LINK_gdbserver.sh` script has execution rights so you can execute it using `./ST-LINK_gdbserver.sh`.
You can check the execution permissions of the file using:
```bash
ls -l /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver.sh
```
When it returns someting without an `x` like `-rw-r--r--` the file has no execution permissions and you need to adjust it by using `chmod`.
```bash
sudo chmod +x /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver.sh
```
When it returns `-rwxr-xr-x`, the file has execution permissions.

Turn off the RP:
```bash
sudo shutdown now
```
Connect the ST-Link debugger to USB and start the RP again
>[!NOTE] 
During testing, I had all the time the ST-Link v2 (clone) connected to the USB and had no issues. But maybe it is better to connect the usb only after you copied the .rule files and turned off the RP.

You should now be able to manually start the ST-LINK_gdbserver by running `./ST-LINK_gdbserver.sh` executed from the directory `/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/` where this file is located. (Without the sharing mode option enabled (`#-t`) in the config.txt file as previously mentioned.)
It is important to start the .sh file beginning with `./` (while the script is located in the working directory) as this tells Linux to execute the .sh script.

Or you can just run the script including the full path like shown underneath:
```bash
/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver.sh
```

You should receive an output like below if everything is OK:
```
ST-LINK_gdbserver.sh
[BOX64] Box64 arm64 v0.3.5 1e2bae92 with Dynarec built on May 24 2025 17:51:23
[BOX64] Dynarec for ARM64, with extension: ASIMD AES CRC32 PMULL ATOMICS SHA1 SHA2
[BOX64] Running on Cortex-A76 with 4 cores, pagesize: 16384
[BOX64] Will use hardware counter measured at 54.0 MHz emulating 3.4 GHz
[BOX64] Detected 48bits at least of address space
[BOX64] Counted 25 Env var
[BOX64] Library search path:
[BOX64] Binary search path: ./:bin/:/usr/local/sbin/:/usr/local/bin/:/usr/sbin/:/usr/bin/:/sbin/:/bin/:/usr/local/games/:/usr/games/
[BOX64] Looking for /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver
[BOX64] argv[1]="-c"
[BOX64] argv[2]="/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt"
[BOX64] Rename process to "ST-LINK_gdbserver"
[BOX64] Using native(wrapped) libpthread.so.0
[BOX64] Using emulated /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/native/linux_x64/libSTLinkUSBDriver.so
[BOX64] Using emulated /usr/lib/box64-x86_64-linux-gnu/libstdc++.so.6
[BOX64] Using emulated /usr/lib/box64-x86_64-linux-gnu/libgcc_s.so.1
[BOX64] Using native(wrapped) libc.so.6
[BOX64] Using native(wrapped) ld-linux-x86-64.so.2
[BOX64] Using native(wrapped) libdl.so.2
[BOX64] Using native(wrapped) libutil.so.1
[BOX64] Using native(wrapped) librt.so.1
[BOX64] Using native(wrapped) libbsd.so.0
[BOX64] Using native(wrapped) libm.so.6
[BOX64] Using native(wrapped) libusb-1.0.so.0


STMicroelectronics ST-LINK GDB server. Version 7.10.0
Copyright (c) 2025, STMicroelectronics. All rights reserved.

Starting server with the following options:
        Persistent Mode            : Disabled
        Logging Level              : 31
        Listen Port Number         : 61234
        Status Refresh Delay       : 15s
        Verbose Mode               : Enabled
        SWD Debug                  : Enabled

COM frequency = 4000 kHz
Target connection mode: Attach
Reading ROM table for AP 0 @0xe00fffd0
Hardware watchpoint supported by the target
ST-LINK Firmware version : V2J45S7
Device ID: 0x410
PC: 0x1
ST-LINK device status: RUN_MODE
ST-LINK detects target voltage = 3.10 V
ST-LINK device status: RUN_MODE
ST-LINK device initialization OK
Stm32Device, pollAndNotify running...
SwvSrv state change: 0 -> 1
Waiting for connection on port 61235...
Waiting for debugger connection...
Waiting for connection on port 61234...
```
To exit and go back to the Linux terminal, press (fast) 2 times `Ctrl+c`.

#### 4.4 Enable Sharing mode
If you need to accept multiple simultaneous connections, you also need 
the ST-Link server part. 
You need to adjust the config.txt file to enable it.

When we enable Shared mode at this point by removing the `#` (comment marking) before `-t` in the `config.txt` using:
```bash
sudo nano /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt
```
```
###############################################################
#  -t                 : Shared mode using ST-LINK server
###############################################################
-t
```
and start the `/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver.sh` script again, you will receive the following error message (after pressing `Ctrl+c`):
```
Failed launching stlink-server (errno 2)
Failed launching /usr/local/bin/stlink-server (errno 2)
Not able to connect to server
ST-Link enumeration failed

Error in initializing ST-LINK device.
Reason: ST-LINK DLL error.
```

To make the Sharing mode available, the program seems to expect the `stlink-server` file in the `/usr/local/bin/` as we can see in the error message: 
```
Failed launching /usr/local/bin/stlink-server (errno 2)
```

This `stlink-server` file can also be found in one of the previously extracted files.
To fix this issue, just copy the `stlink-server` file from the extracted files into the `/usr/local/bin/` dir.
```bash
sudo cp ~/stsources/st-stlink-server-2.1.1-1/usr/bin/stlink-server /usr/local/bin
```

When you now run the `/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver.sh` script again you get:

```
[BOX64] Box64 arm64 v0.3.5 1e2bae92 with Dynarec built on May 24 2025 17:51:23
[BOX64] Dynarec for ARM64, with extension: ASIMD AES CRC32 PMULL ATOMICS SHA1 SHA2
[BOX64] Running on Cortex-A76 with 4 cores, pagesize: 16384
[BOX64] Will use hardware counter measured at 54.0 MHz emulating 3.4 GHz
[BOX64] Detected 48bits at least of address space
[BOX64] Counted 25 Env var
[BOX64] Library search path:
[BOX64] Binary search path: ./:bin/:/usr/local/sbin/:/usr/local/bin/:/usr/sbin/:/usr/bin/:/sbin/:/bin/:/usr/local/games/:/usr/games/
[BOX64] Looking for /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/ST-LINK_gdbserver
[BOX64] argv[1]="-c"
[BOX64] argv[2]="/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt"
[BOX64] Rename process to "ST-LINK_gdbserver"
[BOX64] Using native(wrapped) libpthread.so.0
[BOX64] Using emulated /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/native/linux_x64/libSTLinkUSBDriver.so
[BOX64] Using emulated /usr/lib/box64-x86_64-linux-gnu/libstdc++.so.6
[BOX64] Using emulated /usr/lib/box64-x86_64-linux-gnu/libgcc_s.so.1
[BOX64] Using native(wrapped) libc.so.6
[BOX64] Using native(wrapped) ld-linux-x86-64.so.2
[BOX64] Using native(wrapped) libdl.so.2
[BOX64] Using native(wrapped) libutil.so.1
[BOX64] Using native(wrapped) librt.so.1
[BOX64] Using native(wrapped) libbsd.so.0
[BOX64] Using native(wrapped) libm.so.6
[BOX64] Using native(wrapped) libusb-1.0.so.0


STMicroelectronics ST-LINK GDB server. Version 7.10.0
Copyright (c) 2025, STMicroelectronics. All rights reserved.

Starting server with the following options:
        Persistent Mode            : Disabled
        Logging Level              : 31
        Listen Port Number         : 61234
        Status Refresh Delay       : 15s
        Verbose Mode               : Enabled
        SWD Debug                  : Enabled

[BOX64] Box64 arm64 v0.3.5 1e2bae92 with Dynarec built on May 24 2025 17:51:23
[BOX64] Dynarec for ARM64, with extension: ASIMD AES CRC32 PMULL ATOMICS SHA1 SHA2
[BOX64] Running on Cortex-A76 with 4 cores, pagesize: 16384
[BOX64] Will use hardware counter measured at 54.0 MHz emulating 3.4 GHz
[BOX64] Detected 48bits at least of address space
[BOX64] Counted 26 Env var
[BOX64] Library search path:
[BOX64] Binary search path: ./:bin/:/usr/local/sbin/:/usr/local/bin/:/usr/sbin/:/usr/bin/:/sbin/:/bin/:/usr/local/games/:/usr/games/
[BOX64] Looking for /usr/local/bin/stlink-server
[BOX64] argv[1]="-p7184"
[BOX64] argv[2]="-a"
[BOX64] Rename process to "stlink-server"
[BOX64] Using native(wrapped) libusb-1.0.so.0
[BOX64] Using native(wrapped) libpthread.so.0
[BOX64] Using native(wrapped) libc.so.6
[BOX64] Using native(wrapped) ld-linux-x86-64.so.2
[BOX64] Using native(wrapped) libdl.so.2
[BOX64] Using native(wrapped) libutil.so.1
[BOX64] Using native(wrapped) librt.so.1
[BOX64] Using native(wrapped) libbsd.so.0
Info : default port : 7184
Info : Remote address: 127.0.0.1
Info : Remote address: 127.0.0.1
Info : STLINKV2 v2J45S7, PID 0x3748
COM frequency = 4000 kHz
Target connection mode: Attach
Reading ROM table for AP 0 @0xe00fffd0
Hardware watchpoint supported by the target
ST-LINK Firmware version : V2J45S7
Device ID: 0x410
PC: 0x0
ST-LINK device status: RUN_MODE
ST-LINK detects target voltage = 3.10 V
ST-LINK device status: RUN_MODE
ST-LINK device initialization OK
Stm32Device, pollAndNotify running...
SwvSrv state change: 0 -> 1
Waiting for connection on port 61235...
Waiting for debugger connection...
Waiting for connection on port 61234...
```

Now, after starting ST-LINK GDB server, BOX64 is invoked again while starting ST-Link server as you can see in the section underneath:
```
[BOX64] Box64 arm64 v0.3.5 1e2bae92 with Dynarec built on May 24 2025 17:51:23
[BOX64] Dynarec for ARM64, with extension: ASIMD AES CRC32 PMULL ATOMICS SHA1 SHA2
[BOX64] Running on Cortex-A76 with 4 cores, pagesize: 16384
[BOX64] Will use hardware counter measured at 54.0 MHz emulating 3.4 GHz
[BOX64] Detected 48bits at least of address space
[BOX64] Counted 26 Env var
[BOX64] Library search path:
[BOX64] Binary search path: ./:bin/:/usr/local/sbin/:/usr/local/bin/:/usr/sbin/:/usr/bin/:/sbin/:/bin/:/usr/local/games/:/usr/games/
[BOX64] Looking for /usr/local/bin/stlink-server
[BOX64] argv[1]="-p7184"
[BOX64] argv[2]="-a"
[BOX64] Rename process to "stlink-server"
[BOX64] Using native(wrapped) libusb-1.0.so.0
[BOX64] Using native(wrapped) libpthread.so.0
[BOX64] Using native(wrapped) libc.so.6
[BOX64] Using native(wrapped) ld-linux-x86-64.so.2
[BOX64] Using native(wrapped) libdl.so.2
[BOX64] Using native(wrapped) libutil.so.1
[BOX64] Using native(wrapped) librt.so.1
[BOX64] Using native(wrapped) libbsd.so.0
Info : default port : 7184
Info : Remote address: 127.0.0.1
Info : Remote address: 127.0.0.1
Info : STLINKV2 v2J45S7, PID 0x3748
```

### 5. Configure Linux to autostart ST-Link GDB Server

I use systemd to automatically start `ST-LINK_gdbserver`, with the correct parameters, when the RP starts up. You need to copy a configuration/.service file for this and reload, enable and start systemd afterwards to get those changes active.

```bash
sudo cp ~/stsources/config_ST-Link_gdbserver/stlink-gdb-server.service /etc/systemd/system
```

```bash
sudo systemctl daemon-reload 
sudo systemctl enable stlink-gdb-server.service
sudo systemctl start stlink-gdb-server.service
```

When you now restart your RP, the ST-Link GDB server is automatically started using the settings defined in the config.txt file.

```bash
sudo reboot
```
>[!NOTE]
When starting the ST-Link GDB Server through systemd, the loggings will be sent to the console and the journal as configured in the `stlink-gdb-server.service` file.
>```bash
>StandardOutput=journal+console
>StandardError=journal+console
>```
>You need to connect a HDMI screen to see the console output (Not visible in a SSH session) or you can manually check the loggings of the service using:
>```bash
>journalctl -xeu stlink-gdb-server.service
>```


### 6. Cleanup (Optional)
At this point you have a working setup and all files used in the home 
directory (`~/`) except the optional `adjust-config.txt.sh` file, are not needed anymore and can be deleted if you want
```bash
rm -r box64
rm -r stsources
```

## Connect with STM32CubeIDE (Informational)
Be sure you have the IP of your RP5 and the port where the ST-LINK GDB 
Server is listening on (by default port 61234).

The IP of your RP5 can in Linux be received by running: 
```bash
ip addr show
```
or by using the deprecated command:
```bash
ifconfig
```

The port the ST-Link GDB Server is listening on can be found in the 
`config.txt` file. This is by default port 61234<br>
From config.txt:
```
###############################################################
#  -p <Port-Number>   : TCP-Listen Port-Number.
###############################################################
-p 61234
```
More info on how to connect to the remote ST-LINK GDB Server from 
within STM32CubeIDE can be found on:
[STM32CubeIDE - Remote Debug](https://www.youtube.com/watch?v=Xw5ojR2Ygcw&list=PLnMKNibPkDnFlFe2NTzTLsh4Acoh-cvYR&index=15)

## Overlay File System (Optional)
To extend the lifetime of the MicroSD Card of your RP (if you are using one) you can enable the Overlay File System that is built-in in the Raspberry Pi OS.<br>
In short, this will set the MicroSD Card in read-only mode. Any changes made are now stored in memory which is volatile memory. No write operations to the MicroSD card will considerably extend the lifetime of the card but this will also mean that all changes made will be lost by default after a reboot.
You can easily disable the Overlay File System again but reboots are required. One reboot is needed to enable it and two reboots are needed to disable it again.

I've found a workaround for this as I will explain later on, so that we do not need to reboot the RP several times just to make a small but permanent adjustment in our config.txt file located in `/media/root-ro/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt`.

### Enable the Overlay File System
```bash
sudo raspi-config
```
>```
>- 4 performance Options
>- P2 Overlay File System Enable/disable read-only file system
>- Would you like the overlay file system to be enabled?
>- <Yes>
>- The overlay file system is enabled.
>- <Ok>
>- would you like the boot partition to be write-protected?
>- <Yes>
>- The boot partition is read-only.
>- <Ok>
>- <Finish>
>- Would you like to reboot now?
>- <Yes>
>```
After the reboot, changes made are gone after a reboot.

### Disable the Overlay File System
```bash
sudo raspi-config
```
>```
>- 4 performance Options
>- P2 Overlay File System Enable/disable read-only file system
>- Would you like the overlay file system to be enabled?
>- <No>
>- The overlay file system is disabled.
>- <Ok>
>- The boot partition is currently read-only. This cannot be changed while an overlay file system is enabled.
>- <Ok>
>- <Finish>
>- Would you like to reboot now?
>- <Yes>
>```
Wait till the RP is rebooted. Then connect again over SSH.
```bash
sudo raspi-config
```
>```
>- 4 performance Options
>- P2 Overlay File System Enable/disable read-only file system
>- Would you like the overlay file system to be enabled?
>- <No>
>- The overlay file system is disabled.
>- <Ok>
>- Would you like the boot partition to be write-protected?
>- <No>
>- The boot partition is writable.
>- <Ok>
>- <Finish>
>- Would you like to reboot now?
>- <Yes>
>```
Wait till the RP is rebooted.<br>
Then the RP is fully writable again just like before the Overlay File System was enabled.


### Make permanent adjustments without disabling the Overlay File System

#### Manual method
```bash
sudo mount -o remount,rw /media/root-ro
```

At this point, you can make your permanent changes in `/media/root-ro` or one of its subdirectories. <br>
Eg, if you want to make a permanent change, like creating a file 'test.txt' in the home folder of the 'pi' user: `touch /media/root-ro/home/pi/test.txt`.
In the same way you can make permanent adjustments in the config.txt file.

To switch back to the read-only situation, just remount to read-only.
```bash
sudo mount -o remount,ro /media/root-ro
```
Or reboot the RP
```bash
sudo reboot
```

>[!NOTE]
You can check how the /media/root-ro dir is mounted (RO or RW) by:<br>
>``` bash
>mount -v | grep root-ro`<br>
>```
>
>When mounted in RO:<br>
>`/dev/mmcblk0p2 on /media/root-ro type ext4 (ro,relatime)`
>
>When mounted in RW:<br>
>`/dev/mmcblk0p2 on /media/root-ro type ext4 (rw,relatime)`

#### Using a script

Previously, during the installation process, an (optional) file `adjust-config.txt.sh` was manually copied to the home directory `~/`<br>
This script will detect if the Overlay File System is active and if so, remounts the readonly dir as writable.<br>
Then it opens `config.txt` from the correct location with `nano`. You can make your changes in the `config.txt` file and save it by pressing `Ctrl+x` and follow the instructions. When the settings are saved, nano closes and the script continues.<br>
If the Overlay File System is active, it will remount the readonly dir, that was previously remounted as writable, back to readonly.<br>
Then it will ask you if it is ok to restart the ST-Link GDB Server service. This will force the service to reload the (changed) settings in the `config.txt` file.

Before you can run this script, you have to give it execute rights
```bash
chmod +x ~/adjust-config.txt.sh
```

If you want to make permanent changes into the config.txt file, you can execute the script in the home folder ~/:
```bash
./adjust-config.txt.sh
```
This way, if the Overlay File System is active, the adjustments are kept, even after a reboot.

## Symbolic Links (Optional)
It can be that you often need to make adjustments in the config.txt file when eg switching constantly between projects with different needs.<br>
The config file is located in `/opt/st/stm32cubeclt_1.18.0/
STLink-gdb-server/bin/config.txt`.<br>
It is more accessible to check the config.txt file when you create a kind of 'shortcut' aka symbolic 
link to this file in your home folder `~/`

### Overlay File System not active
To create such a shortcut when the Overlay File System is not active, you can use:
```bash
ln -s /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt ~/config.txt
```

### Overlay File System active
When the Overlay File System is active you cannot make permanent changes. Not for creating the symbolic link, nor for making permanent adjustments in the file to where the symbolic link is pointing to. At least, not by default.
To create a symbolic link while the Overlay File System is active:<br>
Remount the /media/root-ro directory as RW as explained above
```bash
sudo mount -o remount,rw /media/root-ro
```
```bash
ln -s /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt /media/root-ro/home/pi/config.txt
```
Remount the /media/root-ro directory as RW as explained above
```bash
sudo mount -o remount,ro /media/root-ro
```
Or disable the Overlay File System completely (incl. 2x reboot), create the symbolic link and enable it again.

If you now want to check the config.txt file while you are located in the home directory, you can use the symbolic link:
```bash
sudo nano config.txt
```
or from whatever directory you are currently working in with:
```bash
sudo nano ~\config.txt
```
>[!NOTE]
You cannot make, in this case, permanent changes in the ~/config.txt file because it is pointing to `/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt /media/root-ro/home/pi/config.txt` and with the Overlay File System active, any changes made are stored in RAM and will be lost after a reboot.
>
>You could make the symbolic link pointing to `/media/root-ro/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt /media/root-ro/home/pi/config.txt` and then first remount `/media/root-ro` as rw, make adjustments in the file and then remount `/media/root-ro´ as ro.<br>
(Note that the symbolic link will point to an non existing location when the Overlay File System is later on disabled.)
Or just disable the Overlay File System completely, make adjustments and enable it again.
That all is a lot of work. You can better use the above mentioned script for it.

### Check Symbolic Link
You can check if something is a symbolic link by using:
```bash
ls -l
```
If you see in the output an arrow `->` you know that it is a symbolic link and you can see to were it is pointing to.<br>
Eg:<br>
`lrwxrwxrwx  1 pi pi   60 Jun  7 11:34 config.txt -> /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt`

### Remove Symbolic Link
To remove the symbolic link again:
```bash
unlink  ~/config.txt
```
or 
```bash
rm ~/config.txt
```
This will only remove the symbolic link, not the dir or file it is pointing to.


## More info about the config.txt file (Informational)
<span style="color: red;">
<-Under construction...-><br>
</span>
In STM32CubeIDE you can set all settings in the GUI and then click on the export button to see all the parameters used. You can take the parameters from this export and use them in the config.txt file.

<span style="color: red;">
<-There seems to be a lot more settings then by default present/set in the config.txt file.->
</span>

## How to connect to the remote ST-Link GDB Server with STM32CubeIDE
<span style="color: red;">
<-Under construction...-><br>
</span>

[STM32CubeIDE - Remote Debug](https://www.youtube.com/watch?v=Xw5ojR2Ygcw&list=PLnMKNibPkDnFlFe2NTzTLsh4Acoh-cvYR&index=14)

## The usage of multiple hardware Debuggers (Informational)
<span style="color: red;">
<-Under construction...-><br>
< -> I believe it must be possible to connect more then one ST-LINK probe. If so they multiple ST-Link GDB Server instances can be started each process is using then it's own config.txt settings. In that config.txt file is then the unique serial nr of the ST-Link probe defined so to process knows which ST-Link probe to use. Each instance should listen on it's own unique port. This is also configurable in the config.txt file of that process. >
</span>

## SWO/SWV (Informational)
<span style="color: red;">
<-Under construction...-><br>
</span>

[STM32CubeIDE - SWV trace](https://www.youtube.com/watch?v=zvj5NY7hh20&list=PLnMKNibPkDnFlFe2NTzTLsh4Acoh-cvYR&index=8)

## How to debug multi core MCU's (Informational)
<span style="color: red;">
<-Under construction...-><br>
</span>

[
STM32 Dual Core #1. Getting started with STM32 Dual Core CPUs || STM32H745 || How to DEBUG - 8:40](https://www.youtube.com/watch?v=jI1k6p-fduE)

[STM32CubeIDE - AttachDebug - 2:28](https://www.youtube.com/watch?v=tYKXYpWQkNQ&list=PLnMKNibPkDnFlFe2NTzTLsh4Acoh-cvYR&index=6)


### Connect with both STM32CubeIDE and STM32CubeMonitor (Informational)
<span style="color: red;">
<-Under construction...-><br>
</span>

### ST-Link GDB Server Start-Up Options (Informational)

The ST-Link GDB server startup options are described in: 
[ST-Link GDB Server Start-Up Options](https://www.st.com/resource/en/user_manual/um2576-stm32cubeide-stlink-gdb-server-stmicroelectronics.pdf)


When I start ST-LINK_gdbserver with the --help parameter, I see some extra options are also available next to the options described in the above document:

>ST-LINK_gdbserver.exe --help<br>
>USAGE:
>
>   ST-LINK_gdbserver.exe  [--semihost-console-port <port number>]
                          [--semihosting <semihost level>]
                          [--external-init] [--pend-halt-timeout <Pending
                          halt timeout>] [--halt] [-c <config file>] [-e]
                          [-f <log file>] [-l <log level>] [-p <port
                          number>] [-v] [-r <refresh delay>]
                          [--incremental] [-s] [-d] [-z <port number>] [-a
                          <cpu clock>] [-b <SWO CLOCKDIV>] [-k] [-q] [-i
                          <ST-LINK S/N>] [-m <apID>] [-g] [-t]
                          [--erase-all] [--memory-map <device id>]
                          [--ext-memory-loaders] [-ei <file_path>] ...
                          [-el <file_path>] ...  [-cp <path>] [--temp-path
                          <path>] [--preserve-temps] [--frequency <max freq
                          kHz>] [--licenses] [--] [--version] [-h]
>
>Where:
>
>   --semihost-console-port <port number><br>
     Port number for semihost console clients<br>
   --semihosting <semihost level><br>
     Select semihosting mode<br>
   --external-init<br>
     Run Init() from external loader after reset<br>
   --pend-halt-timeout <Pending halt timeout><br>
     Maximum time to wait for core to halt<br>
   --halt<br>
     Halt all cores during reset<br>
   -c <config file>,  --config-file <config file><br>
     Read the config params from config file<br>
   -e,  --persistent<br>
     Enable persistent mode<br>
   -f <log file>,  --log-file <log file><br>
     Path to log file<br>
   -l <log level>,  --log-level <log level><br>
     Logging level between 0 to 31<br>
   -p <port number>,  --port-number <port number><br>
     TCP port number for GDB client<br>
   -v,  --verbose<br>
     Turn ON verbose mode<br>
   -r <refresh delay>,  --refresh-delay <refresh delay><br>
     Minimum delay in seconds for hardware status refresh<br>
   --incremental<br>
     Turn ON incremental flash programming<br>
   -s,  --verify<br>
     Turn ON flash download verify<br>
   -d,  --swd<br>
     Enable SWD debug mode      [use for SWV]<br>
   -z <port number>,  --swo-port <port number><br>
     SWO output port number     [use for SWV]<br>
   -a <cpu clock>,  --cpu-clock <cpu clock><br>
     CPU clock speed in Hz      [use for SWV]<br>
   -b <SWO CLOCKDIV>,  --swo-clock-div <SWO CLOCKDIV><br>
     Divide CPU clock by SWO CLOCKDIV<br>
   -k,  --initialize-reset<br>
     Initialize the device under reset condition<br>
   -q,  --debuggers<br>
     List serial number for connected ST-LINK devices<br>
   -i <ST-LINK S/N>,  --serial-number <ST-LINK S/N><br>
     ST-LINK serial number<br>
   -m <apID>,  --apid <apID><br>
     Select core on multi-core devices<br>
   -g,  --attach<br>
     Attach to running target<br>
   -t,  --shared<br>
     Shareable ST-LINK  [using ST-LINK server]<br>
   --erase-all<br>
     Erase all memories<br>
   --memory-map <device id><br>
     Show memory map for device id<br>
   --ext-memory-loaders<br>
     List of available external memory-loaders<br>
   -ei <file_path>,  --extload_init <file_path>  (accepted multiple times)<br>
     Custom external memory-loader with initialization after reset<br>
   -el <file_path>,  --extload <file_path>  (accepted multiple times)<br>
     Custom external memory-loader<br>
   -cp <path>,  --stm32cubeprogrammer-path <path><br>
     Path to STM32CubeProgrammer installation<br>
   --temp-path <path><br>
     Temporary files for starting a debug session are stored in the<br>
     provided path<br>
   --preserve-temps<br>
     Will not remove used temporary files<br>
   --frequency <max freq kHz><br>
     Select com frequency in kHz<br>
   --licenses<br>
     List of used tools and licenses<br>
   --,  --ignore-rest<br>
     Ignores the rest of the labeled arguments following this flag<br>
   --version<br>
     Displays version information and exits<br>
   -h,  --help<br>
     Displays usage information and exits<br>

## References (Informational)
### Box64
[Instruction how to install Box64](https://pimylifeup.com/raspberry-pi-x64/)<br>
[Extra info](https://github.com/ptitSeb/box64/blob/main/docs/COMPILE.md)

### ST
[ST-Link GDB Server](https://www.st.com/resource/en/user_manual/um2576-stm32cubeide-stlink-gdb-server-stmicroelectronics.pdf)

[ST-Link Server](https://www.st.com/resource/en/data_brief/st-link-server.pdf)<br>
[ST-Link Server - Documentation](https://www.st.com/en/development-tools/st-link-server.html#documentation)

### Youtube:
[STM32 Advanced Debugging](https://www.youtube.com/playlist?list=PL7tUZeMaichqrlJN4PGu3-n6DbYrvoG-s)

[MOOC - STM32CubeIDE Basics](https://www.youtube.com/playlist?list=PLnMKNibPkDnFCosVVv98U5dCulE6T3Iy8)

[STM32CubeIDE Tutorials](https://www.youtube.com/playlist?list=PLnMKNibPkDnFlFe2NTzTLsh4Acoh-cvYR)<br>
--> [STM32CubeIDE - Remote Debug](https://www.youtube.com/watch?v=Xw5ojR2Ygcw&list=PLnMKNibPkDnFlFe2NTzTLsh4Acoh-cvYR&index=15)<br>
-->(Optional) [STM32CubeIDE - SWV trace](https://www.youtube.com/watch?v=zvj5NY7hh20&list=PLnMKNibPkDnFlFe2NTzTLsh4Acoh-cvYR&index=9)


### To be tested:

[(sudo) apt-get install stlink-tools](https://community.st.com/t5/stm32cubeide-mcus/install-stm32cubeide-on-raspberry-pi/td-p/238464)<br>
...<br>
You can use st-flash ((sudo) apt-get install stlink-tools). There is also a gui alternative ((sudo) apt-get install stlink-gui). stlink-gui also install stlink-tools.

If you need a development tool chain, you can try binutils-arm-none-eabi. (sudo apt-get install binutils-arm-none-eabi).<br>
...<br>

[GitHub stlink-org](https://github.com/stlink-org/stlink?tab=readme-ov-file)


<hr style="border-top:3px double #666; margin:1em 0;">





<!--

#To be processed

##More info on chmod usage:
Check execute rights with: ls -l)
You can use chmod to give the required permissions
chmod syntax ->   https://www.geeksforgeeks.org/chmod-command-linux/
  chmod +x ST-LINK_gdbserver.sh
u+x -> The owner execute rights
g+x -> The group execute rights
o+x -> other execute rights
+x -> owner and group and other execute rights


##You can view the output is using journalctl and console as configured in the .service file.
The journalctl part still needs to be tested


##(Optional) Some extra info around systemd/sysemctl:

Some more command examples to enable, start, stop, restart or just check the status of the newly created stlink-gdb-server.service
rpi ~$ sudo systemctl enable stlink-gdb-server.service
rpi ~$ systemctl status stlink-gdb-server.service
rpi ~$ systemctl start|stop|restart stlink-gdb-server.service
and all other commands from systemctl.

sudo systemctl daemon-reload   ->
If you change /lib/systemd/system/<servicename>.service and restart via systemctl restart <servicename>.service
it will not load the new settings unless you do a systemctl daemon-reload. Instead, it will just restart the old cached settings with no changes.
Alternatively, you can also reboot the entire system and the newly rebooted system will also read the new configurations for the service.
It's a "soft" reload, essentially; taking changed configurations from filesystem and regenerating dependency trees.

More info regarding the 'Type' setting:
https://superuser.com/questions/1274901/systemd-forking-vs-simple

Target ->
https://opensource.com/article/20/5/systemd-startup
The default.target file is a symbolic link to the true target file. For a desktop workstation, this is typically going to be the graphical.target, which is equivalent to runlevel 5 in SystemV. For a server, the default is more likely to be the multi-user.target, which is like runlevel 3 in SystemV. The emergency.target file is similar to single-user mode. Targets and services are systemd units.
multi-user.target   All services running, but command-line interface (CLI) only
graphical.target    Multi-user.target with a GUI
default.target      This target is always aliased with a symbolic link to either multi-user.target or graphical.target. systemd always uses the default.target to start the system. 

More info about StandardOutput=journal StandardError=journal
-> normally not neede but if you add journal then you can follow the output of the script through journalctl
	journalctl -u my_script.service -f
The -u flag specifies the unit (service), and the -f flag means to follow the log output in real-time.

More info on StandardOutput=journal+console en StandardError=journal+console   
->  https://blog.stolle.email/2020/05/02/output-systemd-daemon-to-console/

To send the output to a specific tty
-> https://unix.stackexchange.com/questions/523912/how-to-redirect-the-output-of-custom-systemd-service-to-specific-console


##
*Nice To Have: 
optional journald / journalclt   ->  How to shoe the output of the .sh script? -> still needs to be find out
Maybe it is useful to create a script that after the ssh connection the journalclt is started in follow mode? Maybe the output is shown after connectiong over ssh. When you want to do someting else, you probably have to press ctrl+c to exit the follow mode and do your think. Then afterwards, the output mode can maybe be manually started again.




# STILL TO-DO:
-Add section on how to give a fixed IP.
Maybe set with sudo nmtui edit "Wired connection 1" a fixed IP
or may be give your rp and pc a second fixed ip in a different subnet na bv een extra wifi dongle in uw pc te steken (en misschien ook in uw RP) (dat dan het fixed ip heeft).
this way, the pc can access the RP over it's wifi dongle (direct ad-hoc connection) with fixed ip in a different subnet, and the regular wifi/nic of your pc and RP can access the internet through regual DHCP config of the original NIC.
-Install on NVME
-How to update
-What happens when there is a firmware update for ST-Link available? Is it also possible to upgrade the firmware of the ST-Link this way? Or should you better connect the ST-LINK probe to the local USB port of your laptop to do this as a workaround?
-Test to check if this also works with STLINK V3
-It seems that for SWO/SWV usage, certain settings in the config.txt are required.
Eg. You need to start the gdb server with different setting depending on the supported frequency of your MCU.
#### Options without SWV
####  ST-LINK_gdbserver.exe -e -d -cp C:/ST/STM32CubeIDE_1.3.0/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.cubeprogrammer.win32_1.3.0.202002181050/tools/bin
####
#### Options with SWV, Core clock 168MHz, SWO Clock 1 MHz
####  ST-LINK_gdbserver.exe -e -d -z 61235 -a 168000000 -b 168 -cp C:/ST/STM32CubeIDE_1.3.0/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.cubeprogrammer.win32_1.3.0.202002181050/tools/bin

-> Maybe it is possible or usefull to start multiple gdb servers listning on different ports each zith it's own freaquency for SWV?
or one service with and one without SWV enabled? (probably to much overkill)

-It seems that for multi core certain settings in the config.txt are required.
• -m <apID>, --apid <apID>
Defines the apID to debug.
[Use this option for muti-core.]

-in the config.txt you ave a --frequency <max freq kHz>
Specifies the ST-LINK communication frequency in kHz, such as 5, 25, 100, 240, 950, 1800, 4000, 8000, 
24000 kHz.
This is not set by default in the config.txt file. Which frequency is used by default when it is not explicitly set in the config.txt file?  Mad Speed???



# Markdown syntax for GitHub:

https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
...
> [!NOTE]
> Useful information that users should know, even when skimming content.

> [!TIP]
> Helpful advice for doing things better or more easily.

> [!IMPORTANT]
> Key information users need to know to achieve their goal.

> [!WARNING]
> Urgent info that needs immediate user attention to avoid problems.

> [!CAUTION]
> Advises about risks or negative outcomes of certain actions.
...

-->





