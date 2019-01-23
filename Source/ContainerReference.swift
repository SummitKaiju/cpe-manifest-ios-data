//
//  ContainerReference.swift
//

import Foundation
import SWXMLHash

/// A reference to Container within another object
public class ContainerReference {

    /// Supported XML attribute keys
    private struct Attributes {
        static let Priority = "priority"
    }

    /// Supported XML element tags
    private struct Elements {
        static let ContainerLocation = "ContainerLocation"
        static let ParentContainer = "ParentContainer"
        static let ContainerIdentifier = "ContainerIdentifier"
        static let Length = "Length"
        static let Hash = "Hash"
    }

    /// List of file locations
    public var locations: [URL]?

    /// Container's parent if it's located within another Container
    public var parentContainer: ContainerReference?

    /// Identifiers for the Container
    public var identifiers: [ContentIdentifier]?

    /// Length of Container in bytes
    public var length: Int?

    /// Container's primary file location
    open var url: URL? {
        return locations?.first
    }

    /**
        Initializes a new file reference Container with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws:
            - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
            - `ManiefstError.missingRequiredChildElement` if an expected XML element is not present
     */
    public init(indexer: XMLIndexer) throws {
        // ContainerLocation
        if indexer.hasElement(Elements.ContainerLocation) {
            var locations = [URL?](repeating: nil, count: indexer[Elements.ContainerLocation].all.count)
            for indexer in indexer[Elements.ContainerLocation].all {
                if let urlString: String = try indexer.value(), let url = URL(string: urlString) {
                    var index = 0
                    if let priority: Int = indexer.value(ofAttribute: Attributes.Priority) {
                        index = min(priority - 1, 0)
                    }

                    locations.insert(url, at: index)
                }
            }

            self.locations = locations.compactMap { $0 }
        }

        // ParentContainer
        if indexer.hasElement(Elements.ParentContainer) {
            parentContainer = try ContainerReference(indexer: indexer[Elements.ParentContainer])
        }

        // ContainerIdentifier
        identifiers = try indexer[Elements.ContainerIdentifier].value()

        // Length
        length = try indexer[Elements.Length].value()
    }

}
