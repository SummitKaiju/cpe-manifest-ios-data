//
//  CPEXMLSuite.swift
//

import Foundation
import SWXMLHash

public enum ManifestError: Error {
    case missingManifest
    case missingRequiredAttribute(String, element: XMLElement?)
    case missingRequiredChildElement(name: String, element: XMLElement?)
    case missingRequiredValue(element: XMLElement?)
    case unsupportedAttribute(String, value: String, element: XMLElement?)
    case missingMainExperience
    case missingSupplementalExperiences
}

/**
    Supported interactive maps services
 
    - googleMaps: Google Maps (SDK required)
    - appleMaps: Apple Maps (native)
 */
public enum MapsAPIService {
    case googleMaps
    case appleMaps
}

/// Supported custom namespaces
public struct Namespaces {
    static let AppDataID = "AppID"
    static let PeopleID = "PeopleOtherID"
}

/// Supported Media Manifest spec versions
public enum ManifestSpecVersion: String {
    case unknown = "UNKNOWN"
    case oneDotFive = "1.5"
}

/// Supported Media Manifest profiles
public enum ManifestProfile: String {
    case none = "NONE"
    case ip1 = "IP-1"
}

open class CPEXMLSuite {

    /// Supported XML element tags
    private struct Elements {
        static let MediaManifest = "MediaManifest"
        static let ManifestAppDataSet = "ManifestAppDataSet"
        static let CPEStyleSet = "CPEStyleSet"
    }

    /// Various configurable data options
    public struct Settings {

        /// The `APIUtil` to be used to fetch talent details from a third party API
        public static var talentAPIUtil: TalentAPIUtil?

        /// The `APIUtil` to be used to fetch shopping experience product details from a third party API
        public static var productAPIUtil: ProductAPIUtil?

        /// The maps API service that will be used to display any interactive maps in the UI
        public static var mapsAPIService = MapsAPIService.appleMaps

        /// API key for the current maps SDK service if needed
        public static var mapsAPIKey: String?

        /// User country code to override detected device region
        public static var countryCode = Locale.current.regionCode

        public static func resetForTitle() {
            talentAPIUtil = nil
            productAPIUtil = nil
            countryCode = Locale.current.regionCode
        }

    }

    /// Reference to the currently presented XML suite
    public static var current: CPEXMLSuite?

    private static func requestXMLData(url: URL, timeoutInterval: TimeInterval = 5, completionHandler: @escaping (Data?, Error?) -> Void) -> URLSessionDownloadTask? {
        // Check if cached version of this file exists
        if let tempFileURL = CacheManager.tempFileURL(for: url), CacheManager.fileExists(tempFileURL) {
            // Download in the background for next launch
            DispatchQueue.global(qos: .background).async {
                CacheManager.tempFileDownloadTask(url: url).resume()
            }

            // Serve up the cached data
            do {
                completionHandler(try Data(contentsOf: tempFileURL), nil)
            } catch {
                completionHandler(nil, error)
            }

            return nil
        }

        // Cache the remote file and serve its data
        return CacheManager.tempFileDownloadTask(url: url, timeoutInterval: timeoutInterval, completionHandler: completionHandler)
    }

    public static func load(manifestXMLURL: URL, appDataXMLURL: URL? = nil, cpeStyleXMLURL: URL? = nil, singleTimeoutInterval: TimeInterval = 5, completionHandler: @escaping (_ error: Error?) -> Void) {
        var fetchedManifest = false
        var fetchedAppData = false
        var fetchedCPEStlye = false

        var manifestXMLData: Data?
        var appDataXMLData: Data?
        var cpeStyleXMLData: Data?

        var currentDownloadTasks = [URLSessionDownloadTask]()

        let finishWithError = { (error: Error) in
            currentDownloadTasks.forEach({
                if $0.state != .completed {
                    $0.cancel()
                }
            })

            currentDownloadTasks.removeAll()
            completionHandler(error)
        }

        let checkData = {
            if fetchedManifest && fetchedAppData && fetchedCPEStlye {
                if let manifestXMLData = manifestXMLData {
                    do {
                        try load(manifestXMLData: manifestXMLData, appDataXMLData: appDataXMLData, cpeStyleXMLData: cpeStyleXMLData)
                        completionHandler(nil)
                    } catch {
                        finishWithError(error)
                    }
                } else {
                    finishWithError(ManifestError.missingManifest)
                }
            }
        }

        if let appDataXMLURL = appDataXMLURL {
            let downloadTask = requestXMLData(url: appDataXMLURL, timeoutInterval: singleTimeoutInterval) { (data, error) in
                if let error = error {
                    finishWithError(error)
                } else {
                    appDataXMLData = data
                    fetchedAppData = true
                    checkData()
                }
            }

            if let downloadTask = downloadTask {
                currentDownloadTasks.append(downloadTask)
                downloadTask.resume()
            }
        } else {
            fetchedAppData = true
        }

        if let cpeStyleXMLURL = cpeStyleXMLURL {
            let downloadTask = requestXMLData(url: cpeStyleXMLURL, timeoutInterval: singleTimeoutInterval) { (data, error) in
                if let error = error {
                    finishWithError(error)
                } else {
                    cpeStyleXMLData = data
                    fetchedCPEStlye = true
                    checkData()
                }
            }

            if let downloadTask = downloadTask {
                currentDownloadTasks.append(downloadTask)
                downloadTask.resume()
            }
        } else {
            fetchedCPEStlye = true
        }

        let downloadTask = requestXMLData(url: manifestXMLURL, timeoutInterval: singleTimeoutInterval) { (data, error) in
            if let error = error {
                finishWithError(error)
            } else {
                manifestXMLData = data
                fetchedManifest = true
                checkData()
            }
        }

        if let downloadTask = downloadTask {
            currentDownloadTasks.append(downloadTask)
            downloadTask.resume()
        }
    }

