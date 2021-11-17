// Includes general information about device, the SuccessorCLI program, and general functions.

import UIKit
import Foundation

/// Includes info such as the device iOS version, machine name, and the build ID
struct deviceInfo {
    static func sysctl(name: String) -> String {
            var size = 0
            sysctlbyname(name, nil, &size, nil, 0)
            var value = [CChar](repeating: 0,  count: size)
            sysctlbyname(name, &value, &size, nil, 0)
            return String(cString: value)
        }
    static let machineName = sysctl(name: "hw.machine")
    static let buildID = sysctl(name: "kern.osversion")
    static let deviceiOSVersion = UIDevice.current.systemVersion
}

/// Provides information about SuccessorCLI App, such as its path in /var/mobile/Library and the mount point.
class SCLIInfo { // SCLI = SuccessorCLI
    static let shared = SCLIInfo()
    var SuccessorCLIPath = "/var/mobile/Library/SuccessorCLI"

    var mountPoint = "/var/mnt/successor/"
    
    var ver = "2.0.0 PROBABLY-WORKING-BETA"
    
    /// Prints help message
    func printHelp() {
        print("""
            SuccessorCLI - A CLI Utility to restore iOS devices, based off the original Succession by samg_is_a_ninja, created by Dabezt31.
            Report issues to https://github.com/dabezt31/SuccessorCLI/issues
            Version \(SCLIInfo.shared.ver)
            Usage: successorcli <option>
                 -h, --help         Prints this help message.
                 -d, --debug        Prints extra information which may be useful.
            
                 --no-restore       Download and extract iPSW, rename the rootfilesystem DMG to rfs.dmg, then attach and mount rfs.dmg, but won't execute the restore itself.
                 --no-wait          Removes the 15 seconds given for the user to cancel the restore before it starts.
            
                 --mnt-point-path   /PATH/TO/MOUNT          Manually specify path to mount the attached RootfsDMG to.
                 --ipsw-path        /PATH/TO/IPSW           Manually specify path of iPSW to use.
                 --dmg-path         /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use.
                 --rsync-bin-path   /PATH/TO/RSYNC/BIN      Manually specify rsync executable to execute restore with.
            
                 --append-rsync-arg RSYNC-ARG-TO-APPEND     Specify an additional rsync argument to be passed in to rsync.
            
            Notes:
            - You can't use both --dmg-path and --ipsw-path together at the same time.
            - If --mnt-point-path is not used, then the default Mount Point is set to /var/mnt/successor/.
            - Manually specifying an iPSW or DMG is not required. SuccessorCLI will offer to download an iPSW, extract it then get the RootfsDMG from it.
            - All arguments are optional.
            """)
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
    func getLargestFile(atPath directoryToSearch:String) -> String? {
        var fileDict = [String:Int64]()
        let enumerator = fm.enumerator(atPath: directoryToSearch)
        while let file = enumerator?.nextObject() as? String {
            let attributes = try? fm.attributesOfItem(atPath: "\(directoryToSearch)/\(file)")
            fileDict[file] = attributes?[FileAttributeKey.size] as? Int64
        }
        let sortedFiles = fileDict.sorted(by: { $0.value > $1.value } )
        printIfDebug("\(#function): sortedFiles: \(sortedFiles)")
        printIfDebug("\(#function): Biggest file at directory \"\(directoryToSearch)\": \(sortedFiles.first?.key ?? "Unknown")")
        return sortedFiles.first?.key
    }
    
    // Setting enumerate here to false will not search the subpaths of the path given, and the opposite if it's set to true
    /// Returns an array of all files in a specific path with a given extenstion
    func filesByFileExtenstion(atPath path: String, extenstion: String, enumerate: Bool) -> [String] {
        let arr = (enumerate ? fm.enumerator(atPath: path)?.allObjects.compactMap { $0 as? String } : try? fm.contentsOfDirectory(atPath: path) ) ?? [] // Has all files rather than the ones with the file extenstion only
        let filteredArr = arr.filter() { NSString(string: $0).pathExtension == extenstion } // Filters all items from the array to only include the ones with the extenstion specified
        printIfDebug("\(#function): files in directory \"\(path)\" with extenstion \(extenstion): \(filteredArr)")
        return filteredArr
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func printIfDebug(_ message:Any, file:String = #file, line:Int = #line) {
    if CMDLineArgs.contains("--debug") || CMDLineArgs.contains("-d") {
        print("[SCLI Debug]: \(file):\(line): \(message)")
    }
}


/// Returns true or false based on whether or not the current user terminal is NewTerm.
func isNT2() -> Bool {
    guard let lcTerm = ProcessInfo.processInfo.environment["LC_TERMINAL"] else {
        return false // NewTerm 2 sets the LC_TERMINAL enviroment variable
    }
    return lcTerm == "NewTerm"
}
