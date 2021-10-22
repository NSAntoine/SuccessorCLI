import Foundation

let fm = FileManager.default
/// CommandLine.arguements but filters out "succesorcli"
let CMDLineArgs = CommandLine.arguments.filter() { $0 != CommandLine.arguments[0] }

if CMDLineArgs.contains("--ipsw-path") && CMDLineArgs.contains("--dmg-path") {
    print("ERROR: Cannot use --ipsw-path and --dmg-path together, please use only one. Exiting..")
    exit(1)
}
    for arguments in CMDLineArgs {
        switch arguments {
        case "-h", "--help":
            SCLIInfo.shared.printHelp()
            exit(0)
        case "-v", "--version":
            print("SuccessorCLI version: \(SCLIInfo.shared.ver)")
            exit(0)
        case "--unmount", "-u":
            let path = strdup(SCLIInfo.shared.mountPoint)
            guard SCLIInfo.shared.isMountPointMounted() else {
                print("ERROR: Can't unmount \(SCLIInfo.shared.mountPoint) if its not even mounted!\nExiting..")
                exit(1)
            }
            guard unmount(path, 0) == 0 else {
                switch errno {
                case 16:
                    print("ERROR: Coulnd't unmount because the device is resource busy right now, try rebooting, rejailbreaking then running --unmount again")
                case 1:
                    print("ERROR: Couldn't unmount because of an error to do with permissions, are you running SuccessorCLI with sudo?")
                default:
                    print("Error while unmounting, cause: Unknown")
                }
                print("Error code encountered while unmounting: \(errno)")
                print("Exiting..")
                exit(1)
            }
            print("Unmounted \(SCLIInfo.shared.mountPoint)")
            exit(0)
        case "--mnt-status":
            if SCLIInfo.shared.isMountPointMounted() {
                print("\(SCLIInfo.shared.mountPoint) is mounted")
            } else {
                print("\(SCLIInfo.shared.mountPoint) is not mounted.")
            }
            exit(0)
        case "--ipsw-path", "-i":
            guard let index = CMDLineArgs.firstIndex(of: "--ipsw-path") else {
                print("ERROR: User did not specify iPSW Path, Exiting.")
                exit(1)
            }
            let iPSWPath = CMDLineArgs[index + 1]
            print("User manually specified iPSW Path as \(iPSWPath)")
            guard fm.fileExists(atPath: iPSWPath), NSString(string: iPSWPath).pathExtension == "ipsw" else {
                print("Path \"\(iPSWPath)\" either doesn't exist or is not an iPSW. Exiting..")
                exit(1)
            }
            iPSWManager.onboardiPSWPath = iPSWPath
            iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        case "--dmg-path":
            guard let index = CMDLineArgs.firstIndex(of: "--dmg-path") else {
                print("ERROR: User did not specify dmg path, Exiting.")
                exit(1)
            }
            let dmgSpecified = CMDLineArgs[index + 1]
            guard fm.fileExists(atPath: dmgSpecified), NSString(string: dmgSpecified).pathExtension == "dmg" else {
                print("Path \"\(dmgSpecified)\" either doesn't exist or isnt a DMG file. Exiting..")
                exit(1)
            }
            DMGManager.shared.rfsDMGToUseFullPath = dmgSpecified
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
print("Device iOS Version: \(deviceInfo.shared.deviceiOSVersion)")
print("Device Machine Name: \(deviceInfo.shared.machineName)")
print("Device iOS BuildID: \(deviceInfo.shared.deviceiOSBuildID)")

if !fm.fileExists(atPath: SCLIInfo.shared.SuccessorCLIPath) {
    print("\(SCLIInfo.shared.SuccessorCLIPath) does NOT exist! Will try to make it..")
    do {
        try fm.createDirectory(atPath: SCLIInfo.shared.SuccessorCLIPath, withIntermediateDirectories: true, attributes: nil)
        print("Created directory.")
    } catch {
        print("Couldnt create \(SCLIInfo.shared.SuccessorCLIPath), error: \(error.localizedDescription)\nNote: Please create \(SCLIInfo.shared.SuccessorCLIPath) manually and run SuccessorCLI again.")
    }
}

print("URL of iPSW to download: \(iPSWManager.onlineiPSWURLStr)")
print("Size of iPSW to download in bytes: \(iPSWManager.onlineiPSWSizeUnformatted)")
print("Size of iPSW to download, formatted: \(iPSWManager.onlineiPSWSizeformatted)")

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
                    try fm.moveItem(atPath: iPSWManager.extractedOnboardiPSWPath + fm.getLargestFile(iPSWManager.extractedOnboardiPSWPath), toPath: DMGManager.shared.rfsDMGToUseFullPath)
                } catch {
                    print("Couldn't move \(iPSWManager.extractedOnboardiPSWPath + fm.getLargestFile(iPSWManager.extractedOnboardiPSWPath)) to \(DMGManager.shared.rfsDMGToUseFullPath)\nError: \(error.localizedDescription)\nExiting..")
                    exit(1)
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
                            exit(1)
                        }
                    case "2", "N", "n":
                        print("Figure out what you want to do then run SuccessorCLI again\nExiting..")
                        exit(1)
                    default:
                        break
                    }
                }
            default:
                print("Input \"\(choice)\" Not understood, exiting.")
                exit(1)
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
                print("Please provide your own iPSW then place it in \(SCLIInfo.shared.SuccessorCLIPath)\nExiting..")
                exit(0)
            default:
                print("Input \"\(choice)\" Not understood, exiting.")
                exit(1)
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
        print("Found RFS.dmg, proceeding to use it.")
    
    default:
        break
}


