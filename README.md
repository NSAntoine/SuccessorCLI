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
Simply run `sudo successorcli` in terminal through SSH or NewTerm 2. See below for options that can be used with SuccessorCLI, although aren't neccessary.

# Options  
The follwing options can be used with SuccessorCLI:
#### General options:
- `-h, --help` Prints the help message then exits
- `-d, --debug` Prints extra debug information which may be helpful

#### Options for manually specifying:
- `--mnt-point-path /PATH/TO/MOUNT` Specify the directory to where the attached RootfsDMG will be mounted to
- `--ipsw-path /PATH/TO/IPSW` Specify iPSW Which'll be used
- `--dmg-path /PATH/TO/ROOTFSDMG` Specify the rootfsDMG to use
- `--rsync-bin-path /PATH/TO/RSYNC/BIN` Specify the Rsync executable to launch rsync restore with
- `--scli-path /PATH/TO/SET` Manually specify the SuccessorCLI directory.

#### Options for Rsync / Restore stuff:
- `--append-rsync-arg=RSYNC-ARG-TO-APPEND` Specify an additional rsync argument to be passed in to rsync, for example: `--append-rsync-arg="--exclude=/some/directory"` will pass in `--exclude=/some/directory` to rsync 

- `--rsync-dry-run` Specifies that rsync should run with `--dry-run`
- `--restore` Do a full restore with rsync. Note that this WILL erase your device.


##### Notes: 
- You can't use both `--dmg-path` and `--ipsw-path` together at the same time.
- All arguments are optional.
- If `--restore` is not used, then SuccessorCLI will not execute the rsync restore. Use `--restore` if you want SuccesorCLI to execute the restore.
- If -`-mnt-point-path` is not used, then the default Mount Point is set to `/var/mnt/successor/`.
- Using `--scli-path` will change the SuccessorCLI Path, which changes where DMGs/iPSWs are searched for and changes the path of where iPSWs are downloaded if the user chooses to do so

# Project Status
The program does work right now, I've tested it multiple times on an iPhone 8 running iOS 14.5, Im just polishing up the project right now.

*Note*: this project is in beta, im not responsibile for whatever happens to you, your phone, and your cat. Use at your own discretion blah blah you know the bullshit.
