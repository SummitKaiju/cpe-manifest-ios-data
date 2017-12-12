//
//  TimedEvent.swift
//

import Foundation
import SWXMLHash

/**
    Supported `TimedEvent` types
 
    - any: Event has any kind of item associated with it
    - appGroup: Event has an `AppGroup` associated with it
    - gallery: Event has a `Gallery` associated with it
    - video: Event has a `Presentation` associated with it
    - clipShare: Event is a `video` type with subtype `Shareable Clip`
    - location: Event has a `Location` associated with it
    - product: Event has a `ProductItem` associated with it
    - person: Event has a `Person` associated with it
    - textItem: Event has a `TextObject` associated with it
 */
public enum TimedEventType {
    case any
    case appGroup
    case gallery
    case video
    case clipShare
    case location
    case product
    case person
    case textItem
}

/**
    Checks the equality of two `TimedEvent` objects
 
    - Parameters
        - lhs: The first `TimedEvent` object to compare
        - rhs: The second `TimedEvent` object to compare
 
    - Returns: `true` if the `TimedEvent` objects have the same ID and start time
 */
public func == (lhs: TimedEvent, rhs: TimedEvent) -> Bool {
    return (lhs.id == rhs.id && lhs.startTime == rhs.startTime)
}

/// An event tied to a playback timecode
open class TimedEvent: Equatable, Trackable {

    /// Supported XML attribute keys
    private struct Attributes {
        static let Index = "index"
    }

    /// Supported XML element tags
    private struct Elements {
        static let StartTimecode = "StartTimecode"
        static let EndTimecode = "EndTimecode"
        static let PresentationID = "PresentationID"
        static let PictureID = "PictureID"
        static let GalleryID = "GalleryID"
        static let AppGroupID = "AppGroupID"
        static let TextGroupID = "TextGroupID"
        static let ProductID = "ProductID"
        static let OtherID = "OtherID"
        static let Initialization = "Initialization"
    }

    /// Unique identifier
    public var id: String

    /// Start time of this event (in seconds)
    public var startTime: Double

    /// End time of this event (in seconds)
    public var endTime: Double

    /// ID for associated `Presentation`
    public var presentationID: String?

    /// ID for associated `Picture`
    public var pictureID: String?

    /// ID for associated `Gallery`
    public var galleryID: String?

    /// ID for associated `AppGroup`
    public var appGroupID: String?

    public var textGroupMappings: [(textGroupID: String, index: Int)]?

    /// ID for associated `ProductItem`
    public var productID: ContentIdentifier?

    /// ID for other associated content (e.g. Person)
    public var otherID: ContentIdentifier?

    /// ID for parent `Experience`
    public var experienceID: String?

    /// Tracking identifier
    open lazy var analyticsID: String = { [unowned self] in
        if let id = self.presentationID {
            return id
        }

        if let id = self.pictureID {
            return id
        }

        if let id = self.galleryID {
            return id
        }

        if let id = self.appGroupID {
            return id
        }

        if let id = self.productID?.identifier {
            return id
        }

        if let id = self.otherID?.identifier {
            return id
        }

        return self.id
    }()

    /// Parent `Experience`
    open var experience: Experience? {
        return CPEXMLSuite.current?.manifest.experienceWithID(experienceID)
    }

    /// Associated `ExperienceAudioVisual` (used for video clips)
    open lazy var audioVisual: ExperienceAudioVisual? = { [unowned self] in
        if let id = self.presentationID {
            return CPEXMLSuite.current?.manifest.presentationToAudioVisualMapping?[id]
        }

        return nil
    }()

    /// Associated `Picture` (used for single/supplemental image)
    open var picture: Picture? {
        return CPEXMLSuite.current?.manifest.pictureWithID(pictureID)
    }

    /// Associated `Gallery` (used for gallery of images)
    open var gallery: Gallery? {
        return CPEXMLSuite.current?.manifest.galleryWithID(galleryID)
    }

    /// Associated `AppGroup` (used for HTML5 apps)
    open var appGroup: AppGroup? {
        return CPEXMLSuite.current?.manifest.appGroupWithID(appGroupID)
    }

    /// Associated `Person` (used for talent details)
    open var person: Person? {
        if let otherID = otherID, otherID.namespace == Namespaces.PeopleID {
            return CPEXMLSuite.current?.manifest.personWithID(otherID.identifier)
        }

        return nil
    }

    /// Associated `AppDataItemLocation` (used for scene loations)
    open var location: AppDataItemLocation? {
        if let otherID = otherID, otherID.namespace == Namespaces.AppDataID {
            return CPEXMLSuite.current?.appData?.locationWithID(otherID.identifier)
        }

        return nil
    }

