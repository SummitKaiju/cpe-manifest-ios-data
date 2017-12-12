//
//  Metadata.swift
//

import Foundation
import SWXMLHash

/// A reference to an image URL and its resolution
public struct ArtReference {

    /// Supported XML attribute keys
    private struct Attributes {
        static let Resolution = "resolution"
    }

    /// Image file location
    public var imageURL: URL

    /// Image size
    public var size = CGSize.zero

    /**
        Initializes a new image URL and resolution reference with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws: `ManifestError.missingRequiredValue` if an expected XML value is not present
     */
    init(indexer: XMLIndexer) throws {
        // Resolution
        if let resolution: String = indexer.value(ofAttribute: Attributes.Resolution) {
            let sizeArr = resolution.components(separatedBy: "x")
            if sizeArr.count == 2, let width = Int(sizeArr[0]), let height = Int(sizeArr[1]) {
                size = CGSize(width: width, height: height)
            }
        }

        // Value
        guard let imageURLString: String = try indexer.value(), let imageURL = URL(string: imageURLString) else {
            throw ManifestError.missingRequiredValue(element: indexer.element)
        }

        self.imageURL = imageURL
    }

}

/// A collection of text and images describing a piece of content in a single language
open class LocalizedInfo {

    /// Supported XML attribute keys
    private struct Attributes {
        static let Language = "language"
        static let Default = "default"
    }

    /// Supported XML element tags
    private struct Elements {
        static let TitleDisplay19 = "TitleDisplay19"
        static let TitleDisplay60 = "TitleDisplay60"
        static let TitleDisplayUnlimited = "TitleDisplayUnlimited"
        static let TitleSort = "TitleSort"
        static let ArtReference = "ArtReference"
        static let Summary190 = "Summary190"
        static let Summary400 = "Summary400"
        static let Summary4000 = "Summary4000"
    }

    /// This collection's language code
    public var language: String

    /// True if this collection is the metadata's default language
    public var isDefault = false

    /// Title when limited to 19 characters
    public var titleShort: String?

    /// Title when limited to 60 characters
    public var titleMedium: String?

    /// Title when not limited by characters
    public var titleUnlimited: String?

    /// Title when sorting by title
    public var titleSortable: String

    /// Title used for display in app
    open var title: String {
        return (titleUnlimited ?? titleSortable)
    }

    /// Description when limited to 190 characters
    public var descriptionShort: String

    /// Description when limited to 400 characters
    public var descriptionMedium: String?

    /// Description when limited to 4000 characters
    public var descriptionLong: String?

    /// Description used for display in app
    open var description: String {
        return (descriptionLong ?? descriptionMedium ?? descriptionShort)
    }

    /// List of image references
    public var artReferences: [ArtReference]?

    /// Primary image URL
    open var imageURL: URL? {
        return artReferences?.first?.imageURL
    }

    /// Largest image URL provided; falls back to primary image URL
    open lazy var largeImageURL: URL? = { [unowned self] in
        return (self.artReferences?.sorted(by: { $0.size.width < $1.size.height }).last?.imageURL ?? self.imageURL)
    }()

    /**
        Initializes a new collection of metadata for a single language with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws: 
            - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
            - `ManifestError.missingRequiredChildElement` if an expected XML element is not present
     */
    init(indexer: XMLIndexer) throws {
        // Language
        guard let language: String = indexer.value(ofAttribute: Attributes.Language) else {
            throw ManifestError.missingRequiredAttribute(Attributes.Language, element: indexer.element)
        }

        self.language = language

        // Default
        isDefault = (indexer.value(ofAttribute: Attributes.Default) ?? false)

        // TitleDisplay19
        titleShort = try indexer[Elements.TitleDisplay19].value()

        // TitleDisplay60
        titleMedium = try indexer[Elements.TitleDisplay60].value()

        // TitleDisplayUnlimited
        titleUnlimited = try indexer[Elements.TitleDisplayUnlimited].value()

        // TitleSort
        guard let titleSortable: String = try indexer[Elements.TitleSort].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.TitleSort, element: indexer.element)
        }

        self.titleSortable = titleSortable

        // ArtReference
        if indexer.hasElement(Elements.ArtReference) {
            artReferences = try indexer[Elements.ArtReference].all.flatMap({ try ArtReference(indexer: $0) })
        }

        // Summary190
        guard let descriptionShort: String = try indexer[Elements.Summary190].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.Summary190, element: indexer.element)
        }

        self.descriptionShort = descriptionShort

        // Summary400
        descriptionMedium = try indexer[Elements.Summary400].value()

        // Summary4000
        descriptionLong = try indexer[Elements.Summary4000].value()
    }

}

/// A collection of text and images describing a piece of content in multiple languages
open class Metadata {

    /// Supported XML attribute keys
    private struct Attributes {
        static let ContentID = "ContentID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let BasicMetadata = "BasicMetadata"
        static let LocalizedInfo = "LocalizedInfo"
        static let AltIdentifier = "AltIdentifier"
        static let People = "People"
    }

