import Foundation

let fm = FileManager.default

// Now lets make sure the SuccessorCLI Path is created if it doesnt already exist
if let safeCreateSCLIPathError = fm.safeCreatePath(SCLIInfo.SuccessorCLIPath) {
    fatalError("Couldn't create path \(SCLIInfo.SuccessorCLIPath), Error: \(safeCreateSCLIPathError). Please create said path yourself and run SuccessorCLI again.")
}

// Due to the first argument from CommandLine.arguments being the program name, we need to drop that.
let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

// MARK: Command Line Argument support
for arg in CMDLineArgs {
    switch arg {
    case "--help", "-h":
        print(SCLIInfo.helpMessage)
        exit(0)
        
        // Support for manually specifying iPSW:
        // This will unzip the iPSW, get RootfsDMG from it, attach and mount that, then execute restore.
    case "--ipsw-path":
        let iPSWSpecified = parseCMDLineArgument(longOpt: "--ipsw-path", description: "iPSW")
        guard fm.fileExists(atPath: iPSWSpecified) && NSString(string: iPSWSpecified).pathExtension == "ipsw" else {
            fatalError("ERROR: file \"\(iPSWSpecified)\" Either doesn't exist or isn't an iPSW")
        }
        iPSWManager.onboardiPSWPath = iPSWSpecified
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWSpecified, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        
        // Support for manually specifying rootfsDMG:
    case "--dmg-path":
        let dmgSpecified = parseCMDLineArgument(longOpt: "--dmg-path", description: "DMG")
        guard fm.fileExists(atPath: dmgSpecified) && NSString(string: dmgSpecified).pathExtension == "dmg" else {
            fatalError("File \"\(dmgSpecified)\" Either doesnt exist or isnt a DMG file.")
        }
        DMGManager.rfsDMGToUseFullPath = dmgSpecified
        
        // Support for manually specifying rsync binary:
    case "--rsync-bin-path":
        let rsyncBinSpecified = parseCMDLineArgument(longOpt: "--rsync-bin-path", description: "Rsync Executable")
        guard fm.fileExists(atPath: rsyncBinSpecified), fm.isExecutableFile(atPath: rsyncBinSpecified) else {
            fatalError("File \"\(rsyncBinSpecified)\" Can't be used because it either doesn't exist or is not an executable file.")
        }
        deviceRestoreManager.rsyncBinPath = rsyncBinSpecified
        
        // Support for manually specifying Mount Point:
    case "--mnt-point-path":
        let mntPointSpecified = parseCMDLineArgument(longOpt: "--mnt-point-path", shortOpt: nil, description: "Mount Point")
        guard fm.fileExists(atPath: mntPointSpecified) else {
            fatalError("Can't set \(mntPointSpecified) to Mount Point if it doesn't even exist!")
        }
        MntManager.mountPoint = mntPointSpecified
    case "--rootfs-path":
        let rootfsPathSpecified = parseCMDLineArgument(longOpt: "--rootfs-path", description: "Rootfs Path")
        guard fm.fileExists(atPath: rootfsPathSpecified) else {
            fatalError("Can't set \(rootfsPathSpecified) to Rootfs Path if it doesn't exist")
        }
        deviceRestoreManager.rootfsPath = rootfsPathSpecified
    default:
        break
    }
}

// If the user used --append-rsync-arg=/-a=, remove --append-rsync-arg=/-a and parse the specified arg directly
/// Check if the user used --append-rsync-arg and append the values specified to the rsyncArgs array, see SuccessorCLI --help for more info.
let rsyncArgsSpecified = CMDLineArgs.filter() { $0.hasPrefix("--append-rsync-arg=") }.map() { $0.replacingOccurrences(of: "--append-rsync-arg=", with: "") }
deviceRestoreManager.rsyncArgs += rsyncArgsSpecified
if !rsyncArgsSpecified.isEmpty {
    print("User specified to add these args to rsync: \(rsyncArgsSpecified.joined(separator: ", "))")
}

// detecting for root
// root is needed to execute rsync with enough permissions to replace all files necessary
guard getuid() == 0 else {
    fatalError("ERROR: SuccessorCLI Must be run as root, eg `sudo \(SCLIInfo.ProgramName) \(CMDLineArgs.joined(separator: " "))`")
}

print("Welcome to SuccessorCLI! Version \(SCLIInfo.ProgramVer).")