if CMDLineArgs.contains("--no-attach") {
    print("User chose to exit before attaching the rfs DMG.")
    exit(0)
}

var diskNameToMount = ""

if SCLIInfo.shared.isMountPointMounted() {
    print("\(SCLIInfo.shared.mountPoint) is already mounted, skipping right ahead to the restore.")
} else {
    DMGManager.attachDMG(dmgPath: DMGManager.shared.rfsDMGToUseFullPath) { exitCode, output in
    guard exitCode == 0,
          let output = output else {
        print("Failed to attach DMG.")
        print("If you need the following details in order to debug:")
        print("Command that was ran: /usr/sbin/hdik -nomount \(DMGManager.shared.rfsDMGToUseFullPath)")
        print("Task exited with Exit Code (Supposed to be 0): \(exitCode)")
        exit(1)
    }
    diskNameToMount = DMGManager.shared.parseDiskName(output)
}

if diskNameToMount.isEmpty {
    print("Couldnt get disk name to mount, exiting..")
    exit(1)
}
print("Disk name to mount: \(diskNameToMount)")
print("Proceeding to (try) to mount..")

DMGManager.mountDisk(devDiskName: diskNameToMount, mountPointPath: SCLIInfo.shared.mountPoint) { exitCode, output in
    guard exitCode == 0, output != nil else {
        print("Wasn't able to mount disk, the following info may be useful to you:")
        print("Command that was run: /sbin/mount -t apfs -o ro \(diskNameToMount) \(SCLIInfo.shared.mountPoint)")
        print("Output: \(output ??  "Unknown")")
        print("Task exited with Exit Code (Supposed to be 0): \(exitCode)")
        exit(1)
    }

    print("Verifying if mount was successful..")
    if SCLIInfo.shared.isMountPointMounted() {
        print("Verified that Mount Point \(SCLIInfo.shared.mountPoint) is mounted, Will continue.")
    } else {
        print("Wasn't able to mount successfully. Exiting..")
        exit(1)
    }
 }
}
if CMDLineArgs.contains("--no-restore") {
    print("Successfully downloaded, archived, attached and mounted iPSW, exiting now.")
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
        exit(1)
    }
    
        print("Successfully executed restore! now time to reset..")
        deviceRestoreManager.callMobileObliterator()
}
exit(0)
