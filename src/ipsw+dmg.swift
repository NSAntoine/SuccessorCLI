// Manages stuff to do with iPSW And RootfsDMG
import Foundation

// MARK: Onboard iPSW Stuff

/// Class which manages onboard iPSW Stuff, see below
class iPSWManager {
    static let shared = iPSWManager()
    /// Returns the iPSWs that are in SCLIInfo.shared.SuccessorCLIPath, this is used mainly for iPSW detection
    static var iPSWSInSCLIPathArray = fm.filesByFileExtenstion(atPath: SCLIInfo.shared.SuccessorCLIPath, extenstion: "ipsw")
    
    var largestFileInsideExtractedDir:String {
        guard let ret = fm.getLargestFile(at: URL(fileURLWithPath: iPSWManager.extractedOnboardiPSWPath)) else {
            print("Tried to access largest file inside the extracted dir and failed... Exiting..")
            exit(EXIT_FAILURE)
        }
        return ret
    }
    /// Path for which iPSW is downloaded to/located, by defualt its /var/mobile/Library/SuccessorCLI/ipsw.ipsw
    static var onboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/ipsw.ipsw"
    static var extractedOnboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/extracted"

    /// Function which unzips iPSW to where its specified.
    func unzipiPSW(iPSWFilePath: String, destinationPath: String) {
        let unzipTask = NSTask() /* Yes i know.. calling CLI just to unzip files is bad practice..but its better than waiting like 20 minutes with libzip.. */
        unzipTask.setLaunchPath("/usr/bin/unzip")
        unzipTask.setArguments([iPSWFilePath, "-d", destinationPath, "*.dmg"]) // Doing *.dmg here only extract the DMGs
        unzipTask.launch()
        unzipTask.waitUntilExit()
        
        guard unzipTask.terminationStatus == 0 else {
            errPrint("Error: Couldn't successfully unzip the iPSW. Exiting.", line: #line, file: #file)
            exit(unzipTask.terminationStatus)
        }
        
        do {
            try fm.moveItem(atPath: "\(destinationPath)/\(iPSWManager.shared.largestFileInsideExtractedDir)", toPath: DMGManager.shared.rfsDMGToUseFullPath) /* Moves and renames the rootfs dmg */
        } catch {
            errPrint("Couldnt rename and move iPSW...error: \(error.localizedDescription)\nExiting..", line: #line, file: #file)
            exit(EXIT_FAILURE)
        }
}
    
    class func downloadAndExtractiPSW(iPSWURL: URL) {
        print("Will now download iPSW..")
        NetworkUtilities.shared.downloadItem(url: iPSWURL, destinationURL: URL(fileURLWithPath: iPSWManager.onboardiPSWPath))
        print("Downloaded iPSW, now time to extract it..")
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        print("Decompressed iPSW.")
    }
}

// MARK: Online iPSW Stuff
struct onlineiPSWInfoProperties: Codable { // stuff thats in the JSON Response
    let url:URL
    let filesize:Int64
}
var iPSWMEJSONDataResponse:String {
    var ret = ""
    NetworkUtilities.shared.retJSONFromURL(url: "https://api.ipsw.me/v4/ipsw/\(deviceInfo.machineName)/\(deviceInfo.buildID)") { strResponse in
        ret = strResponse
    }
    return ret
}

let iPSWJSONRespData = iPSWMEJSONDataResponse.data(using: .utf8)!
let iPSWJSONDataDecoded = try! JSONDecoder().decode(onlineiPSWInfoProperties.self, from: iPSWJSONRespData)

struct onlineiPSWInfo {
    static let iPSWURL = iPSWJSONDataDecoded.url
    static let iPSWFileSize = iPSWJSONDataDecoded.filesize
    static let iPSWFileSizeForamtted = formatBytes(iPSWJSONDataDecoded.filesize)
}
    

// MARK: DMG Stuff
/// Manages the several operations for DMG, such attaching and mounting
class DMGManager {
    static let shared = DMGManager()
    
    var rfsDMGToUseFullPath = SCLIInfo.shared.SuccessorCLIPath + "/rfs.dmg"
    
    
    // The reason I didn't use fm.filesByFileExtenstion is because that performs a deep search into all subdirectories, all I want is the stuff inside the SuccessorCLIPath
    // This is because the extracted directory usually has 2 or 3 more DMGs (that aren't the RootfsDMG..) and usually are like 20mb, so this is a way to exclude the extracted directory i guess
    static var DMGSinSCLIPathArray: [String] {
        var ret = [String]()
        if let contents = try? fm.contentsOfDirectory(atPath: SCLIInfo.shared.SuccessorCLIPath) {
            for file in contents {
                if NSString(string: file).pathExtension == "dmg" {
                    ret.append(file)
                }
            }
        }
        return ret
    }
    
    // The BSDName is the disk name returned once a disk is attached, usually something like `disk7`, the disk name with `s1s1` added on it is what's supposed to be mounted
    // If an error was encountered with either Attach Parameters or the Attaching process itself, err returns that error in the completionHandler (see function parameters below
    class func attachDMG(dmgPath:String, completionHandler: (_ bsdName: String?, _ err:AnyObject?) -> Void) {
        let url = URL(fileURLWithPath: dmgPath)
        var attachParamsErr:AnyObject?
        var attachErr:NSError?
        var handler: DIDeviceHandle?
        let attachParams = DIAttachParams(url: url, error: &attachParamsErr)
        guard attachParamsErr == nil else {
            return completionHandler(nil, attachParamsErr)
        }
        attachParams?.autoMount = false
        DiskImages2.attach(with: attachParams, handle: &handler, error: &attachErr)
        guard attachErr == nil else {
            return completionHandler(nil, attachErr)
        }
        completionHandler(handler?.bsdName(), nil)
    }
}
