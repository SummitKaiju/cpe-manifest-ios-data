//
//  Theme.swift
//

import Foundation
import SWXMLHash

public struct ThemeButton: XMLIndexerDeserializable {

    /// Supported XML attribute keys
    private struct Attributes {
        static let Label = "label"
    }

    /// Supported XML element tags
    private struct Elements {
        static let Default = "Default"
        static let BaseImage = "BaseImage"
        static let HighlightImage = "HighlightImage"
        static let DefocusImage = "DefocusImage"
    }

    public var label: String
    public var baseImageID: String
    public var highlightImageID: String
    public var defocusImageID: String

    public var baseImage: Image? {
        return CPEXMLSuite.current?.manifest.imageWithID(baseImageID)
    }

    public var highlightImage: Image? {
        return CPEXMLSuite.current?.manifest.imageWithID(highlightImageID)
    }

    public var defocusImage: Image? {
        return CPEXMLSuite.current?.manifest.imageWithID(defocusImageID)
    }

    public static func deserialize(_ node: XMLIndexer) throws -> ThemeButton {
        return try ThemeButton(
            label: node.value(ofAttribute: Attributes.Label),
            baseImageID: node[Elements.Default][Elements.BaseImage].value(),
            highlightImageID: node[Elements.Default][Elements.HighlightImage].value(),
            defocusImageID: node[Elements.Default][Elements.DefocusImage].value()
        )
    }

}

open class Theme {

    /// Supported XML attribute keys
    private struct Attributes {
        static let ThemeID = "ThemeID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let ButtonImageSet = "ButtonImageSet"
        static let Button = "Button"
    }

    /// Unique identifier
    public var id: String
    public var buttons: [String: ThemeButton]? // Label: ThemeButton

    init(indexer: XMLIndexer) throws {
        // ThemeID
        guard let id: String = indexer.value(ofAttribute: Attributes.ThemeID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.ThemeID, element: indexer.element)
        }

        self.id = id

        // ButtonImageSet
        if indexer.hasElement(Elements.ButtonImageSet) {
            // Button
            guard indexer[Elements.ButtonImageSet].hasElement(Elements.Button) else {
                throw ManifestError.missingRequiredChildElement(name: Elements.Button, element: indexer[Elements.ButtonImageSet].element)
            }

            var buttons = [String: ThemeButton]()
            for indexer in indexer[Elements.ButtonImageSet][Elements.Button].all {
                let button: ThemeButton = try indexer.value()
                buttons[button.label] = button
            }

            self.buttons = buttons
        }
    }

    open func baseImageForButton(_ label: String) -> Image? {
        return buttons?[label]?.baseImage
    }

    open func baseImageURLForButton(_ label: String) -> URL? {
        return baseImageForButton(label)?.url
    }

}
