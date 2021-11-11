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
print("Welcome to SuccessorCLI! Version \(SCLIInfo.shared.ver).")
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

        // If there's already a DMG in SuccessorCLI Path, inform the user and ask if they want to use it
case false where !DMGManager.DMGSinSCLIPathArray.isEmpty:
    print("Found Following DMGs in \(SCLIInfo.shared.SuccessorCLIPath), Which would you like to use?")
    for i in 0...(DMGManager.DMGSinSCLIPathArray.count - 1) {
        print("[\(i)] Use DMG \(DMGManager.DMGSinSCLIPathArray[i])")
    }
    print("[\(DMGManager.DMGSinSCLIPathArray.count)] let SuccessorCLI download an iPSW for me automatically then extract the RootfsDMG from said iPSW.")
    if let choice = readLine(), let choiceInt = Int(choice) {
        if choiceInt == DMGManager.DMGSinSCLIPathArray.count {
            iPSWManager.downloadAndExtractiPSW(iPSWURL: onlineiPSWInfo.iPSWURL)
        } else {
            guard DMGManager.DMGSinSCLIPathArray.indices.contains(choiceInt) else {
                errPrint("Inproper Input.", line: #line, file: #file)
                exit(EXIT_FAILURE)
            }
            let dmgSpecified = "\(SCLIInfo.shared.SuccessorCLIPath)/\(DMGManager.DMGSinSCLIPathArray[choiceInt])"
            DMGManager.shared.rfsDMGToUseFullPath = dmgSpecified
        }
    }
    
    // If the below is triggered, its because theres no rfs.dmg or any type of DMG in /var/mobile/Library/SuccessorCLI, note that DMGManager.DMGSinSCLIPathArray doesn't search the extracted path
case false:
    print("No RootfsDMG Detected, what'd you like to do?")
    if !iPSWManager.iPSWSInSCLIPathArray.isEmpty {
    for i in 0...(iPSWManager.iPSWSInSCLIPathArray.count - 1) {
        print("[\(i)] Extract and use iPSW \"\(iPSWManager.iPSWSInSCLIPathArray[i])\"")
        }
    }
    print("[\(iPSWManager.iPSWSInSCLIPathArray.count)] let SuccessorCLI download an iPSW for me automatically")
    guard let input = readLine(), let intInput = Int(input) else {
        errPrint("Inproper Input.", line: #line, file: #file)
        exit(EXIT_FAILURE)
    }
    if intInput == iPSWManager.iPSWSInSCLIPathArray.count {
        iPSWManager.downloadAndExtractiPSW(iPSWURL: onlineiPSWInfo.iPSWURL)
    } else {
        guard iPSWManager.iPSWSInSCLIPathArray.indices.contains(intInput) else {
            errPrint("Inproper Input.", line: #line, file: #file)
            exit(EXIT_FAILURE)
        }
        let iPSWSpecified = iPSWManager.iPSWSInSCLIPathArray[intInput]
        iPSWManager.onboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/\(iPSWSpecified)"
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
    }
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
    for time in 0...15 {
        sleep(UInt32(time))
        print("Starting restore in \(15 - time) Seconds.")
    }
    print("early exit.")
    exit(0)
default:
    break
}

print("proceeding to launch rsync..")

deviceRestoreManager.launchRsync()
print("Rsync done, now time to reset device.")
deviceRestoreManager.callMobileObliterator()
