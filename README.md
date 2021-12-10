# SuccessorCLI
A CLI tool to restore iOS devices on the version they're already on, inspired by the original Succession GUI Application, rewritten from the ground up in Swift.
# Building
You must have Theos for this, and if you're not on macOS, you must've installed the swift toolchain for theos before aswell.
To generate a deb, run the following:
```
git clone https://github.com/Serena-io/SuccessorCLI
cd SuccessorCLI
make package
```
Due to this project using private frameworks, you must be compiling with a patched SDK rather than a normal one.
# Usage
Open NewTerm2 or SSH Into your device (Preferrably SSH), then run the following command: `sudo successorcli`. If you want the rsync restore to be executed, use `--restore/-r`.

See below for options that can be used with SuccessorCLI

# Options  
The follwing options can be used with SuccessorCLI:
#### General options:
- `-h, --help` Prints the help message then exits

#### Options for manually specifying:
- `--mnt-point-path /PATH/TO/MOUNT` Specify the directory to where the attached RootfsDMG will be mounted to
- `--ipsw-path /PATH/TO/IPSW` Specify iPSW Which'll be used
- `--dmg-path /PATH/TO/ROOTFSDMG` Specify the rootfsDMG to use
- `--rsync-bin-path /PATH/TO/RSYNC/BIN` Specify the Rsync executable to launch rsync restore with

#### Options for Rsync / Restore stuff:
- `--append-rsync-arg=RSYNC-ARG-TO-APPEND` Specify an additional rsync argument to be passed in to rsync, for example: `--append-rsync-arg="--exclude=/some/directory"` will pass in `--exclude=/some/directory` to rsync 

- `--dry-run` Specifies that rsync should run with `--dry-run`
- `--restore` Do a full restore with rsync. Note that this WILL erase your device.


##### Notes: 
- `--restore/-r` must be used if the user wants the restore to be executed.
- If -`-mnt-point-path` is not used, then the default Mount Point is set to `/var/mnt/successor/`.

# Project Status
The program does work right now, I've tested it multiple times on an iPhone 8 running iOS 14.5, Im just polishing up the project right now.

*Note*: this project is in beta, im not responsibile for whatever happens to you, your phone, and your cat. Use at your own discretion blah blah you know the bullshit.
