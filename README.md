# SuccessorCLI
A CLI tool to restore iOS devices on the version they're already on, inspired by the original Succession GUI Application, rewritten from the ground up in Swift.
# Building
You must have Theos for this, and if you're not on macOS, you must've installed the swift toolchain for theos before aswell.
To generate a deb, run the following:
```
git clone https://github.com/dabezt31/SuccessorCLI
cd SuccessorCLI
make package
```
Due to this project using private frameworks, you must be compiling with a patched SDK rather than a normal one.
# Usage
Simply run `sudo successorcli` in terminal through SSH or NewTerm 2. See below for options that can be used with SuccessorCLI, although aren't neccessary.

# Options  
The follwing options can be used with SuccessorCLI:
- `-h, --help` Prints the help message then exits
- `-v, --version` Prints the Current SuccessorCLI Version then exit
- `-d, --debug` Prints extra debug information which may be helpful
- `--ipsw-path /PATH/TO/IPSW` Specify iPSW Which'll be used
- `--dmg-path /PATH/TO/ROOTFSDMG` Specify the rootfsDMG to use
- `--no-restore` Downloads and extracts iPSW, gets the RootfsDMG, attach and mount RootfsDMG, then exit right before the restore is supposed to start
- `--no-wait` Removes the 15 seconds given to the user before the restore begins and instead begins the restore immediately

Specifying an iPSW With `--ipsw-path` will unzip the given iPSW to /var/mobile/Media/SuccessorCLI/extracted, then get the largest DMG From there, then attach and mount said DMG.

Specifying a Rootfs DMG With `--dmg-path` Will attach and mount given the DMG, then start the restore.
# Project Status
The program does work right now, I've tested it multiple times on an iPhone 8 running iOS 14.5, Im just polishing up the project right now.

*Note*: this project is in beta, im not responsibile for whatever happens to you, your phone, and your cat. Use at your own discretion blah blah you know the bullshit
# Objectives
Although the project can unzip the iPSW successfully right now, the way it does it is by calling the `unzip` command from the command line, which does work but it would be much better practice if I used another way of unzipping the iPSW, the project used to use libzip however that turned out to be unbelievably slow (20 minutes unzipping time!) So i switched to calling the unzip command which honestly was much better, TL;DR A better way to unzip would be nice
