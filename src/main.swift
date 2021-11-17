import Foundation

let fm = FileManager.default

if !fm.fileExists(atPath: SCLIInfo.shared.SuccessorCLIPath) {
    printIfDebug("Didn't find \(SCLIInfo.shared.SuccessorCLIPath) directory..proceeding to try to create it..")
    do {
        try fm.createDirectory(atPath: SCLIInfo.shared.SuccessorCLIPath, withIntermediateDirectories: true, attributes: nil)
        printIfDebug("Successfully created directory. Continuing.")
    } catch {
        fatalError("Error encountered while creating directory \(SCLIInfo.shared.SuccessorCLIPath): \(error.localizedDescription)\nNote: Please create the directory yourself and run SuccessorCLI again. Exiting")
    }
}

// Due to the first argument from CommandLine.arguments being the program name, we need to drop that.
let CMDLineArgs = Array(CommandLine.arguments.dropFirst())
printIfDebug("Args used: \(CMDLineArgs)")

for args in CMDLineArgs {
    switch args {
    case "--help", "-h":
        SCLIInfo.shared.printHelp()
        exit(0)
    case "-d", "--debug":
        printIfDebug("DEBUG Mode Triggered.")
    case _ where CommandLine.arguments.contains("--dmg-path") && CommandLine.arguments.contains("--ipsw-path"):
        fatalError("Can't use both --dmg-path AND --ipsw-path together..exiting..")
        
        // Support for manually specifying iPSW:
        // This will unzip the iPSW, get RootfsDMG from it, attach and mount that, then execute restore.
    case "--ipsw-path":
        guard let index = CMDLineArgs.firstIndex(of: "--ipsw-path"), let iPSWSpecified = CMDLineArgs[safe: index + 1] else {
            fatalError("User used --ipsw-path, however the program couldn't get the iPSW Path specified, make sure you specified one. See SuccessorCLI --help for more info.")
        }
        print("User manually specified iPSW Path to \(iPSWSpecified)")
        guard fm.fileExists(atPath: iPSWSpecified) && NSString(string: iPSWSpecified).pathExtension == "ipsw" else {
            fatalError("ERROR: file \"\(iPSWSpecified)\" Either doesn't exist or isn't an iPSW")
        }
        iPSWManager.onboardiPSWPath = iPSWSpecified
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWSpecified, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        
        // Support for manually specifying rootfsDMG:
    case "--dmg-path":
        guard let index = CMDLineArgs.firstIndex(of: "--dmg-path"), let dmgSpecified = CMDLineArgs[safe: index + 1] else {
            fatalError("User used --dmg-path, however the program couldn't get DMG Path specified, make sure you specified one. See SuccessorCLI --help for more info.")
        }
        print("User manually specified DMG Path to \(dmgSpecified)")
        guard fm.fileExists(atPath: dmgSpecified) && NSString(string: dmgSpecified).pathExtension == "dmg" else {
            fatalError("File \"\(dmgSpecified)\" Either doesnt exist or isnt a DMG file.")
        }
        DMGManager.shared.rfsDMGToUseFullPath = dmgSpecified
        
        // Support for manually specifying rsync binary:
    case "--rsync-bin-path":
        guard let index = CMDLineArgs.firstIndex(of: "--rsync-bin-path"), let rsyncBinSpecified = CMDLineArgs[safe: index + 1] else {
            fatalError("User used --rsync-bin-path, however the program couldn't get Rsync executable Path specified, make sure you specified one. See SuccessorCLI --help for more info.")
        }
        guard fm.fileExists(atPath: rsyncBinSpecified), fm.isExecutableFile(atPath: rsyncBinSpecified) else {
            fatalError("File \"\(rsyncBinSpecified)\" Can't be used because it either doesn't exist or is not an executable file.")
        }
        print("User manually specified rsync executable path as \(rsyncBinSpecified)")
        deviceRestoreManager.rsyncBinPath = rsyncBinSpecified
        
        // Support for manually specifying Mount Point:
    case "--mnt-point-path":
        guard let index = CMDLineArgs.firstIndex(of: "--mnt-point-path"), let mntPointSpecified = CMDLineArgs[safe: index + 1] else {
            fatalError("User used --mnt-point-path, however the program couldn't get the Mount Point specified, make sure you specified one. See SuccessorCLI --help for more info.")
        }
        guard fm.fileExists(atPath: mntPointSpecified) else {
            fatalError("Can't set \(mntPointSpecified) to Mount Point if it doesn't even exist!")
        }
        print("User manually specified MountPoint as \(mntPointSpecified)")
        SCLIInfo.shared.mountPoint = mntPointSpecified
        
        // Support for passing in additional rsync args:
    case "--append-rsync-arg":
        guard let index = CMDLineArgs.firstIndex(of: "--append-rsync-arg"), let rsyncArgSpecified = CMDLineArgs[safe: index + 1] else {
            fatalError("User used --append-rsync-arg, however the program couldn't get rsync arg specified, make sure you specified one. See SuccessorCLI --help for more info.")
        }
        print("User specified to pass in \"\(rsyncArgSpecified)\" to rsync args.")
        deviceRestoreManager.rsyncArgs.append(rsyncArgSpecified)
    default:
        break
    }
}

