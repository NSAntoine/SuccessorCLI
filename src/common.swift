// Includes stuff such as device, successorcli, and info of online iPSW

import UIKit

/// Includes info such as the device iOS version, machine name, and the build ID
class deviceInfo {
    static let shared = deviceInfo()
    static let deviceiOSVersion = UIDevice.current.systemVersion
    static func sysctl(name: String) -> String {
            var size = 0
            sysctlbyname(name, nil, &size, nil, 0)
            var value = [CChar](repeating: 0,  count: size)
            sysctlbyname(name, &value, &size, nil, 0)
            return String(cString: value)
        }
    static let machineName = sysctl(name: "hw.machine")
    static let buildID = sysctl(name: "kern.osversion")

}

/// Provides information about SuccessorCLI App, such as its path in ~/ and the mount point.
class SCLIInfo { // SCLI = SuccessorCLI
    static let shared = SCLIInfo()
    var SuccessorCLIPath = "/var/mobile/Media/SuccessorCLI"

    var mountPoint = "/var/mnt/successor/"
    
    var ver = "1.0.1 PROBABLY-WORKING-BETA"
    
    /// Prints help message
    func printHelp() {
        print("""
            SuccessorCLI - A CLI Utility to restore iOS devices, based off Succession
            Usage: successorcli <option>
                 -h, --help        Prints this help message
                 -v, --version     Prints current SuccessorCLI Version
                 -u, --unmount     If /var/mnt/successor is mounted, then this will unmount it.
                 --ipsw-path       /PATH/TO/IPSW           Manually specify path of iPSW to use.
                 --dmg-path        /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use.
                 --no-restore      Download and extract iPSW, rename the rootfilesystem DMG to rfs.dmg, then attach and mount rfs.dmg, but won't execute the restore itself.
                 --no-attach        Download and extract iPSW, rename the rootfilesystem DMG to rfs.dmg, then exit.
                 --no-wait          Removes the 15 seconds given for the user to cancel the restore before it starts
                 --mnt-status       Prints whether or not /var/mnt/successor is mounted
            """)
    }
    
    // Copied from https://github.com/Odyssey-Team/Taurine/blob/0ee53dde05da8ce5a9b7192e4164ffdae7397f94/Taurine/post-exploit/utils/remount.swift#L63
    /// Returns true or false based on whether or not SCLIInfo.shared.mountPoint is mounted
    func isMountPointMounted() -> Bool {
        let path = strdup(SCLIInfo.shared.mountPoint)
                defer {
                    free(path!)
                }
                
                var buffer = stat()
                if lstat(path, &buffer) != 0 {
                    return false
                }
                
                let S_IFMT = 0o170000
                let S_IFDIR = 0o040000
                
                guard Int(buffer.st_mode) & S_IFMT == S_IFDIR else {
                    return false
                }
                
                let cwd = getcwd(nil, 0)
                chdir(path)
                
                var p_buf = stat()
                lstat("..", &p_buf)
                
                if let cwd = cwd {
                    chdir(cwd)
                    free(cwd)
                }
                
                return buffer.st_dev != p_buf.st_dev || buffer.st_ino == p_buf.st_ino
    }
}

func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = .useAll
    formatter.countStyle = .file
    formatter.includesUnit = true
    formatter.isAdaptive = true
    
    return formatter.string(fromByteCount: bytes)
}

extension FileManager {
    func getLargestFile(_ directoryPath: String) -> String {
    var fileDict = [String: Int64]()
    let enumerator = fm.enumerator(atPath: directoryPath)
    while let file = enumerator?.nextObject() as? String {
        let attributes = try? fm.attributesOfItem(atPath: directoryPath + "/" + file)
        fileDict[file] = attributes?[FileAttributeKey.size] as? Int64
    }
    let sortedFiles = fileDict.sorted(by: { $0.value > $1.value })
    let biggestFile = sortedFiles.first?.key ?? "Unknown"
    print("Biggest file: \(biggestFile)")
    return biggestFile
    }
}


/// Class which manages iPSW stuff, like getting the online URL and size of the iPSW, declaring the paths at which the iPSW should be downloaded to, etc
class iPSWManager {
    static let shared = iPSWManager()

    static var onlineiPSWSizeUnformatted:Int {
        var ret = 0
        NetworkUtilities.shared.returnInfoOfOnlineIPSW(url: "https://api.ipsw.me/v4/ipsw/\(deviceInfo.machineName)/\(deviceInfo.buildID)") { jsonResponse in
            ret = jsonResponse["filesize"] as! Int
        }
        return ret
    }
    static var onlineiPSWSizeformatted:String {
        return formatBytes(Int64(onlineiPSWSizeUnformatted))
    }
    static var onlineiPSWURLStr:String {
        var ret = ""
        NetworkUtilities.shared.returnInfoOfOnlineIPSW(url: "https://api.ipsw.me/v4/ipsw/\(deviceInfo.machineName)/\(deviceInfo.buildID)") { jsonResponse in
            ret = jsonResponse["url"] as! String
        }
        return ret
    }
    
