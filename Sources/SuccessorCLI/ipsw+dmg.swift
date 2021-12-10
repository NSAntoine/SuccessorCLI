// Manages stuff to do with iPSW And RootfsDMG
import Foundation
import SuccessorCLIBridged

// MARK: Onboard iPSW Stuff

/// Class which manages onboard iPSW Stuff, see below
class iPSWManager {
    static let shared = iPSWManager()
    
    /// Returns the iPSWs that are in SCLIInfo.SuccessorCLIPath, this is used mainly for iPSW detection
    static var iPSWSInSCLIPathArray = fm.filesByFileExtenstion(atPath: SCLIInfo.SuccessorCLIPath, extenstion: "ipsw", enumerate: true)
    
    var largestFileInsideExtractedDir:String {
        guard let ret = fm.getLargestFile(atPath: iPSWManager.extractedOnboardiPSWPath) else {
            fatalError("Tried to access largest file inside the extracted dir and failed... Exiting..")
        }
        return ret
    }
    
    static var onboardiPSWPath = "\(SCLIInfo.SuccessorCLIPath)/ipsw.ipsw"
    static var extractedOnboardiPSWPath = "\(SCLIInfo.SuccessorCLIPath)/extracted"
    
    /// Function which unzips iPSW to where its specified.
    func unzipiPSW(iPSWFilePath: String, destinationPath: String) {
        let unzipTask = NSTask() /* Yes i know.. calling CLI just to unzip files is bad practice..but its better than waiting like 20 minutes with libzip.. */
        unzipTask.setLaunchPath("/usr/bin/unzip")
        unzipTask.setArguments([iPSWFilePath, "-d", destinationPath, "*.dmg"]) // Doing *.dmg here only extracts the DMGs
        
        // Get the time at the start of extracting the iPSW
        let start = CFAbsoluteTimeGetCurrent()
        
        // Start extracting
        unzipTask.launch()
        unzipTask.waitUntilExit()
        
        // Then subtract it by the time that extracting finished to get the time it took to extract the iPSW
        let timeTaken = Int(CFAbsoluteTimeGetCurrent() - start)
        print("Extracting iPSW took \(timeTaken) seconds (\(timeTaken / 60) minutes)")

        guard unzipTask.terminationStatus == 0 else {
            fatalError("Error: Couldn't successfully unzip the iPSW. Exiting.")
        }
        print("Will now try to move largest file inside \(destinationPath) (should be a DMG) to \(SCLIInfo.SuccessorCLIPath) With the name \"rfs.dmg\"")
        let fileToMove = "\(destinationPath)/\(iPSWManager.shared.largestFileInsideExtractedDir)"
        
        // Make sure the file is a DMG
        guard NSString(string:  fileToMove).pathExtension == "dmg" else {
            fatalError("Largest file inside \"\(destinationPath)\" isn't a DMG. Exiting.")
        }
        
        do {
            try fm.moveItem(atPath: fileToMove, toPath: DMGManager.rfsDMGToUseFullPath) /* Moves and renames the rootfs dmg */
        } catch {
            fatalError("Error encountered while trying to move to \(fileToMove) to \(DMGManager.rfsDMGToUseFullPath): \(error.localizedDescription). Exiting")
        }
    }
    
    class func downloadAndExtractiPSW(onlineiPSWURL: URL = onlineiPSWManager.onlineiPSWInfo.iPSWURL, destinationPath:String = iPSWManager.onboardiPSWPath) {
        print("Will now download iPSW..")
        NetworkUtilities.shared.downloadItem(url: onlineiPSWURL, destinationURL: URL(fileURLWithPath: destinationPath))
        print("Downloaded iPSW, now time to extract it..")
        iPSWManager.shared.unzipiPSW(iPSWFilePath: iPSWManager.onboardiPSWPath, destinationPath: iPSWManager.extractedOnboardiPSWPath)
        print("Decompressed iPSW.")
    }
}

// MARK: Online iPSW Stuff
struct onlineiPSWManager {
    static private var iPSWMEJSONResponse:String {
        let apiURLStr = "https://api.ipsw.me/v4/ipsw/\(deviceInfo.machineName)/\(deviceInfo.buildID)"
        var ret = ""
        NetworkUtilities.shared.retJSONFromURL(url: apiURLStr) { responseStr in
            ret = responseStr
        }
        return ret
    }
    
     private struct onlineiPSWProperties: Codable {
        let url:URL
    }
    
    static private var JSONResponseDecoded:onlineiPSWProperties {
        guard let data = iPSWMEJSONResponse.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(onlineiPSWProperties.self, from: data) else {
                  fatalError("Couldn't get online iPSW Info. can't proceed.")
              }
        
        return decoded
    }
    
    struct onlineiPSWInfo {
        static let iPSWURL = JSONResponseDecoded.url
    }
}

// MARK: DMG Stuff
/// Manages the several operations for the RootfsDMG
class DMGManager {
    
    /// The full path at which the rfsDMG will/is located at, can be changed with the `--dmg-path` option, see the help page for more info
    static var rfsDMGToUseFullPath = SCLIInfo.SuccessorCLIPath + "/rfs.dmg"
    
    // enumerate is set to `false` here in order to stop the function to stop from searching subpaths, the reason we want it to stop from searching subpaths is that the extracted directory usually contains 2-3 DMGs, only one of which being the RootfsDMG, and we don't want to detect the useless ones
    /// Returns the DMGs that are in SCLIInfo.SuccessorCLIPath, doesn't include subdirectories
    static let DMGSinSCLIPathArray =  fm.filesByFileExtenstion(atPath: SCLIInfo.SuccessorCLIPath, extenstion: "dmg", enumerate: false)
    
    /*
     The BSDName is the disk name returned once a disk is attached, usually something like `disk7`, the disk name with `s1s1` added on it is what's supposed to be mounted.
     So for example you could have disk7, disk7s1, disk7s1s1, but disk7s1s1 is the only one we care about because thats the one that's supposed to be mounted.
     If an error was encountered with either Attach Parameters or the Attaching process itself, err returns that error in the completionHandler (see function parameters below).
     */
    class func attachDMG(dmgPath:String, completionHandler: (_ bsdName: String?, _ err:String?) -> Void) {
        let url = URL(fileURLWithPath: dmgPath)
        var err:NSError?
        let attachParams = DIAttachParams(url: url, error: err)
        attachParams?.autoMount = false
        var handler:DIDeviceHandle?
        DiskImages2.attach(with: attachParams, handle: &handler, error: err)
        let errToReturn = err?.localizedFailureReason ?? err?.localizedDescription
        completionHandler(handler?.bsdName(), errToReturn)
    }
}
