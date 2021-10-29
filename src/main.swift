import Foundation

let fm = FileManager.default
/// CommandLine.arguements but filters out "succesorcli"
let CMDLineArgs = CommandLine.arguments.filter() { $0 != CommandLine.arguments[0] }

if CMDLineArgs.contains("--ipsw-path") && CMDLineArgs.contains("--dmg-path") {
    print("ERROR: Cannot use --ipsw-path and --dmg-path together, please use only one. Exiting..")
    exit(EXIT_FAILURE)
}
    for arguments in CMDLineArgs {
        switch arguments {
        case "-h", "--help":
            SCLIInfo.shared.printHelp()
            exit(0)
        case "-v", "--version":
            print("SuccessorCLI version: \(SCLIInfo.shared.ver)")
            exit(0)
        case "--ipsw-path":
            // CMDLineArgs.indices.contains(index + 1) here is to make sure that a path after --ipsw-path is provided
            guard !fm.fileExists(atPath: iPSWManager.extractedOnboardiPSWPath) else {
                print("ERROR: Extracted iPSW Directory already exists at \(iPSWManager.extractedOnboardiPSWPath), Please delete it first then run SuccessorCLI With --ipsw-path again, exiting..")
                exit(EXIT_FAILURE)
            }
            guard let index = CMDLineArgs.firstIndex(of: "--ipsw-path"), CMDLineArgs.indices.contains(index + 1) else {
                print("Wasn't able to get the iPSW Path specified..are you sure you specified one? Exiting..")
                exit(EXIT_FAILURE)
            }
            let iPSWPath = CMDLineArgs[index + 1]
            guard fm.fileExists(atPath: iPSWPath), NSString(string: iPSWPath).pathExtension == "ipsw" else {
                print("Path \"\(iPSWPath)\" either doesn't exist or is not an iPSW. Exiting..")
                exit(EXIT_FAILURE)
            }
            print("User manually specified iPSW Path as \"\(iPSWPath)\"")
            iPSWManager.onboardiPSWPath = iPSWPath
            iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        case "--dmg-path":
            // CMDLineArgs.indices.contains(index + 1) here is to make sure that a path after --dmg-path is provided
            guard let index = CMDLineArgs.firstIndex(of: "--dmg-path"), CMDLineArgs.indices.contains(index + 1) else {
                print("Wasn't able to get the DMG Path specified..are you sure you specified one? Exiting..")
                exit(EXIT_FAILURE)
            }
            let dmgPath = CMDLineArgs[index + 1]
            guard fm.fileExists(atPath: dmgPath), NSString(string: dmgPath).pathExtension == "dmg" else {
                print("Path to file \"\(dmgPath)\" either doesn't exist or isn't a DMG File. Exiting..")
                exit(EXIT_FAILURE)
            }
            print("User manually specified DMG Path as \"\(dmgPath)\"")
            DMGManager.shared.rfsDMGToUseFullPath = dmgPath
        default:
            break
        }
    }
    if CMDLineArgs.isEmpty {
    print("No arguments used, will do a normal restore..")
}

guard getuid() == 0 else {
    fatalError("SuccessorCLI Must be run as root, example: sudo successorcli. Exiting.")
}

print("Welcome to SuccessorCLI! Build: \(SCLIInfo.shared.ver)")
printIfDebug("Device iOS Version: \(deviceInfo.deviceiOSVersion)")
printIfDebug("Device Machine Name: \(deviceInfo.machineName)")
printIfDebug("Device iOS BuildID: \(deviceInfo.buildID)")

if !fm.fileExists(atPath: SCLIInfo.shared.SuccessorCLIPath) {
    print("\(SCLIInfo.shared.SuccessorCLIPath) does NOT exist! Will try to make it..")
    do {
        try fm.createDirectory(atPath: SCLIInfo.shared.SuccessorCLIPath, withIntermediateDirectories: true, attributes: nil)
        print("Created directory.")
    } catch {
        print("Couldnt create \(SCLIInfo.shared.SuccessorCLIPath), error: \(error.localizedDescription)\nNote: Please create \(SCLIInfo.shared.SuccessorCLIPath) manually and run SuccessorCLI again.")
    }
}

