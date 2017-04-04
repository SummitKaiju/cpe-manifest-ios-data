//
//  Experience.swift
//

import Foundation
import SWXMLHash

public enum ExperienceType {
    case app
    case audioVisual
    case gallery
    case location
    case product
}

public func == (lhs: Experience, rhs: Experience) -> Bool {
    return lhs.id == rhs.id
}

public struct ExperienceChild: XMLIndexerDeserializable {

    private struct Elements {
        static let ExperienceID = "ExperienceID"
        static let SequenceInfo = "SequenceInfo"
        static let Number = "Number"
    }

    var experienceID: String
    var sequence: Int

    public static func deserialize(_ node: XMLIndexer) throws -> ExperienceChild {
        return try ExperienceChild(
            experienceID: node[Elements.ExperienceID].value(),
            sequence: (node[Elements.SequenceInfo][Elements.Number].value() ?? 0)
        )
    }

}

open class Experience: MetadataDriven, Equatable, Trackable {

    var nodeStyles: [NodeStyle]?

    private struct Attributes {
        static let ExperienceID = "ExperienceID"
    }

    private struct Elements {
        static let Region = "Region"
        static let ExcludedRegion = "ExcludedRegion"
        static let Country = "country"
        static let AudioVisual = "Audiovisual"
        static let Gallery = "Gallery"
        static let App = "App"
        static let TimedSequenceID = "TimedSequenceID"
        static let ExperienceChild = "ExperienceChild"
    }

    public var id: String
    var audioVisual: ExperienceAudioVisual?
    public var gallery: Gallery?
    public var app: ExperienceApp?
    var experienceChildren: [ExperienceChild]?
    private var timedEventSequenceID: String?
    var sequence: Int = 0

    override open var title: String! {
        if let title = super.title {
            return title
        }

        if let title = location?.title {
            return title
        }

        return ""
    }

    override open var description: String? {
        return (super.description ?? location?.description)
    }

    open var largeImageURL: URL? {
        return (metadata?.largeImageURL ?? audioVisual?.metadata?.largeImageURL ?? thumbnailImageURL)
    }

    override open var thumbnailImageURL: URL? {
        if let imageURL = super.thumbnailImageURL {
            return imageURL
        }

        // Break recursion if this is one of the main experiences
        if isMainExperience || isInMovieExperience || isOutOfMovieExperience {
            return nil
        }

        if let imageURL = audioVisual?.thumbnailImageURL {
            return imageURL
        }

        if let imageURL = gallery?.thumbnailImageURL {
            return imageURL
        }

        if let imageURL = location?.thumbnailImageURL {
            return imageURL
        }

        if let imageURL = product?.productImageURL {
            return imageURL
        }

        if let imageURL = app?.thumbnailImageURL {
            return imageURL
        }

        return childExperiences?.first?.thumbnailImageURL
    }

    open lazy var childExperiences: [Experience]? = { [unowned self] in
        if let experienceChildren = self.experienceChildren {
            var childExperiences = [Experience]()
            for experienceChild in experienceChildren {
                if let experience = CPEXMLSuite.current?.manifest.experienceWithID(experienceChild.experienceID) {
                    experience.sequence = experienceChild.sequence
                    childExperiences.append(experience)
                }
            }

            return childExperiences
        }

        return nil
    }()

    open var numChildExperiences: Int {
        return (childExperiences?.count ?? 0)
    }

    open var video: Video? {
        if let presentations = audioVisual?.playableSequence?.presentations, presentations.count > 0 {
            return presentations.last!.video
        }

        return audioVisual?.presentation?.video
    }

    open lazy var location: AppDataItemLocation? = { [unowned self] in
        return CPEXMLSuite.current?.appData?.locationWithID(self.app?.id)
    }()

    open var locationMediaCount: Int {
        return (location?.mediaCount ?? 0)
    }

    open lazy var product: AppDataItemProduct? = { [unowned self] in
        return CPEXMLSuite.current?.appData?.productWithID(self.app?.id)
    }()

    open lazy var productCategories: [ProductCategory]? = { [unowned self] in
        var productCategories: [ProductCategory]?
        if let childExperiences = self.childExperiences {
            for childExperience in childExperiences {
                if let category = childExperience.product?.category {
                    if productCategories == nil {
                        productCategories = [ProductCategory]()
                    }

                    if !productCategories!.contains(where: { $0.id == category.id }) {
                        productCategories!.append(category)
                    }
                }
            }
        }

        return productCategories
    }()

    open lazy var timedEventSequence: TimedEventSequence? = { [unowned self] in
        return CPEXMLSuite.current?.manifest.timedEventSequenceWithID(self.timedEventSequenceID)
    }()

    open lazy var isMainExperience: Bool = { [unowned self] in
        return (self.audioVisual?.type == .main)
    }()

    open lazy var isInMovieExperience: Bool = { [unowned self] in
        return (CPEXMLSuite.current?.manifest.inMovieExperience == self)
    }()

    open lazy var isOutOfMovieExperience: Bool = { [unowned self] in
        return (CPEXMLSuite.current?.manifest.outOfMovieExperience == self)
    }()