    ///
    static let onlineiPSWURL = URL(string: iPSWManager.onlineiPSWURLStr)!
    /// Returns the iPSWs that are in SCLIInfo.shared.SuccessorCLIPath, this is used mainly for iPSW detection
    static var iPSWSInSCLIPathArray:[String] {
        var ret = [String]()
        if let enumerator = fm.enumerator(atPath: SCLIInfo.shared.SuccessorCLIPath) {
            while let element = enumerator.nextObject() as? String {
                if element.hasSuffix("ipsw") {
                    ret.append(element)
                }
        }
    }
        return ret
}
    /// Path for which iPSW is downloaded to/located, by defualt its /var/Media/SuccessorCLI/ipsw.ipsw
    static var onboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/ipsw.ipsw"
    static var extractedOnboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/extracted"

    /// Function which unzips iPSW to where its specified.
    func unzipiPSW(iPSWFilePath: String, destinationPath: String) {
        let unzipTask = NSTask() /* Yes i know.. calling CLI just to unzip files is bad practice..but its better than waiting like 20 minutes with libzip.. */
        unzipTask.setLaunchPath("/usr/bin/unzip")
        unzipTask.setArguments([iPSWFilePath, "-d", destinationPath])
        unzipTask.launch()
        unzipTask.waitUntilExit()
        
        guard unzipTask.terminationStatus == 0 else {
            print("Error: Couldn't successfully unzip the iPSW...exiting..")
            exit(1)
        }
        
        do {
            try fm.moveItem(atPath: "\(destinationPath)/\(DMGManager.shared.locateRFSDMG)", toPath: DMGManager.shared.rfsDMGToUseFullPath) /* Moves and renames the rootfs dmg */
        } catch {
            print("Couldnt rename and move iPSW...error: \(error.localizedDescription)\nExiting..")
            exit(1)
        }
        
         /* if CMDLineArgs.contains("--dont-move-to-tmp") {
            print("User specified that the iPSW Should not be moved to \(NSTemporaryDirectory()) After extraction")
        } else {
        // Moves the now unneeded ipsw to /var/tmp
        do {
            try fm.moveItem(atPath: iPSWFilePath, toPath: "\(NSTemporaryDirectory())/ipsw.ipsw")
            print("Successfully moved old, unneeded ipsw to /var/tmp")
        } catch {
            print("Couldn't move \(iPSWFilePath) to \(NSTemporaryDirectory())/ipsw.ipsw\nError: \(error.localizedDescription), still continiuing")
        }
    } */
}
    
    class func downloadAndExtractiPSW(iPSWURL: URL) {
        print("Will now download iPSW..")
        NetworkUtilities.shared.downloadItem(url: iPSWURL, destinationURL: URL(fileURLWithPath: iPSWManager.onboardiPSWPath))
        print("Downloaded iPSW, now time to extract it..")
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        print("Decompressed iPSW.")
    }
}

/// Manages the several operations for DMG, such attaching and mounting
class DMGManager {
    static let shared = DMGManager()

    var locateRFSDMG:String {
        return fm.getLargestFile(iPSWManager.extractedOnboardiPSWPath)
    }
    var rfsDMGToUseName = "rfs.dmg" // By default this is rfs.dmg but can later on be changed if renaming fails.
    var rfsDMGToUseFullPath = SCLIInfo.shared.SuccessorCLIPath + "/rfs.dmg"
    class func attachDMG(dmgPath: String, completionHandler: (_ exitCode: Int32, _ output: String?) -> Void) {
        let pipe = Pipe()
        let task = NSTask()
        task.setLaunchPath("/usr/sbin/hdik")
        task.setArguments(["-nomount",  dmgPath])
        task.setStandardOutput(pipe)
        task.setStandardError(pipe)
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
//        print(output)
        completionHandler(task.terminationStatus, output ?? nil)
    }
    
    /// Parses the name of the disk to mount.
    let parseDiskName = { (_ input:String) -> String in
        var components = input.components(separatedBy: .newlines)
        var diskToMountName = ""
         for number in 0...60 { // Honestly, i didnt know what number to put here, so i just put 60.
            for objects in components {
                if objects.contains("/dev/disk\(number)s1s1") {
                    guard let firstObject = objects.components(separatedBy: " ").first else {
                        fatalError("Couldnt get disk to mount. exiting.")
                    }
                    diskToMountName = firstObject
                }
            }
        }
        return diskToMountName
    }
    
