//
//  TextObject.swift
//

import Foundation
import SWXMLHash

/// A wrapper for a set of indexed strings
open class TextObject {

    /// Supported XML attribute keys
    private struct Attributes {
        static let TextObjectID = "TextObjectID"
        static let Language = "language"
        static let Index = "index"
    }

    /// Supported XML element tags
    private struct Elements {
        static let TextString = "TextString"
    }

    /// Unique identifier
    public var id: String

    /// This mapping's language code
    public var language: String?

    /// Index to string mapping
    public var textStrings: [Int: String?]

    /**
        Initializes a new wrapper for indexed strings with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws:
            - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
            - `ManifestError.missingRequiredChildElement` if an expected XML element is not present
     */
    init(indexer: XMLIndexer) throws {
        // TextObjectID
        guard let id: String = indexer.value(ofAttribute: Attributes.TextObjectID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.TextObjectID, element: indexer.element)
        }

        self.id = id

        // Language
        language = indexer.value(ofAttribute: Attributes.Language)

        // TextString
        guard indexer.hasElement(Elements.TextString) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.TextString, element: indexer.element)
        }

        textStrings = [Int: String?]()
        var i = 1
        for indexer in indexer[Elements.TextString].all {
            textStrings[indexer.value(ofAttribute: Attributes.Index) ?? i] = try indexer.value()
            i += 1
        }
    }

    /**
        Find child TextString object by index

        - Parameter index: The index of the child TextString to look up
        - Returns: Value of the child TextString at the given `index` if it exists
    */
    open func textItem(_ index: Int) -> String? {
        if let string = textStrings[index] {
            return string
        }

        return nil
    }

}
