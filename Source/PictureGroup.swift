//
//  PictureGroup.swift
//

import Foundation
import SWXMLHash

open class Picture {

    /// Supported XML element tags
    private struct Elements {
        static let PictureID = "PictureID"
        static let ImageID = "ImageID"
        static let ThumbnailImageID = "ThumbnailImageID"
        static let Caption = "Caption"
        static let Sequence = "Sequence"
    }

    /// Unique identifier
    public var id: String
    public var imageID: String?
    public var thumbnailImageID: String?
    public var captions: [String]?
    public var sequence: Int = 0

    open var image: Image? {
        return CPEXMLSuite.current?.manifest.imageWithID(imageID)
    }

    private var _imageURL: URL?
    open var imageURL: URL? {
        return (_imageURL ?? image?.url)
    }

    open var thumbnailImage: Image? {
        return CPEXMLSuite.current?.manifest.imageWithID(thumbnailImageID)
    }

    private var _thumbnailImageURL: URL?
    open var thumbnailImageURL: URL? {
        return (_thumbnailImageURL ?? thumbnailImage?.url ?? imageURL)
    }

    open var caption: String? {
        return captions?.first
    }

    init(imageURL: URL, thumbnailImageURL: URL? = nil) {
        id = UUID().uuidString
        _imageURL = imageURL
        _thumbnailImageURL = thumbnailImageURL
    }

    init(indexer: XMLIndexer) throws {
        // PictureID
        guard let id: String = try indexer[Elements.PictureID].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.PictureID, element: indexer.element)
        }

        self.id = id

        // ImageID
        guard let imageID: String = try indexer[Elements.ImageID].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.ImageID, element: indexer.element)
        }

        self.imageID = imageID

        // ThumbnailImageID
        thumbnailImageID = try indexer[Elements.ThumbnailImageID].value()

        // Caption
        captions = try indexer[Elements.Caption].all.flatMap({
            if let caption: String = try $0.value(), caption.count > 0 {
                return caption
            }

            return nil
        })

        // Sequence
        sequence = (try indexer[Elements.Sequence].value() ?? 0)
    }

}

public class PictureGroup {

    /// Supported XML attribute keys
    private struct Attributes {
        static let PictureGroupID = "PictureGroupID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let Picture = "Picture"
    }

    /// Unique identifier
    public var id: String?
    public var pictures: [Picture]

    open var thumbnailImageURL: URL? {
        return pictures.first?.thumbnailImageURL
    }

    open var numPictures: Int {
        return pictures.count
    }

    init(imageURLs: [URL]) {
        pictures = imageURLs.map({ Picture(imageURL: $0) })
    }

    init(pictures: [Picture]) {
        self.pictures = pictures
    }

    init(indexer: XMLIndexer) throws {
        // PictureGroupID
        guard let id: String = indexer.value(ofAttribute: Attributes.PictureGroupID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.PictureGroupID, element: indexer.element)
        }

        self.id = id

        // Picture
        guard indexer.hasElement(Elements.Picture) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.Picture, element: indexer.element)
        }

        pictures = try indexer[Elements.Picture].all.flatMap({ try Picture(indexer: $0) })
    }

    open func picture(atIndex index: Int) -> Picture? {
        return (pictures.count > index ? pictures[index] : nil)
    }

}