    class func attachDMGNative(dmgPath:String, completionHandler: (String?, AnyObject?) -> Void ) {
        let url = URL(fileURLWithPath: dmgPath)
        var attachParamsErr:AnyObject?
        var attachErr:NSError?
        var handler: DIDeviceHandle?
        var attachParams = DIAttachParams(url: url, error: &attachParamsErr)
        guard attachParamsErr == nil else {
            return completionHandler(nil, attachParamsErr)
        }
        attachParams?.autoMount = false
        DiskImages2.attach(with: attachParams, handle: &handler, error: &attachErr)
        guard attachErr == nil else {
            return completionHandler(nil, attachErr)
        }
        completionHandler(handler?.bsdName(), nil)
    }
    class func mountDisk(devDiskName: String, mountPointPath: String, completionHandler: (_ exitCode: Int32, _ output:String?) -> Void ) {
        if !fm.fileExists(atPath: mountPointPath) {
            print("Mount point at \(mountPointPath) does not exist, will try to make it..")
            do {
                try fm.createDirectory(atPath: mountPointPath, withIntermediateDirectories: true, attributes: nil)
                print("Successfully created Mount Point \(mountPointPath), will continue.")
            } catch {
                print("Couldn't create Mount Point \(mountPointPath)\nError: \(error.localizedDescription)\nPlease create the folder yourself and run SuccessorCLI again.")
                exit(1)
            }
        }
        let pipe = Pipe()
        let mountTask = NSTask()
        mountTask.setLaunchPath("/sbin/mount")
        mountTask.setArguments(["-t", "apfs", "-o", "ro", devDiskName, mountPointPath])
        mountTask.setStandardOutput(pipe)
        mountTask.setStandardError(pipe)
        mountTask.launch()
        mountTask.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        completionHandler(mountTask.terminationStatus, output ?? nil)
    }
}

/// Class which manages rsync and SBDataReset
class deviceRestoreManager {
    
     /// Calls on to SBDataReset to reset the device like the reset in settings button does.
    /// This is executed after the rsync function is complete
    class func callMobileObliterator() {
        let serverPort = SBSSpringBoardServerPort()
        print("Located SBSSpringBoardServerPort at \(serverPort)")
        print("And now we bring forth mass destruction. Do your job, mobile obliterator!")
        SBDataReset(serverPort, 5)
    }
    
     /// Function which launches rsync.
    class func launchRsync(completionHandler: @escaping (Int32) -> Void) {
        let pipe = Pipe()
        let task = NSTask()
        task.setLaunchPath("/usr/bin/rsync")
        task.setArguments(["-vaxcH",
        "--delete",
        "--progress",
        "--force",
        "--exclude=/Developer",
        "--exclude=/System/Library/Caches/com.apple.kernelcaches/kernelcache",
        "--exclude=/System/Library/Caches/apticket.der",
        "--exclude=/System/Library/Caches/com.apple.factorydata/",
        "--exclude=/usr/standalone/firmware/sep-firmware.img4",
        "--exclude=/usr/local/standalone/firmware/Baseband",
        "--exclude=/private/var/mnt/successor/",
        "--exclude=/usr/standalone/firmware/FUD/",
        "--exclude=/usr/standalone/firmware/Savage/",
        "--exclude=/System/Library/Pearl",
        "--exclude=/usr/standalone/firmware/Yonkers/",
        "--exclude=/private/etc/fstab",
        "--exclude=/private/var/containers/",
        "--exclude=/var/containers/",
        "--exclude=/private/var/keybags/",
        "--exclude=/var/keybags/",
        "--exclude=/applelogo",
        "--exclude=/devicetree",
        "--exclude=/kernelcache",
        "--exclude=/ramdisk",
        "/var/mnt/successor/",
        "/"
        ])
        //These args are the exact same that succession uses (https://github.com/Samgisaninja/SuccessionRestore/blob/bbfbe5e3e32c034c2d8b314a06f637cb5f2b753d/SuccessionRestore/RestoreViewController.m#L505), i couldnt be bothered to do it manually
        task.setStandardOutput(pipe)
        task.setStandardError(pipe)
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            guard let line = String(data: pipe.availableData, encoding: .utf8) else {
                print("Error decoding data: \(pipe.availableData)")
                return
            }
            print(line)
        }
        task.launch()
        task.waitUntilExit()
        completionHandler(task.terminationStatus)
    }
}

