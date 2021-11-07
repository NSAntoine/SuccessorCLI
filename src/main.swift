import Foundation

let fm = FileManager.default

if !fm.fileExists(atPath: SCLIInfo.shared.SuccessorCLIPath) {
    printIfDebug("Didn't find \(SCLIInfo.shared.SuccessorCLIPath) directory..proceeding to try to create it..")
    do {
        try fm.createDirectory(atPath: SCLIInfo.shared.SuccessorCLIPath, withIntermediateDirectories: true, attributes: nil)
        printIfDebug("Successfully created directory. Continuing.")
    } catch {
        errPrint("Error encountered while creating directory \(SCLIInfo.shared.SuccessorCLIPath): \(error.localizedDescription)\nNote: Please create the directory yourself and run SuccessorCLI again. Exiting", line: #line, file: #file)
        exit(EXIT_FAILURE)
    }
}

// We first need to filter out the program name, which always happens to be the first argument with CommandLine.arguments
let CMDLineArgs = CommandLine.arguments.filter() { $0 != CommandLine.arguments[0] }

printIfDebug("Args used: \(CMDLineArgs)")

for args in CMDLineArgs {
    switch args {
    case "--help", "-h":
        SCLIInfo.shared.printHelp()
        exit(0)
    case "-v", "--version":
        print("SuccessorCLI Version \(SCLIInfo.shared.ver)")
        exit(0)
    case "-d", "--debug":
        printIfDebug("DEBUG Mode Triggered.")
    case _ where CommandLine.arguments.contains("--dmg-path") && CommandLine.arguments.contains("--ipsw-path"):
        errPrint("Can't use both --dmg-path AND --ipsw-path together..exiting..", line: #line, file: #file)
        exit(EXIT_FAILURE)
    case "--ipsw-path":
        guard let index = CMDLineArgs.firstIndex(of: "--ipsw-path"), CMDLineArgs.indices.contains(index + 1) else {
            print("User used --ipsw-path, however the program couldn't get the iPSW Path specified, are you sure you specified one?")
            exit(EXIT_FAILURE)
        }
        let iPSWSpecified = CMDLineArgs[index + 1]
        printIfDebug("User manually specified iPSW Path to \(iPSWSpecified)")
        guard fm.fileExists(atPath: iPSWSpecified) && NSString(string: iPSWSpecified).pathExtension == "ipsw" else {
            errPrint("ERROR: file \"\(iPSWSpecified)\" Either doesn't exist or isn't an iPSW file.", line: #line, file: #file)
            exit(EXIT_FAILURE)
        }
        iPSWManager.onboardiPSWPath = iPSWSpecified
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWSpecified, destinationPath: iPSWManager.extractedOnboardiPSWPath)
    case "--dmg-path":
        guard let index = CMDLineArgs.firstIndex(of: "--dmg-path"), CMDLineArgs.indices.contains(index + 1) else {
            print("User used --dmg-path, however the program couldn't get DMG Path specified, are you sure you specified one?")
            exit(EXIT_FAILURE)
        }
        let dmgSpecified = CMDLineArgs[index + 1]
        printIfDebug("User manually specified DMG Path to \(dmgSpecified)")
        guard fm.fileExists(atPath: dmgSpecified) && NSString(string: dmgSpecified).pathExtension == "dmg" else {
            errPrint("ERROR: file \"\(dmgSpecified)\" Either doesnt exist or isnt a DMG file.", line: #line, file: #file)
            exit(EXIT_FAILURE)
        }
        DMGManager.shared.rfsDMGToUseFullPath = dmgSpecified
    default:
        break
    }
}

// detecting for root
guard getuid() == 0 else {
    errPrint("ERROR: SuccessorCLI Must be run as root, eg `sudo \(CommandLine.arguments.joined(separator: " "))`", line: #line, file: #file)
    exit(EXIT_FAILURE)
}

printIfDebug("Online iPSW URL: \(onlineiPSWInfo.iPSWURL)\nOnline iPSW Filesize (unformatted): \(onlineiPSWInfo.iPSWFileSize)\nOnline iPSW Filesize (formatted): \(onlineiPSWInfo.iPSWFileSizeForamtted)")
if isNT2() {
    print("[WARNING] NewTerm 2 Detected, I advise you to SSH Instead, as the huge output by rsync may crash NewTerm 2 mid restore.")
}
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
            print("User specified not to use RootfsDMG at \(DMGManager.shared.rfsDMGToUseFullPath). Exiting.")
            exit(0)
        default:
            print("Unkown input \"\(choice)\". Exiting.")
            exit(EXIT_FAILURE)
        }
    }

case false where !iPSWManager.iPSWSInSCLIPathArray.isEmpty:
    print("Found following iPSWs at \(SCLIInfo.shared.SuccessorCLIPath), What would you like to do?")
    for i in 0...(iPSWManager.iPSWSInSCLIPathArray.count - 1) {
        print("[\(i)] Use iPSW \"\(iPSWManager.iPSWSInSCLIPathArray[i])\"")
    }
    print("[\(iPSWManager.iPSWSInSCLIPathArray.count)] Make SuccessorCLI Download an iPSW for you")
    if let choice = readLine(), let intChoice = Int(choice) {
        if intChoice == iPSWManager.iPSWSInSCLIPathArray.count {
            let conflictingPaths = [iPSWManager.extractedOnboardiPSWPath, iPSWManager.onboardiPSWPath]
            for conflictingPath in conflictingPaths {
                if fm.fileExists(atPath: conflictingPath) {
                    print("User specified to download iPSW however conflicting path \(conflictingPath) Already exists, would you like to remove the conflicting path first?")
                    print("[1] Yes")
                    print("[2] No")
                    if let choice = readLine() {
                    switch choice {
                    case "1", "Y", "y":
                        do {
                            try fm.removeItem(atPath: conflictingPath)
                        } catch {
                            errPrint("Error while removing conflicting path: \(error.localizedDescription). Exiting.", line: #line, file: #file)
                            exit(EXIT_FAILURE)
                        }
                    case "2", "n", "N":
                        print("Exiting.")
                        exit(EXIT_FAILURE)
                    default:
                        print("Unkown input \(choice), exiting.")
                    }
                    }
                }
            }
            iPSWManager.downloadAndExtractiPSW(iPSWURL: onlineiPSWInfo.iPSWURL)
        } else {
            iPSWManager.onboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/\(iPSWManager.iPSWSInSCLIPathArray[intChoice])"
            iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        }
    }

case false where iPSWManager.iPSWSInSCLIPathArray.isEmpty:
    print("No iPSW Found at \(SCLIInfo.shared.SuccessorCLIPath), Would you like for SuccessorCLI to download one for you?")
    print("[1] Yes")
    print("[2] No")
    if let choice = readLine() {
        switch choice {
        case "1", "Y", "y":
            iPSWManager.downloadAndExtractiPSW(iPSWURL: onlineiPSWInfo.iPSWURL)
        case "2", "N", "n":
            print("Please figure out what you want to do then run SuccessorCLI Again, note that you can manually specify an iPSW file path with --ipsw-path or manually specify a DMG File path with --dmg-path")
            exit(0)
        default:
            print("Unkown Input \(choice), Exiting.")
            exit(EXIT_FAILURE)
        }
    }
default:
    break
}

if MntManager.shared.isMountPointMounted() {
    print("\(SCLIInfo.shared.mountPoint) Already mounted, skipping right ahead to the restore.")
} else {
    var diskNameToMnt = ""

    DMGManager.attachDMG(dmgPath: DMGManager.shared.rfsDMGToUseFullPath) { bsdName, err in
        guard err == nil else {
            errPrint("Error encountered while attaching DMG \(DMGManager.shared.rfsDMGToUseFullPath): \(err!)", line: #line, file: #file)
            exit(EXIT_FAILURE)
        }
        guard let bsdName = bsdName else {
            print("Attached Rfs DMG However wasn't able to get name..exiting.")
            exit(EXIT_FAILURE)
        }
        printIfDebug("Got attached disk name at \(bsdName)")
        diskNameToMnt = "/dev/\(bsdName)s1s1"
    }

    MntManager.mountNative(devDiskName: diskNameToMnt, mountPointPath: SCLIInfo.shared.mountPoint) { mntStatus in
        guard mntStatus == 0 else {
            errPrint("Wasn't able to mount successfully..error: \(String(cString: strerror(errno))). Exiting..", line: #line, file: #file)
            exit(EXIT_FAILURE)
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
    sleep(15)
default:
    break
}

print("proceeding to launch rsync..")

deviceRestoreManager.launchRsync()
print("Rsync done, now time to reset device.")
deviceRestoreManager.callMobileObliterator()