// detecting for root
// root is needed to execute rsync with enough permissions to replace all files necessary
guard getuid() == 0 else {
    fatalError("ERROR: SuccessorCLI Must be run as root, eg `sudo \(CommandLine.arguments.joined(separator: " "))`")
}

if isNT2() {
    print("[WARNING] NewTerm 2 Detected, I advise you to SSH Instead, as the huge output by rsync may crash NewTerm 2 mid restore.")
}
print("Welcome to SuccessorCLI! Version \(SCLIInfo.shared.ver).")

// MARK: RootfsDMG and iPSW Detection
/*
 The switch case below detects if a RootfsDMG is present in the SuccessorCLI directory.
 If there isn't one, it also checks if there are other DMGs the SuccessorCLI directory, if there are any it'll ask the user if they want to use one.
 If there are also no other DMGs in the SuccessorCLI directory, it will also try to find existing iPSWs in the SuccssorCLI Directory
 If there are existing iPSWs, then they are listed, however whether or not there are existing iPSWs in the SuccessorCLI directory, it'll ask the user if they want SuccessorCLI to download an iPSW for them.
 */
switch fm.fileExists(atPath: DMGManager.shared.rfsDMGToUseFullPath) {
case true:
    print("Found rootfsDMG at \(DMGManager.shared.rfsDMGToUseFullPath), Would you like to use it?")
    print("[1] Yes")
    print("[2] No")
    if let choice = readLine() {
        switch choice {
        case "1", "Y", "y":
            print("Proceeding to use \(DMGManager.shared.rfsDMGToUseFullPath)")
        case "2", "N", "n":
            /*
             If this case gets triggered, the following happens:
             if there are other DMGs in the SuccessorCLIPath, it will list all of them and ask the user if they want to use them. Note this doesn't include subdirectories of the SuccessorCLIPath
             the second to last option will always be asking the user if they want to download the iPSW for their device and version
             the last option will be SuccessorCLI asking the user if they want to do nothing and exit the program
            */
            if !DMGManager.DMGSinSCLIPathArray.isEmpty {
                print("Found other DMGs in \(SCLIInfo.shared.SuccessorCLIPath), What would you like to do?")
                for i in 0...(DMGManager.DMGSinSCLIPathArray.count - 1) {
                    print("[\(i)] Use DMG \(DMGManager.DMGSinSCLIPathArray[i])")
                }
                print("[\(DMGManager.DMGSinSCLIPathArray.count)] let SuccessorCLI download an iPSW for me automatically then extract the RootfsDMG from said iPSW.")
                print("[\(DMGManager.DMGSinSCLIPathArray.count + 1)] Do nothing and exit.")
                if let input = readLine(), let intInput = Int(input) {
                    switch intInput {
                    case DMGManager.DMGSinSCLIPathArray.count:
                        iPSWManager.downloadAndExtractiPSW(iPSWURL: onlineiPSWInfo.iPSWURL)
                    case (DMGManager.DMGSinSCLIPathArray.count + 1):
                        print("Exiting because user specified to do so.")
                        exit(0)
                    default:
                        guard let DMGSpecified = DMGManager.DMGSinSCLIPathArray[safe: intInput] else {
                            fatalError("Inrpoper input.")
                        }
                        DMGManager.shared.rfsDMGToUseFullPath = "\(SCLIInfo.shared.SuccessorCLIPath)/\(DMGSpecified)"
                    }
                }
            }
        default:
            fatalError("Inproper input.")
        }
    }

        // If there's already a DMG in SuccessorCLI Path, inform the user and ask if they want to use it
case false where !DMGManager.DMGSinSCLIPathArray.isEmpty:
    print("Found Following DMGs in \(SCLIInfo.shared.SuccessorCLIPath), Which would you like to use?")
    for i in 0...(DMGManager.DMGSinSCLIPathArray.count - 1) {
        print("[\(i)] Use DMG \(DMGManager.DMGSinSCLIPathArray[i])")
    }
    print("[\(DMGManager.DMGSinSCLIPathArray.count)] let SuccessorCLI download an iPSW for me automatically then extract the RootfsDMG from said iPSW.")
    // Input needs to be Int
    if let choice = readLine(), let choiceInt = Int(choice) {
        if choiceInt == DMGManager.DMGSinSCLIPathArray.count {
            iPSWManager.downloadAndExtractiPSW(iPSWURL: onlineiPSWInfo.iPSWURL)
        } else {
            guard let dmgSpecified = DMGManager.DMGSinSCLIPathArray[safe: choiceInt] else {
                fatalError("Inproper Input.")
            }
            DMGManager.shared.rfsDMGToUseFullPath = "\(SCLIInfo.shared.SuccessorCLIPath)/\(dmgSpecified)"
        }
    }
    break
    
    // If the case below is triggered, its because theres no rfs.dmg or any type of DMG in the SuccessorCLI Path, note that DMGManager.DMGSinSCLIPathArray doesn't search the extracted path, explanation to why is at DMGManager.DMGSinSCLIPathArray's declaration
case false:
    print("No RootfsDMG Detected, what'd you like to do?")
    if !iPSWManager.iPSWSInSCLIPathArray.isEmpty {
    for i in 0...(iPSWManager.iPSWSInSCLIPathArray.count - 1) {
        print("[\(i)] Extract and use iPSW \"\(iPSWManager.iPSWSInSCLIPathArray[i])\"")
        }
    }
    print("[\(iPSWManager.iPSWSInSCLIPathArray.count)] let SuccessorCLI download an iPSW for me automatically")
    guard let input = readLine(), let intInput = Int(input) else {
        fatalError("Inproper Input.")
    }
    if intInput == iPSWManager.iPSWSInSCLIPathArray.count {
        iPSWManager.downloadAndExtractiPSW(iPSWURL: onlineiPSWInfo.iPSWURL)
    } else {
        guard let iPSWSpecified = iPSWManager.iPSWSInSCLIPathArray[safe: intInput] else {
            fatalError("Inproper Input.")
        }
        iPSWManager.onboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/\(iPSWSpecified)"
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
    }
}

