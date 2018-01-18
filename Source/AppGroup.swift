//
//  AppGroup.swift
//

import Foundation
import SWXMLHash

/// Interactive track wrappers for app groups
open class InteractiveTrackReference {
    
    /// Supported XML element tags
    private struct Elements {
        static let InteractiveTrackID = "InteractiveTrackID"
        static let Compatibility = "Compatibility"
        static let EnvironmentAttribute = "EnvironmentAttribute"
    }
    
    /// List of child `Interactive` element IDs
    public var interactiveTrackIDs: [String]
    
    /// List of child `Interactive` elements
    open lazy var interactives: [Interactive] = { [unowned self] in
        return self.interactiveTrackIDs.flatMap({ CPEXMLSuite.current?.manifest.interactiveWithID($0) })
    }()
    
    /// Attributes with which the interactive asset should be launched, namely the supported orientations
    public var environmentAttributes: [InteractiveEnvironmentAttribute]
    
    /// Flag to determine if interactive track can be launched in portrait orientation
    open var supportsPortrait: Bool {
        return environmentAttributes.contains(.portrait)
    }
    
    /// Flag to determine if interactive track can be launched in landscape orientation
    open var supportsLandscape: Bool {
        return (environmentAttributes.contains(.landscape) || environmentAttributes.isEmpty)
    }
    
    /**
         Initializes a new interactive track reference with the provided XML indexer
     
         - Parameter indexer: The root XML node
         - Throws:
             - `ManiefstError.missingRequiredChildElement` if an expected XML element is not present
     */
    init?(indexer: XMLIndexer) throws {
        // InteractiveTrackID
        guard indexer.hasElement(Elements.InteractiveTrackID) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.InteractiveTrackID, element: indexer.element)
        }
        
        interactiveTrackIDs = try indexer[Elements.InteractiveTrackID].value()
        
        // Compatibility
        guard indexer.hasElement(Elements.Compatibility) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.Compatibility, element: indexer.element)
        }
        
        // EnvironmentAttribute
        environmentAttributes = try indexer[Elements.Compatibility][Elements.EnvironmentAttribute].all.flatMap({ try InteractiveEnvironmentAttribute.build(rawValue: $0.value()) })
    }
    
}

/// App groups that reference launchable interactive assets
public class AppGroup: MetadataDriven, Trackable {

    /// Supported XML attribute keys
    private struct Attributes {
        static let AppGroupID = "AppGroupID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let InteractiveTrackReference = "InteractiveTrackReference"
    }

    /// Unique identifier
    public var id: String
    
    /// List of child `InteractiveTrackReference` elements
    public var interactiveTrackReferences: [InteractiveTrackReference]
    
    /// App URL for launching in web views
    open var url: URL? {
        return interactiveTrackReferences.first?.interactives.first?.url
    }
    
    /// Flag to determine if app group can be launched in portrait orientation
    open var supportsPortrait: Bool {
        return (interactiveTrackReferences.first?.supportsPortrait ?? false)
    }
    
    /// Flag to determine if app group can be launched in landscape orientation
    open var supportsLandscape: Bool {
        return (interactiveTrackReferences.first?.supportsLandscape ?? true)
    }

    /// Flag to determine if this app should be treated as a shopping experience
    public var isProductApp = false

    /// Tracking identifier
    open var analyticsID: String {
        return id
    }
    
    /**
         Initializes a new app group with the provided XML indexer
     
         - Parameter indexer: The root XML node
         - Throws:
             - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
             - `ManiefstError.missingRequiredChildElement` if an expected XML element is not present
     */
    override init?(indexer: XMLIndexer) throws {
        // AppGroupID
        guard let id: String = indexer.value(ofAttribute: Attributes.AppGroupID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.AppGroupID, element: indexer.element)
        }

        self.id = id
        
        // InteractiveTrackReference
        guard indexer.hasElement(Elements.InteractiveTrackReference) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.InteractiveTrackReference, element: indexer.element)
        }
        
        interactiveTrackReferences = try indexer[Elements.InteractiveTrackReference].all.flatMap({ try InteractiveTrackReference(indexer: $0) })

        // MetadataDriven
        try super.init(indexer: indexer)
    }

}
