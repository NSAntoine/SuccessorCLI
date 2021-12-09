import Foundation

extension FileManager {
    func getLargestFile(atPath path:String) -> String? {
        // Return nil if the contents of said directory is empty
        let contentsOfDir = (try? contentsOfDirectory(atPath: path)) ?? []
        if contentsOfDir.isEmpty { return nil }
        
        var fileDict = [String:Int64]()
        let enumerator = fm.enumerator(atPath: path)
        while let file = enumerator?.nextObject() as? String {
            let attributes = try? fm.attributesOfItem(atPath: "\(path)/\(file)")
            fileDict[file] = attributes?[FileAttributeKey.size] as? Int64
        }
        let sortedFiles = fileDict.sorted(by: { $0.value > $1.value } )
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
        return filteredArr
    }
    
    /// Creates a path if it doesnt exist, returns nil if creation was successfull, otherwise it returns the errors description
    func safeCreatePath(_ path:String) -> String? {
        let url = URL(fileURLWithPath: path)
        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            print("created Path \(path) Successfully.")
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
