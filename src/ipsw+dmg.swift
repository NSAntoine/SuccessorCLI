// Manages stuff to do with iPSW And RootfsDMG
import Foundation


/// Class which manages iPSW stuff, like getting the online URL and size of the iPSW, declaring the paths at which the iPSW should be downloaded to, etc
class iPSWManager {
    static let shared = iPSWManager()

    static var onlineiPSWSizeUnformatted:Int {
        var ret = 0
        NetworkUtilities.shared.returnInfoOfOnlineIPSW(url: "https://api.ipsw.me/v4/ipsw/\(deviceInfo.machineName)/\(deviceInfo.buildID)") { jsonResponse in
            ret = jsonResponse["filesize"] as! Int
        }
        return ret
    }
    static var onlineiPSWSizeformatted:String {
        return formatBytes(Int64(onlineiPSWSizeUnformatted))
    }
    static var onlineiPSWURLStr:String {
        var ret = ""
        NetworkUtilities.shared.returnInfoOfOnlineIPSW(url: "https://api.ipsw.me/v4/ipsw/\(deviceInfo.machineName)/\(deviceInfo.buildID)") { jsonResponse in
            ret = jsonResponse["url"] as! String
        }
        return ret
    }
    
    static let onlineiPSWURL = URL(string: iPSWManager.onlineiPSWURLStr)!
    /// Returns the iPSWs that are in SCLIInfo.shared.SuccessorCLIPath, this is used mainly for iPSW detection
    static var iPSWSInSCLIPathArray:[String] {
        var ret = [String]()
        if let enumerator = fm.enumerator(atPath: SCLIInfo.shared.SuccessorCLIPath) {
            while let element = enumerator.nextObject() as? String {
                if element.hasSuffix("ipsw") {
                    ret.append(element)
                }
        }
    }
        return ret
}
    /// Path for which iPSW is downloaded to/located, by defualt its /var/Media/SuccessorCLI/ipsw.ipsw
    static var onboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/ipsw.ipsw"
    static var extractedOnboardiPSWPath = "\(SCLIInfo.shared.SuccessorCLIPath)/extracted"

    /// Function which unzips iPSW to where its specified.
    func unzipiPSW(iPSWFilePath: String, destinationPath: String) {
        let unzipTask = NSTask() /* Yes i know.. calling CLI just to unzip files is bad practice..but its better than waiting like 20 minutes with libzip.. */
        unzipTask.setLaunchPath("/usr/bin/unzip")
        unzipTask.setArguments([iPSWFilePath, "-d", destinationPath, "*.dmg"])
        unzipTask.launch()
        unzipTask.waitUntilExit()
        
        guard unzipTask.terminationStatus == 0 else {
            errPrint("Error: Couldn't successfully unzip the iPSW. Exiting.", line: #line, file: #file)
            exit(unzipTask.terminationStatus)
        }
        
        do {
            try fm.moveItem(atPath: "\(destinationPath)/\(DMGManager.shared.locateRFSDMG)", toPath: DMGManager.shared.rfsDMGToUseFullPath) /* Moves and renames the rootfs dmg */
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

/// Manages the several operations for DMG, such attaching and mounting
class DMGManager {
    static let shared = DMGManager()

    var locateRFSDMG:String {
        return fm.getLargestFile(iPSWManager.extractedOnboardiPSWPath)
    }
    var rfsDMGToUseName = "rfs.dmg" // By default this is rfs.dmg but can later on be changed if renaming fails.
    var rfsDMGToUseFullPath = SCLIInfo.shared.SuccessorCLIPath + "/rfs.dmg"
    
    class func attachDMG(dmgPath:String, completionHandler: (String?, AnyObject?) -> Void ) {
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