    public static func load(manifestXMLPath: String, appDataXMLPath: String? = nil, cpeStyleXMLPath: String? = nil, completionHandler: (_ error: Error?) -> Void) throws {
        current = nil

        do {
            // Manifest
            let manifestXMLData = try Data(contentsOf: URL(fileURLWithPath: manifestXMLPath), options: .mappedIfSafe)

            // AppData
            var appDataXMLData: Data?
            if let appDataXMLPath = appDataXMLPath {
                appDataXMLData = try Data(contentsOf: URL(fileURLWithPath: appDataXMLPath), options: .mappedIfSafe)
            }

            // CPEStyle
            var cpeStyleXMLData: Data?
            if let cpeStyleXMLPath = cpeStyleXMLPath {
                cpeStyleXMLData = try Data(contentsOf: URL(fileURLWithPath: cpeStyleXMLPath), options: .mappedIfSafe)
            }

            try load(manifestXMLData: manifestXMLData, appDataXMLData: appDataXMLData, cpeStyleXMLData: cpeStyleXMLData)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    public static func load(manifestXMLData: Data, appDataXMLData: Data?, cpeStyleXMLData: Data? = nil) throws {
        // Manifest
        let manifestIndexer = SWXMLHash.config { conf in
            conf.shouldProcessNamespaces = true
        }.parse(manifestXMLData)

        guard manifestIndexer.hasElement(Elements.MediaManifest) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.MediaManifest, element: manifestIndexer.element)
        }

        let manifest = try MediaManifest(indexer: manifestIndexer[Elements.MediaManifest])

        // AppData
        var appData: AppDataSet?
        if let appDataXMLData = appDataXMLData {
            let indexer = SWXMLHash.config { conf in
                conf.shouldProcessNamespaces = true
            }.parse(appDataXMLData)

            guard indexer.hasElement(Elements.ManifestAppDataSet) else {
                throw ManifestError.missingRequiredChildElement(name: Elements.ManifestAppDataSet, element: indexer.element)
            }

            appData = try AppDataSet(indexer: indexer[Elements.ManifestAppDataSet])
        }

        // CPEStyle
        var cpeStyle: CPEStyleSet?
        if let cpeStyleXMLData = cpeStyleXMLData {
            let indexer = SWXMLHash.config { conf in
                conf.shouldProcessNamespaces = true
            }.parse(cpeStyleXMLData)

            guard indexer.hasElement(Elements.CPEStyleSet) else {
                throw ManifestError.missingRequiredChildElement(name: Elements.CPEStyleSet, element: indexer.element)
            }

            cpeStyle = try CPEStyleSet(indexer: indexer[Elements.CPEStyleSet])
        }

        current = try CPEXMLSuite(manifest: manifest, appData: appData, cpeStyle: cpeStyle)

        try manifest.postProcess()
        appData?.postProcess()
    }

    open var manifest: MediaManifest
    open var appData: AppDataSet?
    open var cpeStyle: CPEStyleSet?

    open var hasAppData: Bool {
        return (appData != nil)
    }

    open var hasCPEStyle: Bool {
        return (cpeStyle != nil)
    }

    deinit {
        Settings.resetForTitle()
    }

    init(manifest: MediaManifest, appData: AppDataSet? = nil, cpeStyle: CPEStyleSet? = nil) throws {
        self.manifest = manifest
        self.appData = appData
        self.cpeStyle = cpeStyle
    }

}
