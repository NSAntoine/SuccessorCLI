// Includes stuff such as device, successorcli, and info of online iPSW

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

/// Provides information about SuccessorCLI App, such as its path in /var/mobile and the mount point.
class SCLIInfo { // SCLI = SuccessorCLI
    static let shared = SCLIInfo()
    var SuccessorCLIPath = "/var/mobile/Library/SuccessorCLI"

    var mountPoint = "/var/mnt/successor/"
    
    var ver = "1.8.0 PROBABLY-WORKING-BETA"
    
    /// Prints help message
    func printHelp() {
        print("""
            SuccessorCLI - A CLI Utility to restore iOS devices, based off the original Succession by samg_is_a_ninja, created by dabezt31
            Version \(SCLIInfo.shared.ver)
            Usage: successorcli <option>
                 -h, --help         Prints this help message.
                 -v, --version      Prints current SuccessorCLI Version.
                 -d, --debug        Prints extra information which may be useful.
                 --ipsw-path        /PATH/TO/IPSW           Manually specify path of iPSW to use. NOTE: This is optional.
                 --dmg-path         /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use. NOTE: This is optional.
                 --no-restore       Download and extract iPSW, rename the rootfilesystem DMG to rfs.dmg, then attach and mount rfs.dmg, but won't execute the restore itself.
                 --no-wait          Removes the 15 seconds given for the user to cancel the restore before it starts.
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
    func getLargestFile(_ directoryPath: String) -> String {
    var fileDict = [String: Int64]()
    let enumerator = fm.enumerator(atPath: directoryPath)
    while let file = enumerator?.nextObject() as? String {
        let attributes = try? fm.attributesOfItem(atPath: directoryPath + "/" + file)
        fileDict[file] = attributes?[FileAttributeKey.size] as? Int64
    }
    let sortedFiles = fileDict.sorted(by: { $0.value > $1.value })
    let biggestFile = sortedFiles.first!.key
    printIfDebug("Biggest file at directory \(directoryPath): \(biggestFile)")
    return biggestFile
    }
}

func printIfDebug(_ message:Any) {
    if CMDLineArgs.contains("--debug") || CMDLineArgs.contains("-d") {
        print("[DEBUG]: \(message)")
    }
}

func errPrint(_ message:Any, line: Int, file:String) {
    print("[ERROR] \(message), file \(file) at line \(line)")
}
