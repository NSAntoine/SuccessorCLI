// Includes general information about device, the SuccessorCLI program, and general functions.

import UIKit

/// Includes info such as the device iOS version, machine name, and the build ID
class deviceInfo {
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
    
    var ver = "1.9.8 PROBABLY-WORKING-BETA"
    
    /// Prints help message
    func printHelp() {
        print("""
            SuccessorCLI - A CLI Utility to restore iOS devices, based off the original Succession by samg_is_a_ninja, created by Dabezt31.
            Report issues to https://github.com/dabezt31/SuccessorCLI/issues
            Version \(SCLIInfo.shared.ver)
            Usage: successorcli <option>
                 -h, --help         Prints this help message.
                 -v, --version      Prints current SuccessorCLI Version.
                 -d, --debug        Prints extra information which may be useful.
                 --no-restore       Download and extract iPSW, rename the rootfilesystem DMG to rfs.dmg, then attach and mount rfs.dmg, but won't execute the restore itself.
                 --no-wait          Removes the 15 seconds given for the user to cancel the restore before it starts.
                 --online-ipsw-info Prints information about online iPSW.
                 --ipsw-path        /PATH/TO/IPSW           Manually specify path of iPSW to use.                      NOTE: This is optional.
                 --dmg-path         /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use.                    NOTE: This is optional.
                 --rsync-bin-path   /PATH/TO/RSYNC/BIN      Manually specify rsync executable to execute restore with. NOTE: This is optional.
            
            Notes:
            You can't use both --dmg-path and --ipsw-path together at the same time.
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
        printIfDebug("getLargestFile: sortedFiles: \(sortedFiles)")
        printIfDebug("getLargestFile: Biggest file at directory \"\(directoryToSearch)\": \(sortedFiles.first?.key ?? "Unknown")")
        return sortedFiles.first?.key
    }
    
    // Setting enumerate here to false will not search the subpaths of the path given, and the opposite if it's set to true
    /// Returns an array of all files in a specific path with a given extenstion
    func filesByFileExtenstion(atPath path:String, extenstion:String, enumerate:Bool) -> [String] {
        var ret = [String]() // Array with the files that have the extenstion only
        let arr = (enumerate ? fm.enumerator(atPath: path)?.allObjects.compactMap { $0 as? String } : try? fm.contentsOfDirectory(atPath: path) ) ?? []
        for file in arr {
            if NSString(string: file).pathExtension == extenstion {
                ret.append(file)
            }
        }
        printIfDebug("filesByFileExtenstion: files in directory \"\(path)\" with extenstion \(extenstion): \(ret)")
        return ret
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
        print("[DEBUG]: \(file):\(line): \(message)")
    }
}

func isNT2() -> Bool {
    guard let lcTerm = ProcessInfo.processInfo.environment["LC_TERMINAL"] else {
        return false // NewTerm 2 sets the LC_TERMINAL enviroment variable
    }
    return lcTerm == "NewTerm"
}
