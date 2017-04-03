//
//  PictureGroup.swift
//

import Foundation
import SWXMLHash

open class Picture {

    private struct Elements {
        static let PictureID = "PictureID"
        static let ImageID = "ImageID"
        static let ThumbnailImageID = "ThumbnailImageID"
        static let Caption = "Caption"
        static let Sequence = "Sequence"
    }

    var id: String
    public var imageID: String?
    var thumbnailImageID: String?
    var captions: [String]?
    public var sequence: Int = 0

    open lazy var image: Image? = { [unowned self] in
        return CPEXMLSuite.current?.manifest.imageWithID(self.imageID)
    }()

    private var _imageURL: URL?
    open var imageURL: URL? {
        return (_imageURL ?? image?.url)
    }

    open lazy var thumbnailImage: Image? = { [unowned self] in
        return CPEXMLSuite.current?.manifest.imageWithID(self.thumbnailImageID)
    }()

    open var thumbnailImageURL: URL? {
        return (thumbnailImage?.url ?? imageURL)
    }

    open var caption: String? {
        return captions?.first
    }

    init(imageURL: URL) {
        id = UUID().uuidString
        _imageURL = imageURL
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
        captions = try indexer[Elements.Caption].value()

        // Sequence
        sequence = (try indexer[Elements.Sequence].value() ?? 0)
    }

}

public class PictureGroup {

    private struct Attributes {
        static let PictureGroupID = "PictureGroupID"
    }

    private struct Elements {
        static let Picture = "Picture"
    }

    var id: String?
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

        pictures = try indexer[Elements.Picture].flatMap({ try Picture(indexer: $0) })
    }

}
