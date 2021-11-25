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

    /// If the user chooses to download or extract an iPSW, then it ends up here. This is also the path at which SuccessorCLI scans for iPSWs and DMGs
    var SuccessorCLIPath = "/var/mobile/Library/SuccessorCLI"

    /// Directory to where the attached DMG will be mounted to, by default this is /var/mnt/successor/, however this can be changed with `--mnt-point-path`, see help message for more.
    var mountPoint = "/var/mnt/successor/"
    
    /// SuccessorCLI Version
    var ProgramVer = "2.3.5 EXPERIMENTAL-BETA"
    
    /// Program name, always the first argument in CommandLine.arguments
    var ProgramName = CommandLine.arguments[0]
    
    static let helpMessage = """
            SuccessorCLI - A CLI Utility to restore iOS devices, based off the original Succession by samg_is_a_ninja, created by Dabezt31.
            Report issues to https://github.com/dabezt31/SuccessorCLI/issues
            Version \(SCLIInfo.shared.ProgramVer)
            Usage: successorcli <option>
            
            General Options:
                 -h, --help         Prints this help message.
                 -d, --debug        Prints extra information which may be useful.
            
            Options for manually specifying:
                 --mnt-point-path   /PATH/TO/MOUNT          Manually specify path to mount the attached RootfsDMG to.
                 --ipsw-path        /PATH/TO/IPSW           Manually specify path of iPSW to use.
                 --dmg-path         /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use.
                 --rsync-bin-path   /PATH/TO/RSYNC/BIN      Manually specify rsync executable to execute restore with.
                 --scli-path        /PATH/TO/SET            Manually specify the SuccessorCLI directory.
            
            Options for Rsync / Restoring stuff:
                 --rsync-dry-run                            Specifies that rsync should run with --dry-run.
                 --restore                                  Do a full restore with rsync. Note that this WILL erase your device.
                 --append-rsync-arg=RSYNC-ARG               Specify an additional rsync argument to be passed in to rsync.
            
            Notes:
            - All options for manually specifying are optional.
            - SuccessorCLI Does not execute a restore if --restore / -r is not used. Use --restore / -r to execute the restore.
            - The default Mount Point (if --mnt-point-path isn't used) is /var/mnt/successor/.
            - Using --scli-path will change the SuccessorCLI Path, which changes where DMGs/iPSWs are searched for and changes the path of where iPSWs are downloaded if the user chooses to do so
            """
    
    func printHelp() {
        print(SCLIInfo.helpMessage)
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

/* The following function returns the value that the user specified for a specific option. Example:
 --dmg-path randomDMG.dmg
 The function will return `randomDMG.dmg`.
 
 The `thingToParse` parameter is there to be shown in the error message or if the parsing was successful
 */
func retValueAfterCMDLineOpt(longOpt:String, fromArgArr ArgArr:[String] = CMDLineArgs, thingToParseName:String) -> String {
    guard let index = ArgArr.firstIndex(of: longOpt), let specifiedThing = ArgArr[safe: index + 1] else {
        fatalError("User used \(longOpt), however the program couldn't get the \(thingToParseName) specified, make sure you specified one. See SuccessorCLI --help for more info.")
    }
    print("User manually specified \(thingToParseName) as \(specifiedThing)")
    return specifiedThing
}
