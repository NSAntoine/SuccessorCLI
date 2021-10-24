# SuccessorCLI
A CLI tool to restore iOS devices on the version they're already on, inspired by the original Succession GUI Application, rewritten from the ground up in Swift.
# Building
You must have Theos for this, and if you're not on macOS, you must've installed the swift toolchain for theos before aswell.
To generate a deb, run the following:
```sh
git clone https://github.com/dabezt31/SuccessorCLI
cd SuccessorCLI
make package
```

# Usage
Simply run `sudo successorcli` in terminal. See below for options that can be used with successorcli, although arent neccessary

# Options  
The follwing options can be used with SuccessorCLI:
```SuccessorCLI - A CLI Utility to restore iOS devices, based off Succession
            Usage: successorcli <option>
                 -h, --help         Prints this help message
                 -v, --version      Prints current SuccessorCLI Version
                 -u, --unmount      If /var/mnt/successor is mounted, then this will unmount it.
                 --ipsw-path        /PATH/TO/IPSW           Manually specify path of iPSW to use.
                 --dmg-path         /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use.
                 --no-restore       Download and extract iPSW, rename the rootfilesystem DMG to rfs.dmg, then attach and mount rfs.dmg, but won't execute the restore itself.
                 --no-attach        Download and extract iPSW, rename the rootfilesystem DMG to rfs.dmg, then exit.
                 --no-wait          Removes the 15 seconds given for the user to cancel the restore before it starts
                 --mnt-status       Prints whether or not /var/mnt/successor is mounted, then exit
```

# Project Status
The program does work right now, it downloads the iPSW, unzip it, get the rootfs DMG, attach and mount the rootFS DMG, then executes the restore with rsync and lastly calls SBDataReset (Mobile Obliterator), I'm just polishing the project up right now.

Note that this project *is* currently in beta, im not responsible for what happens to you and your device, blah blah you know the bullshit

# Known issues/things to improve:
1. Rsync output is so spammy, it probably crashes NewTerm 2, printing with `terminator: "\r"` doesnt work for rsync progress like it does for iPSW download progress
2. The current way that the rootfs DMG is parsed is by getting the largest file in `/var/mobile/Media/SuccessorCLI/extracted`, which while yes, does work, is bad practice, a better way to parse the Rootfs DMG would be to parse it from the BuildManifest.plist