// If the mount point is already mounted, ask the user if they want to execute the restore from it
if MntManager.isMountPointMounted() {
    print("Mount Point at \(MntManager.mountPoint) already mounted, would you like to execute restore from the contents inside it?")
    print("[1] Yes")
    print("[2] No, unmount it and continue")
    print("[3] No and exit")
    // make sure input is int and within range
    guard let input = readLine(), let inputInt = Int(input), (1...3) ~= inputInt else {
        fatalError("Input must be a number and be from 1 to 3. Exiting.")
    }
    switch inputInt {
    case 1:
        deviceRestoreManager.execRsyncThenCallDataReset()
    case 2:
        let unmtStatus = unmount(MntManager.mountPoint, 0)
        guard unmtStatus == 0 else {
            let error = String(cString: strerror(errno))
            fatalError("Error encountered while unmounting \"\(MntManager.mountPoint)\": \(error)")
        }
        print("Unmounted \(MntManager.mountPoint)")
    default:
        exit(0)
    }
}

// MARK: RootfsDMG and iPSW Detection
if fm.fileExists(atPath: DMGManager.rfsDMGToUseFullPath) {
    print("Rfs DMG at \(DMGManager.rfsDMGToUseFullPath) already exists, would you like to use it?")
    print("[1] Yes")
    print("[2] No")
    guard let input = readLine(), let inputInt = Int(input) else {
        fatalError("Input must be a Int.")
    }
    if inputInt == 1 {
        deviceRestoreManager.attachMntAndExecRestore()
    }
}

print("Choose what to do below.")

// If there are DMGs in the SuccessorCLI directory, ask the user if they want to use them
if !DMGManager.DMGSinSCLIPathArray.isEmpty {
    print("Found DMGs in \(SCLIInfo.SuccessorCLIPath), Which would you like to use?")
    for i in 0...(DMGManager.DMGSinSCLIPathArray.count - 1) {
        print("[\(i)] Use DMG \(DMGManager.DMGSinSCLIPathArray[i])")
    }
    print("[\(DMGManager.DMGSinSCLIPathArray.count)] None - Use/Download an iPSW")
    // The input should be an integer and less than / equal to the count of DMGManager.DMGSinSCLIPathArray
    guard let input = readLine(), let inputInt = Int(input), inputInt <= DMGManager.DMGSinSCLIPathArray.count else {
        fatalError("Input must be a number and must be equal to or less than \(DMGManager.DMGSinSCLIPathArray.count)")
    }
    if inputInt != DMGManager.DMGSinSCLIPathArray.count {
        let DMGSpecified = DMGManager.DMGSinSCLIPathArray[inputInt]
        DMGManager.rfsDMGToUseFullPath = "\(SCLIInfo.SuccessorCLIPath)/\(DMGSpecified)"
        deviceRestoreManager.attachMntAndExecRestore()
    }
}

// If there are no DMGs in the SuccessorCLI directory or if the user declined to use a DMG, it'll search for iPSWs in the SuccessorCLI directory, if there are any, itll ask the user if they want to use them
if !iPSWManager.iPSWSInSCLIPathArray.isEmpty {
    print("Found following iPSWs in \(SCLIInfo.SuccessorCLIPath).")
    for i in 0...(iPSWManager.iPSWSInSCLIPathArray.count - 1) {
        print("[\(i)] Extract and use iPSW \(iPSWManager.iPSWSInSCLIPathArray[i])")
    }
}
// The choice to download an iPSW will also always be present
print("[\(iPSWManager.iPSWSInSCLIPathArray.count)] Download an iPSW")
guard let input = readLine(), let inputInt = Int(input), inputInt <= iPSWManager.iPSWSInSCLIPathArray.count else {
    fatalError("Input must be a number and must be equal to or less than \(iPSWManager.iPSWSInSCLIPathArray.count)")
}
if inputInt == iPSWManager.iPSWSInSCLIPathArray.count {
    iPSWManager.downloadAndExtractiPSW()
} else {
    let iPSWSpecified = iPSWManager.iPSWSInSCLIPathArray[inputInt]
    iPSWManager.onboardiPSWPath = "\(SCLIInfo.SuccessorCLIPath)/\(iPSWSpecified)"
    iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
}

deviceRestoreManager.attachMntAndExecRestore()
