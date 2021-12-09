import Foundation
import SuccessorCLIBridged

/// Class which manages rsync and SBDataReset
class deviceRestoreManager {
    
    /// Path for the where rsync executable is located, though this is `/usr/bin/rsync` by defualt, it can manually be changed (see --rsync-bin-path in SuccessorCLI Options)
    static var rsyncBinPath = "/usr/bin/rsync"
    
    /// Returns true or false based on whether or not the user used the `--dry-run` option
    static let doDryRun = CMDLineArgs.contains("--dry-run")
    
    /// Needs to be true to launch the rsync restore, returns true or false based on whether or not the user used `--restore/-r`
    static let shouldDoRestore = CMDLineArgs.contains("--restore") || CMDLineArgs.contains("-r")
    
    /// If this is true, the rsync restore will not be executed and instead exit before starting it.
    static let shouldntDoRestore = CMDLineArgs.contains("--no-restore") || CMDLineArgs.contains("-n")
    
    /// SpringBoardServerPort needed when calling SBDataReset
    @_silgen_name("SBSSpringBoardServerPort") private static func SBServerPort() -> mach_port_t
    
    /// SBDataReset function which resets the device.
    @_silgen_name("SBDataReset") private static func SBDataReset(_ :mach_port_t, _ :Int32) -> Int32
    
    /// Contains directories which will be excluded if certain xpcproxy directories exists on the device
    static let XPCProxyExcludeArgs = ["--exclude=/Library/Caches/",
                                      "--exclude=/usr/libexec/xpcproxy",
                                      "--exclude=/tmp/xpcproxy",
                                      "--exclude=/var/tmp/xpcproxy",
                                      "--exclude=/usr/lib/substitute-inserter.dylib"]
    
    /// Arguments that will be passed in to rsync, note that the user can add more arguments by using `--append-rsync-arg`, see SuccessorCLI --help or the README for more info.
    static var rsyncArgs = { () -> [String] in
        var args = ["-vaxcH",
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
                    "--exclude=\(MntManager.mountPointRealPath)",
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
                    MntManager.mountPointRealPath,
                    "/"]
        
        // If the user used --dry-run, append --dry-run to the args to return
        if doDryRun {
            args.append("--dry-run")
        }
        // If the 2 xpcproxy directories exist, add the xpcproxy exclude args to the args to return
        if fm.fileExists(atPath: "/Library/Caches/xpcproxy") || fm.fileExists(atPath: "/var/tmp/xpcproxy") {
            args += XPCProxyExcludeArgs
        }
        return args
    }()
    
    /// Function which launches rsync.
    class func launchRsync() {
        guard shouldDoRestore && !shouldntDoRestore else {
            print("Not launching the rsync restore because the user did not use --restore/-r.")
            print("If you want the restore to be executed, run SuccessorCLI with --restore/-r.")
            print("Exiting.")
            exit(0)
        }
        let pipe = Pipe()
        let task = NSTask()
        
        // We need to make sure the rsyncBinPath exists before we start the restore, otherwise give the user an error and exit
        guard fm.fileExists(atPath: rsyncBinPath) else {
            fatalError("Rsync Binary Path is \(rsyncBinPath) However that path doesn't exist! Please (re)install your rsync and run SuccessorCLI Again!")
        }
        
        task.setLaunchPath(rsyncBinPath)
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
            
            // If the user cancelled mid restore, trigger the statement below
            signal(SIGINT) { _ in
                fatalError("You done fucked up. Go restore rootfs NOW.")
            }
        }
        task.launch()
        task.waitUntilExit()
    }
    
    /// Calls on to `SBDataReset` to reset the device, if the user uses `dry run` then this will just exit before it calls onto `SBDataReset`
    class func callSBDataReset() {
        guard !doDryRun else {
            print("User specified to do a dry run. Not calling mobile obliterator.")
            exit(0)
        }
        print("Located SBSSpringBoardServerPort at \(SBServerPort())")
        print("Now launching SBDataReset.")
        SBDataReset(SBServerPort(), 5)
    }
    
    /// Function which launches Rsync then calls onto SBDataReset.
    class func execRsyncThenCallDataReset() {
        print("Proceeding to launch rsync..")
        deviceRestoreManager.launchRsync()
        print("Rsync done, now time to reset device.")
        deviceRestoreManager.callSBDataReset()
        exit(0)
    }
    
    // By default, it will select the DMG in DMGManager.rfsDMGToUseFullPath as the dmg to attach/mount and MntManager.mountPoint as the default mount
    /// Attaches and mounts specified DMG, then executes restore
    class func attachMntAndExecRestore(DMGPath:String = DMGManager.rfsDMGToUseFullPath,
                                       mntPointPath mntPoint:String = MntManager.mountPoint) {
        if !MntManager.isMountPointMounted() {
            MntManager.attachAndMntDMG(DMGPath: DMGPath, mntPointPath: mntPoint)
        }
        execRsyncThenCallDataReset()
    }
}
