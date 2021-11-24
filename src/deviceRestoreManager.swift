import Foundation
import SuccessorCLIBridged

/// Class which manages rsync and SBDataReset
class deviceRestoreManager {
    
    /// Path for the where rsync executable is located, though this is `/usr/bin/rsync` by defualt, it can manually be changed (see --rsync-bin-path in SuccessorCLI Options)
    static var rsyncBinPath = "/usr/bin/rsync"
    
    /// Returns true or false based on whether or not the user used the `--rsync-dry-run` option
    static let doDryRun = CMDLineArgs.contains("--rsync-dry-run")
    
    /// Needs to be used to launch the rsync restore.
    static let shouldDoRestore = CMDLineArgs.contains("--restore") || CMDLineArgs.contains("-r")
    
    /// Arguments that will be passed in to rsync, note that the user can add more arguments by using `--append-rsync-arg`, see SuccessorCLI --help or the README for more info.
    static var rsyncArgs = ["-vaxcH",
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
                            "--exclude=/private\(SCLIInfo.shared.mountPoint)",
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
                            "/private\(SCLIInfo.shared.mountPoint)",
                            "/"]
    
    /// Contains directories which will be excluded if certain xpcproxy directories exists on the device
    static let XPCProxyExcludeArgs = ["--exclude=/Library/Caches/",
                                      "--exclude=/usr/libexec/xpcproxy",
                                      "--exclude=/tmp/xpcproxy",
                                      "--exclude=/var/tmp/xpcproxy",
                                      "--exclude=/usr/lib/substitute-inserter.dylib"]
    
    /// Function which launches rsync.
    class func launchRsync() {
        let pipe = Pipe()
        let task = NSTask()
        task.setLaunchPath(rsyncBinPath)
        if fm.fileExists(atPath: "/Library/Caches/xpcproxy") || fm.fileExists(atPath: "/var/tmp/xpcproxy") {
            rsyncArgs += XPCProxyExcludeArgs
        }
        if doDryRun {
            rsyncArgs.append("--dry-run")
        }
        task.setArguments(rsyncArgs)
        task.setStandardOutput(pipe)
        task.setStandardError(pipe)
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
             guard let line = String(data: pipe.availableData, encoding: .utf8) else {
                 print("Error decoding data: \(pipe.availableData)")
                 return
             }
             print(line)
            signal(SIGINT) { _ in
                fatalError("You done fucked up. Go restore rootfs NOW.")
            }
         }
        task.launch()
        task.waitUntilExit()
    }
    
    /// Calls on to SBDataReset to reset the device.
    /// This is executed after the rsync function is complete
    class func callSBDataReset() {
        guard !doDryRun else {
            print("User specified to do a dry run. Not calling mobile obliterator.")
            exit(0)
        }
        let serverPort = SBSSpringBoardServerPort()
        print("Located SBSSpringBoardServerPort at \(serverPort)")
        print("Now launching SBDataReset.")
        SBDataReset(serverPort, 5)
    }
    
    /// Function which launches Rsync then calls onto SBDataReset.
    class func execRsyncThenCallDataReset() {
        guard shouldDoRestore else {
            print("Not launching restore because the user did not use --restore / -r.")
            print("If you want SuccessorCLI to do the restore, please run SuccessorCLI again with --restore / -r.")
            print("Exiting.")
            exit(0)
        }
        print("Proceeding to launch rsync..")
        deviceRestoreManager.launchRsync()
        print("Rsync done, now time to reset device.")
        deviceRestoreManager.callSBDataReset()
        exit(0)
    }
    
    // By default, it will select the DMG in DMGManager.shared.rfsDMGToUseFullPath as the dmg to attach/mount and SCLIInfo.shared.mountPoint as the default mount point
    class func attachMntAndExecRestore(DMGPath:String = DMGManager.shared.rfsDMGToUseFullPath, mntPointPath mntPoint:String = SCLIInfo.shared.mountPoint) {
        if !MntManager.shared.isMountPointMounted() {
        MntManager.attachAndMntDMG(DMGPath: DMGPath, mntPointPath: mntPoint)
        }
        execRsyncThenCallDataReset()
    }
}
