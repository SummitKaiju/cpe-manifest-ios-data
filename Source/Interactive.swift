//
//  Interactive.swift
//

import Foundation
import SWXMLHash

/**
    Supported interactive types
 
    - standaloneGame: Playable game that runs independently of audio or video
    - interactivity: Ability to choose settings, value added material and other options outside of menus. For example, pop-ups.
    - other: Miscellaneous interactive types
 */
public enum InteractiveType: String {
    case standaloneGame     = "standalone game"
    case interactivity      = "interactivity"
    case other              = "other"

    static func build(rawValue: String) -> InteractiveType? {
        return (InteractiveType(rawValue: rawValue) ?? InteractiveType(rawValue: rawValue.lowercased()))
    }
}

/**
    Supported interactive runtime environments
     
    - html5: W3C HTML5
    - html: W3C HTML5
    - iOS: Apple iOS
    - defaultEnvironment: Represents an application that can be played if nothing else can. This is typically an image
    - other: May be used when there is not a type convention
 */
public enum InteractiveRuntimeEnvironment: String {
    case html5              = "html5"
    case html               = "html"
    case iOS                = "ios"
    case defaultEnvironment = "default"
    case other              = "other"

    static func build(rawValue: String) -> InteractiveRuntimeEnvironment? {
        return (InteractiveRuntimeEnvironment(rawValue: rawValue) ?? InteractiveRuntimeEnvironment(rawValue: rawValue.lowercased()))
    }
}

/**
    Supported interactive environment attributes
 
    - landscape: Webview locked to landscape
    - portrait: Webview locked to portrait
*/
public enum InteractiveEnvironmentAttribute: String {
    case landscape          = "landscape"
    case portrait           = "portrait"
    
    static func build(rawValue: String) -> InteractiveEnvironmentAttribute? {
        return (InteractiveEnvironmentAttribute(rawValue: rawValue) ?? InteractiveEnvironmentAttribute(rawValue: rawValue.lowercased()))
    }
}

/// Encoding details of an interactive asset
open class InteractiveEncoding: DigitalAssetEncoding {

    /// Supported XML element tags
    private struct Elements {
        static let RuntimeEnvironment = "RuntimeEnvironment"
    }

    /// Runtime environment in which the interactive asset is designed to be launched
    public var runtimeEnvironment: InteractiveRuntimeEnvironment

    /**
        Initializes a new interactive encoding details wrapper with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws: `ManiefstError.missingRequiredChildElement` if an expected XML element is not present
     */
    override init?(indexer: XMLIndexer) throws {
        // RuntimeEnvironment
        guard let runtimeEnvironmentString: String = try indexer[Elements.RuntimeEnvironment].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.RuntimeEnvironment, element: indexer.element)
        }

        guard let runtimeEnvironment = InteractiveRuntimeEnvironment.build(rawValue: runtimeEnvironmentString) else {
            print("Ignoring unsupported Interactive Encoding object with RuntimeEnvironment \"\(runtimeEnvironmentString)\"")
            return nil
        }

        self.runtimeEnvironment = runtimeEnvironment

        // DigitalAsset
        try super.init(indexer: indexer)
    }

}

/// Launchable interactive asset
open class Interactive: DigitalAsset {

    /// Supported XML attribute keys
    private struct Attributes {
        static let InteractiveTrackID = "InteractiveTrackID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let InteractiveType = "Type"
        static let Encoding = "Encoding"
    }

    /// Unique identifier
    public var id: String

    /// Type of interactive asset
    public var type: InteractiveType

    /// Encoding details of interactive asset
    public var encodings: [InteractiveEncoding]

    /**
         Initializes a new interactive asset with the provided XML indexer
         
         - Parameter indexer: The root XML node
         - Throws:
            - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
            - `ManiefstError.missingRequiredChildElement` if an expected XML element is not present
     */
    override init?(indexer: XMLIndexer) throws {
        // InteractiveTrackID
        guard let id: String = indexer.value(ofAttribute: Attributes.InteractiveTrackID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.InteractiveTrackID, element: indexer.element)
        }

        self.id = id

        // Type
        guard let typeString: String = try indexer[Elements.InteractiveType].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.InteractiveType, element: indexer.element)
        }

        guard let type = InteractiveType.build(rawValue: typeString) else {
            print("Ignoring unsupported Interactive object with Type \"\(typeString)\"")
            return nil
        }

        self.type = type

        // Encoding
        guard indexer.hasElement(Elements.Encoding) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.Encoding, element: indexer.element)
        }

        encodings = try indexer[Elements.Encoding].all.flatMap({ try InteractiveEncoding(indexer: $0) })

        try super.init(indexer: indexer)
    }

}
