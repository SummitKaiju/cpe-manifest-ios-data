//
//  AppData.swift
//

import Foundation
import SWXMLHash

public struct AppDataNVPairName {
    // Global
    static let AppType = "type"
    static let Text = "text"
    static let Description = "description"
    static let DisplayOrder = "display_order"
    static let ContentID = "content_id"
    static let ParentContentID = "parent_content_id"
    static let ExperienceID = "experience_id"
    static let VideoID = "video_id"
    static let PictureID = "picture_id"
    static let VideoThumbnail = "video_thumbnail"
    static let GalleryThumbnail = "gallery_thumbnail"

    // Location
    static let Location = "location"
    static let LocationThumbnail = "location_thumbnail"
    static let Zoom = "zoom"
    static let ZoomLocked = "zoom_locked"

    // Product
    static let ExternalURL = "external_url"
    static let Price = "price"
    static let ExactMatch = "exact_match"
    static let ProductImageBullseyeX = "product_image_bullseye_x"
    static let ProductImageBullseyeY = "product_image_bullseye_y"
    static let SceneImage = "scene_image"
    static let SceneImageBullseyeX = "scene_image_bullseye_x"
    static let SceneImageBullseyeY = "scene_image_bullseye_y"
    static let ProductVideo = "product_video"
    static let ProductVideoContentID = "product_video_content_id"
}

open class AppDataItem: Trackable {

    internal struct Attributes {
        static let AppID = "AppID"
        static let Name = "Name"
        static let Currency = "currency"
    }

    internal struct Elements {
        static let NVPair = "NVPair"
        static let ExperienceID = "ExperienceID"
        static let ContentID = "ContentID"
        static let LocationSet = "LocationSet"
        static let Location = "Location"
        static let URL = "URL"
        static let Money = "Money"
        static let Text = "Text"
        static let PictureID = "PictureID"
        static let PresentationID = "PresentationID"
        static let Decimal = "Decimal"
        static let Integer = "Integer"
    }

    @objc public var id: String
    public var displayOrder: Int = 0

    public var contentID: String?
    public var parentContentID: String?

    open var metadata: Metadata? {
        return CPEXMLSuite.current?.manifest.metadataWithID(self.contentID)
    }

    open var parentMetadata: Metadata? {
        return CPEXMLSuite.current?.manifest.metadataWithID(self.parentContentID)
    }

    open var title: String? {
        if let title = experience?.title {
            return title
        }

        return metadata?.title
    }

    public var _description: String?
    open var description: String? {
        return (_description ?? experience?.description ?? metadata?.description)
    }

    open var thumbnailImageURL: URL? {
        return (experience?.thumbnailImageURL ?? metadata?.imageURL)
    }

    public var pictureIDs: [String]?
    open var pictures: [Picture]? {
        if let pictureIDs = pictureIDs {
            return pictureIDs.flatMap({ CPEXMLSuite.current?.manifest.pictureWithID($0) })
        }

        return nil
    }

    public var experienceID: String?
    open var experience: Experience? {
        return CPEXMLSuite.current?.manifest.experienceWithID(self.experienceID)
    }

    open var mediaCount: Int {
        return (experience?.experienceChildren?.count ?? 0)
    }

    /// Tracking identifier
    open var analyticsID: String {
        return id
    }

    init(indexer: XMLIndexer) throws {
        // AppID
        guard let id: String = indexer.value(ofAttribute: Attributes.AppID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.AppID, element: indexer.element)
        }

        self.id = id

        // NVPair
        guard indexer.hasElement(Elements.NVPair) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.NVPair, element: indexer.element)
        }

        for indexer in indexer[Elements.NVPair].all {
            // Name
            guard let name: String = indexer.value(ofAttribute: Attributes.Name) else {
                throw ManifestError.missingRequiredAttribute(Attributes.Name, element: indexer.element)
            }

            switch name {
            case AppDataNVPairName.ExperienceID:
                // ExperienceID
                guard let experienceID: String = try indexer[Elements.ExperienceID].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.ExperienceID, element: indexer.element)
                }

                self.experienceID = experienceID
                break

            case AppDataNVPairName.ContentID:
                // ContentID
                guard let contentID: String = try indexer[Elements.ContentID].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.ContentID, element: indexer.element)
                }

                self.contentID = contentID
                break

            case AppDataNVPairName.ParentContentID:
                // Content ID
                guard let parentContentID: String = try indexer[Elements.ContentID].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.ContentID, element: indexer.element)
                }

                self.parentContentID = parentContentID
                break

            case AppDataNVPairName.DisplayOrder:
                guard let displayOrder: Int = try indexer[Elements.Integer].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.Integer, element: indexer.element)
                }

                self.displayOrder = displayOrder
                break

            case AppDataNVPairName.Description:
                guard let description: String = try indexer[Elements.Text].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.Text, element: indexer.element)
                }

                _description = description
                break

            case AppDataNVPairName.PictureID:
                guard let pictureID: String = try indexer[Elements.PictureID].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.PictureID, element: indexer.element)
                }

                if pictureIDs == nil {
                    pictureIDs = [String]()
                }

                pictureIDs!.append(pictureID)
                break

            default:
                break
            }
        }
    }

    /**
        Finds the Experience media associated with the AppData at the specified index
     
        - Parameter index: Media index to search
        - Returns: Associated Experience if it exists
     */
    open func mediaAtIndex(_ index: Int) -> Experience? {
        return (index < mediaCount ? experience?.childExperiences?[index] : nil)
    }

}
