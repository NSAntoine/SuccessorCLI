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
- `--no-restore` Downloads and extracts iPSW, gets the RootfsDMG, attach and mount RootfsDMG, then exit right before the restore is supposed to start
- `--no-wait` Removes the 15 seconds given to the user before the restore begins and instead begins the restore immediately
- `--online-ipsw-info` Prints Information about the online iPSW obtained from ipsw.me API, see more [Here](https://ipswdownloads.docs.apiary.io/)
- `--ipsw-path /PATH/TO/IPSW` Specify iPSW Which'll be used
- `--dmg-path /PATH/TO/ROOTFSDMG` Specify the rootfsDMG to use
- `--rsync-bin-path /PATH/TO/RSYNC/BIN` Specify the Rsync executable to launch rsync restore with

*Notes*: 
- You can't use both `--dmg-path` and `--ipsw-path` together at the same time.
- `--rsync-bin-path`, `--ipsw-path`, and `--dmg-path` are all optional

# Project Status
The program does work right now, I've tested it multiple times on an iPhone 8 running iOS 14.5, Im just polishing up the project right now.

*Note*: this project is in beta, im not responsibile for whatever happens to you, your phone, and your cat. Use at your own discretion blah blah you know the bullshit.