if MntManager.shared.isMountPointMounted() {
    print("\(SCLIInfo.shared.mountPoint) Already mounted, skipping right ahead to the restore.")
} else {
    var diskNameToMnt = ""
    printIfDebug("Proceeding to (try) to attach DMG \"\(DMGManager.shared.rfsDMGToUseFullPath)\"")
    DMGManager.attachDMG(dmgPath: DMGManager.shared.rfsDMGToUseFullPath) { bsdName, err in
        // If the "else" statement is executed here, then that means the program either encountered an error while attaching (see attachDMG function declariation) or it couldn't get the name of the attached disk
        guard let bsdName = bsdName, err == nil else {
            fatalError("Error encountered while attaching: \(err ?? "Unknown Error"). Exiting.")
        }
        printIfDebug("attachDMG: BSD Name of DMG: \(bsdName)")
        guard fm.fileExists(atPath: "/dev/\(bsdName)s1s1") else {
            fatalError("Inproper DMG was attached.")
        }
        diskNameToMnt = "/dev/\(bsdName)s1s1"
        print("Successfully attached \(DMGManager.shared.rfsDMGToUseFullPath) to \(diskNameToMnt)")
    }

    MntManager.mountNative(devDiskName: diskNameToMnt, mountPointPath: SCLIInfo.shared.mountPoint) { mntStatus in
        guard mntStatus == 0 else {
            fatalError("Wasn't able to mount successfully..error: \(String(cString: strerror(errno))). Exiting..")
        }
        print("Mounted \(diskNameToMnt) to \(SCLIInfo.shared.mountPoint) Successfully. Continiung!")
    }
}

switch CMDLineArgs {
case _ where CMDLineArgs.contains("--no-restore"):
    print("Successfully attached and mounted RootfsDMG, exiting now because the user used --no-restore.")
    exit(0)
case _ where !CMDLineArgs.contains("--no-wait"):
    print("You have 15 seconds to cancel the restore before it starts, to cancel, Press CTRL+C.")
    for time in 0...15 {
        sleep(UInt32(time))
        print("Starting restore in \(15 - time) Seconds.")
    }
default:
    break
}

print("Proceeding to launch rsync..")

deviceRestoreManager.launchRsync()
print("Rsync done, now time to reset device.")
deviceRestoreManager.callSBDataReset()
