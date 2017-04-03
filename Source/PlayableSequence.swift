//
//  PlayableSequence.swift
//

import Foundation
import SWXMLHash

open class PlayableSequence {

    private struct Attributes {
        static let PlayableSequenceID = "PlayableSequenceID"
    }

    private struct Elements {
        static let Clip = "Clip"
        static let PresentationID = "PresentationID"
    }

    var id: String
    var presentationIDs: [String]

    open lazy var presentations: [Presentation] = { [unowned self] in
        return self.presentationIDs.flatMap({ CPEXMLSuite.current?.manifest.presentationWithID($0) })
    }()

    init(indexer: XMLIndexer) throws {
        // PlayableSequenceID
        guard let id: String = indexer.value(ofAttribute: Attributes.PlayableSequenceID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.PlayableSequenceID, element: indexer.element)
        }

        self.id = id

        // Clip
        guard indexer.hasElement(Elements.Clip) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.Clip, element: indexer.element)
        }

        presentationIDs = try indexer[Elements.Clip].flatMap({ try $0[Elements.PresentationID].value() })
    }

}
