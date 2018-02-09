//
//  Person.swift
//

import Foundation
import SWXMLHash

public enum SocialAccountType: String {
    case unknown = "UNKNOWN"
    case facebook = "FACEBOOK"
    case twitter = "TWITTER"
    case instagram = "INSTAGRAM"
}

public struct Film {

    var id: String
    public var title: String
    public var imageURL: URL?

    public init(id: String, title: String, imageURL: URL? = nil) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
    }

}

public struct SocialAccount {

    public var type = SocialAccountType.unknown
    public var handle: String
    public var url: URL?

    public init(handle: String, urlString: String) {
        self.handle = handle

        if urlString.contains("twitter") {
            type = .twitter
        } else if urlString.contains("facebook") {
            type = .facebook
        } else if urlString.contains("instagram") {
            type = .instagram
        }

        url = URL(string: urlString)
    }

}

public enum PersonJobFunction: String {
    case actor = "Actor"
    case keyCharacter = "Key Character"
    case director = "Director"
    case producer = "Producer"
    case writer = "Writer"

    public static func build(rawValue: String?) -> PersonJobFunction {
        if let rawValue = rawValue, let jobFunction = PersonJobFunction(rawValue: rawValue) {
            return jobFunction
        }

        return .actor
    }
}

extension PersonJobFunction: Comparable {
    
    public static func < (lhs: PersonJobFunction, rhs: PersonJobFunction) -> Bool {
        return (lhs.rawValue < rhs.rawValue)
    }
    
}

public struct PersonJob {

    private struct Elements {
        static let JobFunction = "JobFunction"
        static let BillingBlockOrder = "BillingBlockOrder"
        static let Character = "Character"
    }

    public var function: PersonJobFunction
    public var billingBlockOrder: Int = 0
    public var characters: [String]?

    init(function: PersonJobFunction = .actor, billingBlockOrder: Int = 0, character: String? = nil) {
        self.function = function
        self.billingBlockOrder = billingBlockOrder
        if let character = character {
            characters = [character]
        }
    }

    init(indexer: XMLIndexer) throws {
        // JobFunction
        guard let functionString: String = try indexer[Elements.JobFunction].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.JobFunction, element: indexer.element)
        }

        function = PersonJobFunction.build(rawValue: functionString)

        // BillingBlockOrder
        if let billingBlockOrder: Int = try indexer[Elements.BillingBlockOrder].value() {
            self.billingBlockOrder = billingBlockOrder
        }

        // Character
        characters = try indexer[Elements.Character].value()
    }

}

open class Person: Trackable {

    private struct Elements {
        static let Job = "Job"
        static let Name = "Name"
        static let DisplayName = "DisplayName"
        static let Identifier = "Identifier"
    }

    public var jobs: [PersonJob]?
    public var name: String
    public var contentIdentifiers: [ContentIdentifier]?
    public var biographyHeader: String?
    public var biography: String?
    public var pictureGroup: PictureGroup?
    public var socialAccounts: [SocialAccount]?
    public var films: [Film]?

    open var id: String {
        return (personID ?? apiID)!
    }

    private var customAPIID: String?
    open var apiID: String? {
        if let apiID = customAPIID {
            return apiID
        }

        if let talentAPIUtil = CPEXMLSuite.Settings.talentAPIUtil {
            let apiNamespace = type(of: talentAPIUtil).APINamespace
            return contentIdentifiers?.first(where: { $0.namespace == apiNamespace })?.identifier
        }

        return nil
    }

    open lazy var personID: String? = { [unowned self] in
        return self.contentIdentifiers?.first(where: { $0.namespace == Namespaces.PeopleID })?.identifier
    }()

    open lazy var appDataID: String? = { [unowned self] in
        return self.contentIdentifiers?.first(where: { $0.namespace == Namespaces.AppDataID })?.identifier
    }()

    open var character: String? {
        return jobs?.first?.characters?.first
    }
    
    open var jobFunction: PersonJobFunction? {
        return jobs?.first?.function
    }

    open var billingBlockOrder: Int {
        return (jobs?.first?.billingBlockOrder ?? 0)
    }

    open var thumbnailImageURL: URL? {
        return pictureGroup?.thumbnailImageURL
    }

    open var largeImageURL: URL? {
        return pictureGroup?.picture(atIndex: 0)?.imageURL
    }

    open lazy var gallery: Gallery? = { [unowned self] in
        guard let pictureGroup = self.pictureGroup else {
            return nil
        }

        return Gallery(pictureGroup: pictureGroup)
    }()

    public var detailsLoaded = false

    /// Tracking identifier
    open var analyticsID: String {
        return id
    }

    public init(apiID: String, name: String, jobFunction: PersonJobFunction = .actor, billingBlockOrder: Int = 0, character: String? = nil) {
        self.customAPIID = apiID
        self.name = name
        if let character = character {
            jobs = [PersonJob(function: jobFunction, billingBlockOrder: billingBlockOrder, character: character)]
        }
    }

    init(indexer: XMLIndexer) throws {
        // Job
        guard indexer.hasElement(Elements.Job) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.Job, element: indexer.element)
        }

        jobs = try indexer[Elements.Job].all.flatMap({ try PersonJob(indexer: $0) })

        // Name
        guard let name: String = try indexer[Elements.Name][Elements.DisplayName].value() else {
            throw ManifestError.missingRequiredChildElement(name: "\(Elements.Name).\(Elements.DisplayName)", element: indexer.element)
        }

        self.name = name

        // Identifier
        contentIdentifiers = try indexer[Elements.Identifier].value()
    }

    open func getTalentDetails(_ successBlock: @escaping (_ biography: String?, _ socialAccounts: [SocialAccount]?, _ films: [Film]?) -> Void) {
        if detailsLoaded {
            successBlock(biography, socialAccounts, films)
        } else if let talentAPIUtil = CPEXMLSuite.Settings.talentAPIUtil, let id = apiID {
            talentAPIUtil.fetchDetails(forPersonID: id, completionHandler: { [weak self] (biography, socialAccounts, films) in
                self?.biography = biography
                self?.socialAccounts = socialAccounts
                self?.films = films
                self?.detailsLoaded = true
                successBlock(biography, socialAccounts, films)
            })
        } else {
            successBlock(biography, socialAccounts, films)
            detailsLoaded = true
        }
    }

}

extension Person: Equatable {
    
    public static func == (lhs: Person, rhs: Person) -> Bool {
        return (lhs.id == rhs.id)
    }
    
}

extension Person: Comparable {
    
    public static func < (lhs: Person, rhs: Person) -> Bool {
        return (lhs.billingBlockOrder < rhs.billingBlockOrder)
    }
    
}