    /// Unique identifier
    public var id: String

    /// List of `ContentIdentifier`s associated with this metadata
    public var contentIdentifiers: [ContentIdentifier]?

    /// List of locale-specific metadata objects
    public var localizedInfos: [LocalizedInfo]

    /// Ordered list of `Person` objects associated with this metadata
    public var people: [Person]?

    /// Look-up table of `Person` objects associated with this metadata
    public lazy var personMapping: [String: Person]? = { [unowned self] in
        if let people = self.people {
            var personMapping = [String: Person]()
            for person in people {
                personMapping[person.id] = person
            }

            return personMapping
        }

        return nil
    }()

    /// Metadata collection in the language marked as default
    open var defaultLocalizedInfo: LocalizedInfo {
        return (localizedInfos.first(where: { $0.isDefault }) ?? localizedInfos.first!)
    }

    /// Content title in the device's language
    open var title: String {
        return title(forLanguage: Locale.deviceLanguage)
    }

    /// Content description in the device's language
    open var description: String {
        return description(forLanguage: Locale.deviceLanguage)
    }

    /// Content image URL for the device's language
    open var imageURL: URL? {
        return imageURL(forLanguage: Locale.deviceLanguage)
    }

    /// Largest content image URL for the device's language
    open var largeImageURL: URL? {
        return largeImageURL(forLanguage: Locale.deviceLanguage)
    }

    /**
        Initializes a new collection of metadata for multiple languages with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws:
            - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
            - `ManifestError.missingRequiredChildElement` if an expected XML element is not present
     */
    init(indexer: XMLIndexer) throws {
        // ContentID
        guard let id: String = indexer.value(ofAttribute: Attributes.ContentID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.ContentID, element: indexer.element)
        }

        self.id = id

        // BasicMetadata
        guard indexer.hasElement(Elements.BasicMetadata) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.BasicMetadata, element: indexer.element)
        }

        let metadataIndexer = indexer[Elements.BasicMetadata]

        // LocalizedInfo
        guard metadataIndexer.hasElement(Elements.LocalizedInfo) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.LocalizedInfo, element: metadataIndexer.element)
        }

        localizedInfos = try metadataIndexer[Elements.LocalizedInfo].all.flatMap({ try LocalizedInfo(indexer: $0) })

        // AltIdentifier
        contentIdentifiers = try metadataIndexer[Elements.AltIdentifier].value()

        // People
        if metadataIndexer.hasElement(Elements.People) {
            people = try metadataIndexer[Elements.People].all.flatMap({ try Person(indexer: $0) }).sorted(by: { (person1, person2) -> Bool in
                return person1.billingBlockOrder < person2.billingBlockOrder
            })
        }
    }

    /**
        Fetches the `LocalizedInfo` object associated with the provided language
 
        - Parameter language: The desired language to find or blank for default
        - Returns: The `LocalizedInfo` object for the provided language; falls back to default language
    */
    private func localizedInfo(forLanguage language: String? = nil) -> LocalizedInfo {
        return (localizedInfos.first(where: { $0.language == language }) ?? defaultLocalizedInfo)
    }

    /**
        Fetches the title associated with the provided language
     
        - Parameter language: The desired language to find or blank for default
        - Returns: The title for the provided language; falls back to default language
     */
    private func title(forLanguage language: String? = nil) -> String {
        return localizedInfo(forLanguage: language).title
    }

    /**
        Fetches the description associated with the provided language
     
        - Parameter language: The desired language to find or blank for default
        - Returns: The description for the provided language; falls back to default language
     */
    private func description(forLanguage language: String? = nil) -> String {
        return localizedInfo(forLanguage: language).description
    }

    /**
        Fetches the image URL associated with the provided language
     
        - Parameter language: The desired language to find or blank for default
        - Returns: The image URL for the provided language; falls back to default language
     */
    private func imageURL(forLanguage language: String? = nil) -> URL? {
        return localizedInfo(forLanguage: language).imageURL
    }

    /**
        Fetches the largest image URL associated with the provided language
     
        - Parameter language: The desired language to find or blank for default
        - Returns: The largest image URL for the provided language; falls back to default language
     */
    private func largeImageURL(forLanguage language: String? = nil) -> URL? {
        return localizedInfo(forLanguage: language).largeImageURL
    }

    /**
        Fetches the identifier associated with the provided namespace
 
        - Parameter namespace: The desired identifier's namespace
        - Returns: The namespace's identifier if found
    */
    open func contentIdentifier(_ namespace: String) -> String? {
        return contentIdentifiers?.first(where: { $0.namespace == namespace })?.identifier
    }

    /**
        Fetches a `Person` associated with the provided identifier
 
        - Parameter id: The desired `Person`'s identifier
        - Returns: The `Person` if found
    */
    open func personWithID(_ id: String?) -> Person? {
        if let id = id {
            return personMapping?[id]
        }

        return nil
    }

}
