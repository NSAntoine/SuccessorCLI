import Foundation
import SuccessorCLIBridged

/// Manages stuff such as mount status and mounting function, etc
class MntManager {
    
    /// Directory to where the attached DMG will be mounted to, by default this is /var/mnt/successor/, however this can be changed with `--mnt-point-path`, see help message for more.
    static var mountPoint = "/var/mnt/successor/"
    
    /// Returns the mountPoint but with symlinks resvolved
    static var mountPointRealPath:String {
        guard let realpathCStr = realpath(mountPoint, nil) else {
            // If the realpath can't be obtained, just return the normal path instead
            return mountPoint
        }
        return String(cString: realpathCStr)
    }

    class func mountDisk(devDiskName:String, mountPointPath:String) -> Int32 {
        if let safeCreateMntPointError = fm.safeCreatePath(mountPointPath) {
            fatalError("Error creating Mount Point Path \(mountPointPath): \(safeCreateMntPointError). Please create said directory yourself then run SuccessorCLI again.")
        }
        
        //https://github.com/Odyssey-Team/Taurine/blob/0ee53dde05da8ce5a9b7192e4164ffdae7397f94/Taurine/post-exploit/utils/remount.swift#L169
        let fspec = strdup(devDiskName)
        defer {
            if let fspec = fspec {
                free(fspec)
            }
        }
        
        var mntargs = hfs_mount_args()
        mntargs.fspec = fspec
        mntargs.hfs_mask = 1
        gettimeofday(nil, &mntargs.hfs_timezone)
        
        // If you dont add MNT_WAIT as the flag here, this will fail with the error "Permission Denied"
        return mount("apfs", mountPointPath, MNT_WAIT, &mntargs)
    }
    
    
    //https://github.com/Odyssey-Team/Taurine/blob/0ee53dde05da8ce5a9b7192e4164ffdae7397f94/Taurine/post-exploit/utils/remount.swift#L63
    /// Returns true or false based on whether or not MntManager.mountPoint is mounted
    class func isMountPointMounted(mntPointPath:String = mountPoint) -> Bool {
        let path = strdup(mntPointPath)
        defer {
            if let path = path {
                free(path)
            }
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
    
    class func attachAndMntDMG(DMGPath:String = DMGManager.rfsDMGToUseFullPath,
                               mntPointPath mntPoint:String = MntManager.mountPoint) {
        var diskName = ""
        DMGManager.attachDMG(dmgPath: DMGPath) { bsdName, err in
            guard let bsdName = bsdName, err == nil else {
                fatalError("Error encountered while attaching DMG \"\(DMGPath)\": \(err ?? "Unknown Error")..Cannot proceed.")
            }
            diskName = "/dev/\(bsdName)s1s1"
        }
        guard fm.fileExists(atPath: diskName) else {
            fatalError("DMG \"\(DMGPath)\" was attached improperly..Cannot proceed.")
        }
        let diskNameMntStatus = mountDisk(devDiskName: diskName, mountPointPath: mntPoint)
        guard diskNameMntStatus == 0 else {
            fatalError("Error encountered while mounting \(diskName) to \(mntPoint): \(String(cString: strerror(errno)))..Cannot proceed.")
        }
        print("Mounted \(diskName) to \(mntPoint) Successfully.")
    }
}