printIfDebug("URL of iPSW to download: \(iPSWManager.onlineiPSWURLStr)")
printIfDebug("Size of iPSW to download in bytes: \(iPSWManager.onlineiPSWSizeUnformatted)")
printIfDebug("Size of iPSW to download, formatted: \(iPSWManager.onlineiPSWSizeformatted)")

switch fm.fileExists(atPath: DMGManager.shared.rfsDMGToUseFullPath) {
    case false where fm.fileExists(atPath: iPSWManager.extractedOnboardiPSWPath):
        print("Found extracted iPSW Path at \(iPSWManager.extractedOnboardiPSWPath), would you like to use it?")
        print("[1] Yes")
        print("[2] No")
        if let choice = readLine() {
            switch choice {
            case "1", "y", "Y":
                print("Proceeding to use \(iPSWManager.extractedOnboardiPSWPath)")
                do {
                    try fm.moveItem(atPath: iPSWManager.extractedOnboardiPSWPath + "/" + fm.getLargestFile(iPSWManager.extractedOnboardiPSWPath), toPath: DMGManager.shared.rfsDMGToUseFullPath)
                } catch {
                    print("Couldn't move \(iPSWManager.extractedOnboardiPSWPath + fm.getLargestFile(iPSWManager.extractedOnboardiPSWPath)) to \(DMGManager.shared.rfsDMGToUseFullPath)\nError: \(error.localizedDescription)\nExiting..")
                    exit(EXIT_FAILURE)
                }
            case "2", "N", "n":
                print("Would you like to remove \(iPSWManager.extractedOnboardiPSWPath) then?")
                print("[1] Yes")
                print("[2] No")
                if let choice = readLine() {
                    switch choice {
                    case "1", "Y", "y":
                        do {
                            try fm.removeItem(atPath: iPSWManager.extractedOnboardiPSWPath)
                            print("Removed \(iPSWManager.extractedOnboardiPSWPath)\nExiting..")
                            exit(0)
                        } catch {
                            print("Couldn't remove path \(iPSWManager.extractedOnboardiPSWPath), error: \(error.localizedDescription)\nExiting..")
                            exit(EXIT_FAILURE)
                        }
                    case "2", "N", "n":
                        print("Figure out what you want to do then run SuccessorCLI again\nExiting..")
                        exit(0)
                    default:
                        break
                    }
                }
            default:
                print("Input \"\(choice)\" Not understood, exiting.")
                exit(EXIT_FAILURE)
            }
        }
        break
    case false where iPSWManager.iPSWSInSCLIPathArray.isEmpty:
        print("It seems that there are no iPSWs in \(SCLIInfo.shared.SuccessorCLIPath), would you like SuccessorCLI to provide one for you?")
        print("[1] Yes")
        print("[2] No")
        if let choice = readLine() {
            switch choice {
                case "1", "y", "Y":
                    iPSWManager.downloadAndExtractiPSW(iPSWURL: iPSWManager.onlineiPSWURL)
            case "2", "n", "N":
                print("Please either provide your own iPSW and place it in \(SCLIInfo.shared.SuccessorCLIPath) or manually specify your own ipsw/rootfsDMG with --ipsw-path/--dmg-path. Exiting..")
                exit(0)
            default:
                print("Input \"\(choice)\" Not understood, exiting.")
                exit(EXIT_FAILURE)
            }
        }
    case false where !iPSWManager.iPSWSInSCLIPathArray.isEmpty:
        print("Found the following iPSWs in \(SCLIInfo.shared.SuccessorCLIPath):")
        for i in 0...(iPSWManager.iPSWSInSCLIPathArray.count - 1) {
            print("[\(i)] \(iPSWManager.iPSWSInSCLIPathArray[i])")
        }
        print("[\(iPSWManager.iPSWSInSCLIPathArray.count)] Make SuccessorCLI Download an iPSW for you automatically")
        if let choice = readLine(), let intChoice = Int(choice) {
            if intChoice == iPSWManager.iPSWSInSCLIPathArray.count {
                iPSWManager.downloadAndExtractiPSW(iPSWURL: iPSWManager.onlineiPSWURL)
            } else {
                iPSWManager.onboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/\(iPSWManager.iPSWSInSCLIPathArray[intChoice])"
                print("Proceeding to use \(iPSWManager.onboardiPSWPath), Will now extract it..")
                iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
            }
        }
        break
        
    case true:
    print("Found rfs.dmg at \(DMGManager.shared.rfsDMGToUseFullPath), Would you like to use it?")
    print("[1] Yes")
    print("[2] No")
    if let choice = readLine() {
        switch choice {
        case "1", "Y", "y":
            print("Proceeding with rootfsDMG at \(DMGManager.shared.rfsDMGToUseFullPath)")
        case "2", "N", "n":
            print("User doesn't want to use rootfsDMG at \(DMGManager.shared.rfsDMGToUseFullPath), please figure out what you want to do then run successorcli again. If you dont want this message to pop up again, move the rootfsDMG file from \(DMGManager.shared.rfsDMGToUseFullPath) to somewhere else. Exiting..")
            exit(0)
        default:
            print("Input \"\(choice)\" not understood, Exiting..")
            exit(EXIT_FAILURE)
        }
    }
    default:
        break
}


