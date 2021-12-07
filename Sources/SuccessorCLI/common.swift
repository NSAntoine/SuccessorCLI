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
struct SCLIInfo { // SCLI = SuccessorCLI
    static var shared = SCLIInfo()
    
    /// If the user chooses to download or extract an iPSW, then it ends up here. This is also the path at which SuccessorCLI scans for iPSWs and DMGs
    var SuccessorCLIPath = "/var/mobile/Library/SuccessorCLI"
    
    /// Directory to where the attached DMG will be mounted to, by default this is /var/mnt/successor/, however this can be changed with `--mnt-point-path`, see help message for more.
    var mountPoint = "/var/mnt/successor/"
    
    /// SuccessorCLI Version
    var ProgramVer = "2.4.5 EXPERIMENTAL-BETA"
    
    /// Program name, always the first argument in CommandLine.arguments
    var ProgramName = CommandLine.arguments[0]
    
    static let helpMessage = """
            SuccessorCLI - By Serena-io
            A utility to restore iOS devices, inspired by the original Succession.
            Version \(SCLIInfo.shared.ProgramVer)
            Usage: successorcli [--restore/-r or --no-restore/-n] <option>
            
            General Options:
                 -h, --help         Prints this help message.
                 -d, --debug        Prints extra information which may be useful.
            
            Options for manually specifying:
                 --mnt-point-path   /PATH/TO/MOUNT          Manually specify path to mount the attached RootfsDMG to.
                 --ipsw-path        /PATH/TO/IPSW           Manually specify path of iPSW to use.
                 --dmg-path         /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use.
                 --rsync-bin-path   /PATH/TO/RSYNC/BIN      Manually specify rsync executable to execute restore with.
            
            Options for Rsync / Restoring stuff:
                 --dry-run                                  Specifies that rsync should run with --dry-run.
                 -r, --restore                              Do a full restore with rsync. Note that this WILL erase your device.
                 -n, --no-restore                           Attach and mount rootfsDMG, but exit before starting the restore.
                 --append-rsync-arg=RSYNC-ARG               Specify an additional rsync argument to be passed in to rsync.
            
            Notes:
            - All options for manually specifying are optional.
            - The user must either use --restore/-r or --no-restore/-n.
            - The default Mount Point (if --mnt-point-path isn't used) is /var/mnt/successor/.
            """
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
        // Has all files rather than the ones with the file extenstion only
        // If enumerate is true, use FileManager's enumerator, otherwise use FileManager's contentsOfDirectory
        let arr = (enumerate ? fm.enumerator(atPath: path)?.allObjects.compactMap { $0 as? String } : try? fm.contentsOfDirectory(atPath: path) ) ?? []
        
        // Filters all items from the array to only include the ones with the extenstion specified
        let filteredArr = arr.filter() { NSString(string: $0).pathExtension == extenstion }
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

func parseCMDLineArgument(longOpt:String, shortOpt:String? = nil, fromArray ArgArr:[String] = CMDLineArgs, description:String) -> String {
    
    var argToParse = ""
    if let shortOpt = shortOpt {
        // If a short option was provided in the parameters, make it the argument to parse if the long one wasn't used by the user
        argToParse = CMDLineArgs.contains(longOpt) ? longOpt : shortOpt
    } else {
        // Otherwise, only target the longOpt
        argToParse = longOpt
    }
    guard let index = ArgArr.firstIndex(of: argToParse), let specifiedValue = CMDLineArgs[safe: index + 1] else {
        fatalError("User used \(argToParse) however did not specify a \(description). See SuccessorCLI --help for more info.")
    }
    print("User manually specified \(description) as \(specifiedValue)")
    return specifiedValue
}