    open lazy var isClipShareExperience: Bool = { [unowned self] in
        return ((self.audioVisual?.isClipShare ?? false) || self.id.contains("clipshare"))
    }()

    // Trackable
    open var analyticsID: String {
        return id
    }

    override init?(indexer: XMLIndexer) throws {
        // ExperienceID
        guard let id: String = indexer.value(ofAttribute: Attributes.ExperienceID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.ExperienceID, element: indexer.element)
        }

        self.id = id

        // Region / ExcludedRegion
        if let regionCode = CPEXMLSuite.Settings.countryCode {
            if indexer.hasElement(Elements.Region) {
                let supportedRegions: [String] = try indexer[Elements.Region].flatMap({ try $0[Elements.Country].value() })
                if !supportedRegions.contains(regionCode) {
                    print("Ignoring unsupported Experience object with ID \(id) and Regions \"\(supportedRegions.joined(separator: ", "))\"")
                    return nil
                }
            } else if indexer.hasElement(Elements.ExcludedRegion) {
                let unsupportedRegions: [String] = try indexer[Elements.ExcludedRegion].flatMap({ try $0[Elements.Country].value() })
                if unsupportedRegions.contains(regionCode) {
                    print("Ignoring unsupported Experience object with ID \(id) and ExcludedRegions \"\(unsupportedRegions.joined(separator: ", "))\"")
                    return nil
                }
            }
        }

        // AudioVisual
        if indexer.hasElement(Elements.AudioVisual) {
            audioVisual = try ExperienceAudioVisual(indexer: indexer[Elements.AudioVisual])
        }

        // Gallery
        if indexer.hasElement(Elements.Gallery) {
            gallery = try Gallery(indexer: indexer[Elements.Gallery])
        }

        // App
        if indexer.hasElement(Elements.App) {
            app = try ExperienceApp(indexer: indexer[Elements.App])
        }

        // TimedSequenceID
        timedEventSequenceID = try indexer[Elements.TimedSequenceID].value()

        // ExperienceChild
        experienceChildren = try indexer[Elements.ExperienceChild].value()

        // MetadataDriven
        try super.init(indexer: indexer)
    }

    // MARK: Helper Methods
    /**
        Check if Experience is of the specified type
     
        - Parameters:
            - type: Type of Experience
     
        - Returns: `true` if the Experience is of the specified type
     */
    // FIXME: Hardcoded Experience ID strings are being used to identify Experience types
    open func isType(_ type: ExperienceType) -> Bool {
        switch type {
        case .app:
            return (app != nil)

        case .audioVisual:
            return audioVisual != nil

        case .gallery:
            return (gallery != nil)

        case .location:
            if location != nil {
                return true
            }

            if let firstChildExperience = childExperiences?.first {
                return firstChildExperience.isType(.location)
            }

            return false

        case .product:
            if product != nil || (app != nil && app!.isProductApp) {
                return true
            }

            if let firstChildExperience = childExperiences?.first {
                return firstChildExperience.isType(.product)
            }

            return false
        }
    }

    /**
        Finds the Experience media associated with the AppData at the specified index
 
        - Parameters:
            - index: Media index to search
 
        - Returns: Associated Experience if it exists
    */
    open func locationMediaAtIndex(_ index: Int) -> Experience? {
        return location?.mediaAtIndex(index)
    }

    /**
        Finds the NodeStyle matching the current orientation and device
 
        - Parameters:
            - interfaceOrientation: Current device orientation
 
        - Returns: Current NodeStyle if it exists
    */
    open func getNodeStyle(_ interfaceOrientation: UIInterfaceOrientation) -> NodeStyle? {
        var tabletLandscapeNodeStyle: NodeStyle?
        var tabletPortraitNodeStyle: NodeStyle?
        var phoneLandscapeNodeStyle: NodeStyle?
        var phonePortraitNodeStyle: NodeStyle?

        if let nodeStyles = nodeStyles {
            for nodeStyle in nodeStyles {
                if nodeStyle.supportsTablet {
                    if nodeStyle.supportsLandscape {
                        tabletLandscapeNodeStyle = nodeStyle
                    } else if nodeStyle.supportsPortrait {
                        tabletPortraitNodeStyle = nodeStyle
                    }
                }

                if nodeStyle.supportsPhone {
                    if nodeStyle.supportsLandscape {
                        phoneLandscapeNodeStyle = nodeStyle
                    } else if nodeStyle.supportsPortrait {
                        phonePortraitNodeStyle = nodeStyle
                    }
                }
            }
        }

        let isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return (isLandscape ? (tabletLandscapeNodeStyle ?? tabletPortraitNodeStyle) : (tabletPortraitNodeStyle ?? tabletLandscapeNodeStyle))
        }

        return (isLandscape ? (phoneLandscapeNodeStyle ?? phonePortraitNodeStyle) : (phonePortraitNodeStyle ?? phoneLandscapeNodeStyle))
    }

    /**
        Finds the ExperienceChild at the given index
 
        - Parameters:
            - index: Child experience index to search
 
        - Returns: Child experience, if it exists
    */
    open func childExperience(atIndex index: Int) -> Experience? {
        if let childExperiences = childExperiences, childExperiences.count > index {
            return childExperiences[index]
        }

        return nil
    }

}
