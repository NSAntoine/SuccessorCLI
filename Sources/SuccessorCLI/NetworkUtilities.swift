import Foundation

let group = DispatchGroup()
let sema = DispatchSemaphore(value: 0)
/// Utilities for making HTTP requests & downloading items
class NetworkUtilities:NSObject {
    static let shared = NetworkUtilities()
    
    /// Returns info from ipsw.me's v4 API, which can be returned in other JSON or XML, docs: https://ipswdownloads.docs.apiary.io/
    func retJSONFromURL(url:String, completion: @escaping (String) -> Void) {
        group.enter()
        let task = URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
            // Make sure we encountered no errors
            guard let data = data, error == nil,
                let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    fatalError("Error while getting online iPSW Info: \(error?.localizedDescription ?? "Unknown error")")
                }
            // Make sure the string response is valid
            guard let strResponse = String(data: data, encoding: .utf8) else {
                fatalError("Error encountered while converting JSON Response from ipsw.me to string..exiting..")
            }
            completion(strResponse)
            group.leave()
        }
        task.resume()
        group.wait()
    }
    
    var downloadItemDestination = ""
    func downloadItem(url: URL, destinationURL: URL) {
        downloadItemDestination = destinationURL.path
        let downloadTimeStarted = Int(CFAbsoluteTimeGetCurrent())
        let task = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        task.downloadTask(with: url).resume()
        sema.wait()
        let timeTakenToDownload = Int(CFAbsoluteTimeGetCurrent()) - downloadTimeStarted
        print("Downloading iPSW took \(timeTakenToDownload) seconds (\(timeTakenToDownload / 60) minutes) to download")
        }
}


extension NetworkUtilities: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo: URL) {
        print("finished downloading item to \(didFinishDownloadingTo)")
        if fm.fileExists(atPath: self.downloadItemDestination) {
            print("File already exists at \(self.downloadItemDestination).. will now try to replace it.")
            do {
                try fm.replaceItemAt(URL(fileURLWithPath:  self.downloadItemDestination), withItemAt: didFinishDownloadingTo)
                print("Successfully replaced \(self.downloadItemDestination) with \(didFinishDownloadingTo)")
            } catch {
                fatalError("Error with replacing \(self.downloadItemDestination): \(error)..")
            }
        } else {
            do {
                try fm.moveItem(at: didFinishDownloadingTo, to: URL(fileURLWithPath: self.downloadItemDestination))
                print("Successfully Moved item at \(didFinishDownloadingTo) to \(self.downloadItemDestination)")
            } catch {
                fatalError("Error encountered while moving \(didFinishDownloadingTo) to \(self.downloadItemDestination): \(error)")
            }
        }
        sema.signal()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let totalBytesWrittenFormatted = formatBytes(totalBytesWritten)
        let totalBytesExpectedToWriteFormatted = formatBytes(totalBytesExpectedToWrite)

        print("Downloaded \(totalBytesWrittenFormatted) out of \(totalBytesExpectedToWriteFormatted)", terminator: "\r")
        fflush(stdout)
    }
}

