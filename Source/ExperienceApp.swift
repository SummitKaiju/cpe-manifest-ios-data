//
//  ExperienceApp.swift
//

import Foundation
import SWXMLHash

/// Experience app that references launchable app groups and interactive assets
open class ExperienceApp: MetadataDriven, Trackable {

    /// Supported XML attribute keys
    private struct Attributes {
        static let AppID = "AppID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let AppGroupID = "AppGroupID"
        static let AppName = "AppName"
    }

    /// Possible value of unique identifier
    public var appID: String?
    
    /// Possible value of unique identifier
    public var appGroupID: String
    
    /// List of possible display names
    public var names: [String]?

    /// Unique identifier
    open var id: String {
        return (appID ?? appGroupID)
    }

    /// Display name
    override open var title: String? {
        return (names?.first ?? super.title)
    }

    /// Linked app group that contains interactive asset references
    open var appGroup: AppGroup? {
        return CPEXMLSuite.current?.manifest.appGroupWithID(appGroupID)
    }

    /// App URL for launching in web views
    open var url: URL? {
        return appGroup?.url
    }
    
    /// Flag to determine if experience app can be launched in portrait orientation
    open var supportsPortrait: Bool {
        return (appGroup?.supportsPortrait ?? false)
    }
    
    /// Flag to determine if experience app can be launched in landscape orientation
    open var supportsLandscape: Bool {
        return (appGroup?.supportsLandscape ?? true)
    }

    /// Flag to determine if this app should be treated as a shopping experience
    open lazy var isProductApp: Bool = { [unowned self] in
        if let names = self.names, let productAPIUtil = CPEXMLSuite.Settings.productAPIUtil {
            return names.contains(type(of: productAPIUtil).APINamespace)
        }

        return false
    }()

    /// Tracking identifier
    open var analyticsID: String {
        return id
    }
    
    /**
         Initializes a new experience app with the provided XML indexer
     
         - Parameter indexer: The root XML node
         - Throws:
             - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
             - `ManiefstError.missingRequiredChildElement` if an expected XML element is not present
     */
    override init?(indexer: XMLIndexer) throws {
        // AppID
        appID = indexer.value(ofAttribute: Attributes.AppID)

        // AppGroupID
        guard let appGroupID: String = try indexer[Elements.AppGroupID].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.AppGroupID, element: indexer.element)
        }

        self.appGroupID = appGroupID

        // AppName
        names = try indexer[Elements.AppName].value()

        // MetadataDriven
        try super.init(indexer: indexer)
    }

}
