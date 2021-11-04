import Foundation

/// Manages stuff such as mount status and mounting function, etc
class MntManager {
    static let shared = MntManager()
    
    class func mountNative(devDiskName:String, mountPointPath:String, completionHandler: (_ mntStatus: Int32) -> Void ) {
        if !fm.fileExists(atPath: mountPointPath) {
            print("Mount Point \(mountPointPath) doesn't exist.. will try to make it..")
            do {
                try fm.createDirectory(atPath: mountPointPath, withIntermediateDirectories: true, attributes: nil)
                print("Successfully create \(mountPointPath), Continuing..")
            } catch {
                errPrint("Error encountered while creating directory \(mountPointPath): \(error.localizedDescription)\nPlease create the \(mountPointPath) directory again and run SuccessorCLI Again\nExiting..", line: #line, file: #file)
                exit(EXIT_FAILURE)
            }
        }
    //https://github.com/Odyssey-Team/Taurine/blob/0ee53dde05da8ce5a9b7192e4164ffdae7397f94/Taurine/post-exploit/utils/remount.swift#L169
        let fspec = strdup(devDiskName)

        var mntargs = hfs_mount_args()
        mntargs.fspec = fspec
        mntargs.hfs_mask = 1
        gettimeofday(nil, &mntargs.hfs_timezone)
        
        // For the longest time, I had tried to mount natively instead of using NSTask with the mount_apfs command, however doing it natively literally never worked, becuase the way I did it was the same as the line below however instead of MNT_WAIT there was a 0, so for weeks I kept constantly trying to get it to work until one day i was trying all the MNT_ args, and suddenly MNT_WAIT worked. Otherwise I would somehow get a "Permission Denied" error
        let mnt = mount("apfs", mountPointPath, MNT_WAIT, &mntargs)
        completionHandler(mnt)
    }
    
    
    //https://github.com/Odyssey-Team/Taurine/blob/0ee53dde05da8ce5a9b7192e4164ffdae7397f94/Taurine/post-exploit/utils/remount.swift#L63
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