    /// Associated `AppDataItemProduct` (used for scene products)
    open var product: AppDataItemProduct? {
        if let otherID = otherID, otherID.namespace == Namespaces.AppDataID {
            return CPEXMLSuite.current?.appData?.productWithID(otherID.identifier)
        }

        return nil
    }

    /// Associated text item (used for trivia)
    open lazy var textItem: String? = { [unowned self] in
        if let textGroupMapping = self.textGroupMappings?.first {
            return CPEXMLSuite.current?.manifest.textGroupWithID(textGroupMapping.textGroupID)?.textObject?.textItem(textGroupMapping.index)
        }

        return nil
    }()

    /// Primary text of associated object
    open var description: String? {
        if isType(.textItem) {
            return textItem
        }

        return (gallery?.title ?? location?.title ?? audioVisual?.title)
    }

    /// Image URL of associated object
    open var imageURL: URL? {
        if isType(.clipShare) {
            return audioVisual?.metadata?.largeImageURL
        }

        return picture?.imageURL
    }

    /// Thumbnail image URL of associated object
    private var _thumbnailImageURL: URL?
    open var thumbnailImageURL: URL? {
        if _thumbnailImageURL == nil {
            if let url = gallery?.thumbnailImageURL {
                _thumbnailImageURL = url
            } else if let url = picture?.thumbnailImageURL {
                _thumbnailImageURL = url
            } else if let url = audioVisual?.thumbnailImageURL {
                _thumbnailImageURL = url
            } else if let url = location?.thumbnailImageURL {
                _thumbnailImageURL = url
            } else if let url = appGroup?.thumbnailImageURL {
                _thumbnailImageURL = url
            }
        }

        return (_thumbnailImageURL ?? imageURL)
    }

    /**
        Initializes a new event at the provided timecodes
     
        - Parameters
            - startTime: The start time, in seconds, of the event
            - endTime: The end time, in seconds, of the event
     */
    init(startTime: Double, endTime: Double) {
        id = UUID().uuidString
        self.startTime = startTime
        self.endTime = endTime
    }

    /**
        Initializes a new event with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws:
            - `ManifestError.missingRequiredChildElement` if an expected XML element is not present
     */
    init(indexer: XMLIndexer) throws {
        // Custom ID
        id = UUID().uuidString

        // StartTimecode
        guard let startTime: Double = try indexer[Elements.StartTimecode].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.StartTimecode, element: indexer.element)
        }

        self.startTime = startTime

        // EndTimecode
        guard let endTime: Double = try indexer[Elements.EndTimecode].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.EndTimecode, element: indexer.element)
        }

        self.endTime = endTime

        // PresentationID / PictureID / GalleryID / AppGroupID / TextGroupID / OtherID
        if indexer.hasElement(Elements.PresentationID) {
            presentationID = try indexer[Elements.PresentationID].value()
        } else if indexer.hasElement(Elements.PictureID) {
            pictureID = try indexer[Elements.PictureID].value()
        } else if indexer.hasElement(Elements.GalleryID) {
            galleryID = try indexer[Elements.GalleryID].value()
        } else if indexer.hasElement(Elements.AppGroupID) {
            appGroupID = try indexer[Elements.AppGroupID].value()
        } else if indexer.hasElement(Elements.TextGroupID) {
            var textGroupMappings = [(String, Int)]()
            for indexer in indexer[Elements.TextGroupID].all {
                if let textGroupID: String = try indexer.value(), let index: Int = indexer.value(ofAttribute: Attributes.Index) {
                    textGroupMappings.append((textGroupID, index))
                }
            }

            self.textGroupMappings = textGroupMappings
        } else if indexer.hasElement(Elements.ProductID) {
            productID = try indexer[Elements.ProductID].value()
        } else if indexer.hasElement(Elements.OtherID) {
            otherID = try indexer[Elements.OtherID].value()
        }

        // Initialization
        if pictureID == nil { // Making assumption that supplemental PictureID is in the Initialization property
            pictureID = try indexer[Elements.Initialization].value()
        }
    }

    /**
        Check if TimedEvent is of the specified type
 
        - Parameter type: Type of TimedEvent
        - Returns: `true` if the TimedEvent is of the specified type
    */
    open func isType(_ type: TimedEventType) -> Bool {
        switch type {
        case .appGroup:
            return (appGroup != nil)

        case .video:
            return (audioVisual != nil)

        case .clipShare:
            return (experience?.isClipShareExperience ?? false)

        case .gallery:
            return (gallery != nil)

        case .location:
            return (location != nil)

        case .product:
            if let productAPIUtil = CPEXMLSuite.Settings.productAPIUtil, let productNamespace = productID?.namespace {
                return (productNamespace == Swift.type(of: productAPIUtil).APINamespace)
            }

            return (product != nil)

        case .person:
            return (person != nil)

        case .textItem:
            return (textItem != nil)

        case .any:
            return true
        }
    }

}
