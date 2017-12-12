//
//  CacheManager.swift
//

import Foundation

open class CacheManager {

    private struct Constants {
        static let CacheParentDirectory = "CacheParentDirectory"
    }

    open static var tempDirectoryURL: URL? {
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(Constants.CacheParentDirectory, isDirectory: true)

        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return directoryURL
            }
        }

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating temp directory: \(error)")
            return nil
        }

        return directoryURL
    }

    open static func fileName(for remoteURL: URL) -> String? {
        if let fileName = remoteURL.path.split(separator: "/").last {
            return String(fileName)
        }

        return nil
    }

    open static func tempFileURL(for url: URL) -> URL? {
        if let fileName = fileName(for: url) {
            return tempDirectoryURL?.appendingPathComponent(fileName)
        }

        return nil
    }

    open static func fileExists(_ fileURL: URL) -> Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    open static func tempFileDownloadTask(url: URL, timeoutInterval: TimeInterval = 5, completionHandler: ((Data?, Error?) -> Void)? = nil) -> URLSessionDownloadTask {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: timeoutInterval)
        request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        let downloadTask = URLSession.shared.downloadTask(with: request, completionHandler: { (location, _, error) in
            if let error = error {
                print("Error downloading temp file: \(error)")

                completionHandler?(nil, error)
            } else if let sourceURL = location, let destinationURL = CacheManager.tempFileURL(for: url) {
                if fileExists(destinationURL) {
                    do {
                        try FileManager.default.removeItem(at: destinationURL)
                    } catch {
                        print("Error deleting existing temp file: \(error)")
                    }
                }

                do {
                    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                } catch {
                    print("Error moving temp file: \(error)")
                    completionHandler?(nil, error)
                    return
                }

                if let completionHandler = completionHandler {
                    do {
                        completionHandler(try Data(contentsOf: destinationURL), nil)
                    } catch {
                        print("Error converting temp file to data: \(error)")
                        completionHandler(nil, error)
                    }
                }
            }
        })

        return downloadTask
    }

    open static func clearTempDirectory() {
        if let tempDirectoryURL = tempDirectoryURL {
            do {
                try FileManager.default.removeItem(at: tempDirectoryURL)
            } catch {
                print("Error deleting temp directory: \(error)")
            }
        }
    }

}
