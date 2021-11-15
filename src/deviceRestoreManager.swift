import Foundation
import SuccessorCLIBridged

/// Class which manages rsync and SBDataReset
class deviceRestoreManager {
    
    /// Path for the where rsync executable is located, though this is `/usr/bin/rsync` by defualt, it can manually be changed (see --rsync-bin-path in SuccessorCLI Options)
    static var rsyncBinPath = "/usr/bin/rsync"
    
    /// Calls on to SBDataReset to reset the device like the reset in settings button does.
    /// This is executed after the rsync function is complete
    class func callMobileObliterator() {
        let serverPort = SBSSpringBoardServerPort()
        print("Located SBSSpringBoardServerPort at \(serverPort)")
        print("And now we bring forth mass destruction. Do your job, mobile obliterator!")
        SBDataReset(serverPort, 5)
    }
    
    /// Function which launches rsync.
    class func launchRsync() {
        let pipe = Pipe()
        let task = NSTask()
        task.setLaunchPath(rsyncBinPath)
        var rsyncArgs = ["-vaxcH",
        "--delete",
        "--progress",
        "--ignore-errors",
        "--force",
        "--exclude=/Developer",
        "--exclude=/System/Library/Caches/com.apple.kernelcaches/kernelcache",
        "--exclude=/System/Library/Caches/apticket.der",
        "--exclude=/System/Library/Caches/com.apple.factorydata/",
        "--exclude=/usr/standalone/firmware/sep-firmware.img4",
        "--exclude=/usr/local/standalone/firmware/Baseband",
        "--exclude=/private/\(SCLIInfo.shared.mountPoint)",
        "--exclude=/private/etc/fstab",
        "--exclude=/etc/fstab",
        "--exclude=/usr/standalone/firmware/FUD/",
        "--exclude=/usr/standalone/firmware/Savage/",
        "--exclude=/System/Library/Pearl",
        "--exclude=/usr/standalone/firmware/Yonkers/",
        "--exclude=/private/var/containers/",
        "--exclude=/var/containers/",
        "--exclude=/private/var/keybags/",
        "--exclude=/var/keybags/",
        "--exclude=/applelogo",
        "--exclude=/devicetree",
        "--exclude=/kernelcache",
        "--exclude=/ramdisk",
        "/private/\(SCLIInfo.shared.mountPoint)",
        "/"]
        if fm.fileExists(atPath: "/Library/Caches/xpcproxy") || fm.fileExists(atPath: "/var/tmp/xpcproxy") {
            rsyncArgs.append("--exclude=/Library/Caches/")
            rsyncArgs.append("--exclude=/usr/libexec/xpcproxy")
            rsyncArgs.append("--exclude=/tmp/xpcproxy")
            rsyncArgs.append("--exclude=/var/tmp/xpcproxy")
            rsyncArgs.append("--exclude=/usr/lib/substitute-inserter.dylib")
        }
        task.setArguments(rsyncArgs)
         //These args are the exact same that succession uses  (https://github.com/Samgisaninja/SuccessionRestore/blob/bbfbe5e3e32c034c2d8b314a06f637cb5f2b753d/SuccessionRestore/RestoreViewController.m#L505), i couldnt be bothered to do it manually
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
    }
}
