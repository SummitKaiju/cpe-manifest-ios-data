//
//  AppGroup.swift
//

import Foundation
import SWXMLHash

public class AppGroup: MetadataDriven, Trackable {

    private struct Attributes {
        static let AppGroupID = "AppGroupID"
    }

    private struct Elements {
        static let InteractiveTrackReference = "InteractiveTrackReference"
        static let InteractiveTrackID = "InteractiveTrackID"
    }

    public var id: String
    public var interactiveTrackIDs: [String]

    open lazy var interactives: [Interactive]? = { [unowned self] in
        return self.interactiveTrackIDs.flatMap({ CPEXMLSuite.current?.manifest.interactiveWithID($0) })
    }()

    open var url: URL? {
        return interactives?.first?.url
    }

    public var isProductApp = false

    /// Tracking identifier
    open var analyticsID: String {
        return id
    }

    override init?(indexer: XMLIndexer) throws {
        // AppGroupID
        guard let id: String = indexer.value(ofAttribute: Attributes.AppGroupID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.AppGroupID, element: indexer.element)
        }

        self.id = id

        // InteractiveTrackReference
        guard indexer.hasElement(Elements.InteractiveTrackReference) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.InteractiveTrackReference, element: indexer.element)
        }

        interactiveTrackIDs = [String]()

        for indexer in indexer[Elements.InteractiveTrackReference].all {
            // InteractiveTrackID
            guard let id: String = try indexer[Elements.InteractiveTrackID].value() else {
                throw ManifestError.missingRequiredChildElement(name: Elements.InteractiveTrackID, element: indexer.element)
            }

            interactiveTrackIDs.append(id)
        }

        // MetadataDriven
        try super.init(indexer: indexer)
    }

}
