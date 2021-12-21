// Includes general information about device, the SuccessorCLI program, and general functions.

import UIKit
import SuccessorCLIBridged

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

/// Provides information about SuccessorCLI Program
struct SCLIInfo { // SCLI = SuccessorCLI
    
    /// If the user chooses to download or extract an iPSW, then it ends up here. This is also the path at which SuccessorCLI scans for iPSWs and DMGs
    static var SuccessorCLIPath = "/var/mobile/Library/SuccessorCLI"
    
    /// SuccessorCLI Version
   static var ProgramVer = "2.5.6 MOSTLY-STABLE-BETA"
    
    /// Program name, always the first argument in CommandLine.arguments
    static var ProgramName = CommandLine.arguments[0]
    
    static let helpMessage = """
            SuccessorCLI - By Serena-io
            A utility to restore iOS devices, inspired by the original Succession.
            Version \(SCLIInfo.ProgramVer)
            Compiled \(compileDate) at \(compileTime)
            Usage: successorcli <option>
            
            General Options:
                 -h, --help         Prints this help message.
            
            Options for manually specifying:
                 --mnt-point-path   /PATH/TO/MOUNT          Manually specify path to mount the attached RootfsDMG to.
                 --ipsw-path        /PATH/TO/IPSW           Manually specify path of iPSW to use.
                 --dmg-path         /PATH/TO/ROOTFSDMG      Manually specify the rootfs DMG To use.
                 --rsync-bin-path   /PATH/TO/RSYNC/BIN      Manually specify rsync executable to execute restore with.
            
            Options for Rsync / Restoring stuff:
                 -r, --restore                              Do a full restore with rsync. Note that this WILL erase your device.
                 --dry-run                                  Specifies that rsync should run with --dry-run.
                 --append-rsync-arg=RSYNC-ARG               Specify an additional rsync argument to be passed in to rsync.
            
            Notes:
            - All options for manually specifying are optional.
            - If the user wants the rsync restore to be executed, the user must use --restore/-r.
            - The default Mount Point (if --mnt-point-path isn't used) is /var/mnt/successor/.
            """
}

// Takes a specified amount of bytes and formats them
// Ie "1024kb" = "1 MB"
func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = .useAll
    formatter.countStyle = .file
    formatter.includesUnit = true
    formatter.isAdaptive = true
    
    return formatter.string(fromByteCount: bytes)
}


/// Returns the difference in time between 2 date points
func differenceInTime(from startDate: Double, to endDate: Double) -> String {
    // Convert both of our startDate and endDate parameters to Date
    // Because formatter.string(from: to:) requires the parameters to be Date()
    let firstDate = Date(timeIntervalSince1970: startDate)
    let secondDate = Date(timeIntervalSince1970: endDate)
    
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    
    formatter.allowedUnits = [.minute, .hour, .second]
    formatter.includesApproximationPhrase = true
    let formattedStr = formatter.string(from: firstDate, to: secondDate)
    return formattedStr ?? "Unknown"
}

func parseCMDLineArgument(longOpt:String, shortOpt:String? = nil, fromArray Arguments:[String] = CMDLineArgs, description:String) -> String {
    
    var argToParse = ""
    if let shortOpt = shortOpt {
        // If a short option was provided in the parameters, make it the argument to parse if the long one wasn't used by the user
        argToParse = Arguments.contains(longOpt) ? longOpt : shortOpt
    } else {
        // Otherwise, only target the longOpt
        argToParse = longOpt
    }
    guard let index = Arguments.firstIndex(of: argToParse), let specifiedValue = CMDLineArgs[safe: index + 1] else {
        fatalError("User used \(argToParse) however did not specify a \(description). See SuccessorCLI --help for more info.")
    }
    print("User manually specified \(description) as \(specifiedValue)")
    return specifiedValue
}