var diskNameToMount = ""

if SCLIInfo.shared.isMountPointMounted() {
    print("\(SCLIInfo.shared.mountPoint) Already mounted, skipping right ahead to the restore")
} else {
    DMGManager.attachDMG(dmgPath: DMGManager.shared.rfsDMGToUseFullPath) { bsdName, error in
        guard error == nil else {
            print("Error encountered while attaching DMG \(DMGManager.shared.rfsDMGToUseFullPath): \(error!). Exiting..")
            exit(EXIT_FAILURE)
        }
        guard let bsdName = bsdName else {
            print("Couldn't get name of where DMG was attached to..Exiting.")
            exit(EXIT_FAILURE)
        }
        diskNameToMount = "\(bsdName)s1s1"
        guard fm.fileExists(atPath: "/dev/\(diskNameToMount)") else {
            print("DMG Was not attached successfully. Exiting.")
            exit(EXIT_FAILURE)
        }
    }

    if diskNameToMount.isEmpty {
        print("Couldnt get disk name to mount, exiting..")
        exit(EXIT_FAILURE)
    }
    print("Disk name to mount: \(diskNameToMount)")
    print("Proceeding to (try) to mount..")
    DMGManager.mountNative(devDiskName: "/dev/\(diskNameToMount)", mountPointPath: SCLIInfo.shared.mountPoint)
    
    print("Verifiying if mount was successful..")
    if SCLIInfo.shared.isMountPointMounted() {
        print("Successfully verified \(SCLIInfo.shared.mountPoint) was mounted correctly")
    } else {
        print("Wasn't able to successfuly mount \(SCLIInfo.shared.mountPoint).. Exiting..")
        exit(EXIT_FAILURE)
    }
}

if CMDLineArgs.contains("--no-restore") {
    print("Successfully downloaded and extracted iPSW, then mounted iPSW RootfsDMG. Exiting now caus the user used --no-restore.")
    exit(0)
}

if CMDLineArgs.contains("--no-wait") {
    print("Starting restore now.")
} else {
    print("You have 15 seconds to cancel the restore before it starts, to cancel, simply press ctrl c.")
    sleep(15)
}
print("Proceeding to launch rsync..")
deviceRestoreManager.launchRsync() { exitCode in
    guard exitCode == 0 else {
        print("Wasn't able to use rsync to execute restore..\nExiting..")
        exit(EXIT_FAILURE)
    }
    
        print("Successfully executed restore! now time to reset..")
        deviceRestoreManager.callMobileObliterator()
}
exit(0)
