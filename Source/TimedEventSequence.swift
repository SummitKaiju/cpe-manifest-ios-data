//
//  TimedEventSequence.swift
//

import Foundation
import SWXMLHash

/// A series of events tied to the playback of a `Presentation` or `PlayableSequence`
open class TimedEventSequence {

    /// Supported XML attribute keys
    private struct Attributes {
        static let TimedSequenceID = "TimedSequenceID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let PresentationID = "PresentationID"
        static let PlayableSequenceID = "PlayableSequenceID"
        static let TimedEvent = "TimedEvent"
    }

    /// Unique identifier
    public var id: String

    /// ID for associated `Presentation`
    public var presentationID: String?

    /// Associated `Presentation`
    open var presentation: Presentation? {
        return CPEXMLSuite.current?.manifest.presentationWithID(presentationID)
    }

    /// ID for associated `PlayableSequence`
    public var playableSequenceID: String?

    /// Associated `PlayableSequence`
    open var playableSequence: PlayableSequence? {
        return CPEXMLSuite.current?.manifest.playableSequenceWithID(playableSequenceID)
    }

    /// Series of `TimedEvents` tied to playback
    public var timedEvents: [TimedEvent]

    /**
         Initializes a new sequence of `TimedEvents` with the provided XML indexer
         
         - Parameter indexer: The root XML node
         - Throws:
            - `ManifestError.missingRequiredAttribute` if an expected XML attribute is not present
            - `ManiefstError.missingRequiredChildElement` if an expected XML element is not present
     */
    init(indexer: XMLIndexer) throws {
        // TimedSequenceID
        guard let id: String = indexer.value(ofAttribute: Attributes.TimedSequenceID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.TimedSequenceID, element: indexer.element)
        }

        self.id = id

        // PresentationID / PlayableSequenceID
        if indexer.hasElement(Elements.PresentationID) {
            presentationID = try indexer[Elements.PresentationID].value()
        } else if indexer.hasElement(Elements.PlayableSequenceID) {
            playableSequenceID = try indexer[Elements.PlayableSequenceID].value()
        } else {
            throw ManifestError.missingRequiredChildElement(name: "\(Elements.PresentationID) or \(Elements.PlayableSequenceID)", element: indexer.element)
        }

        // TimedEvent
        guard indexer.hasElement(Elements.TimedEvent) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.TimedEvent, element: indexer.element)
        }

        timedEvents = try indexer[Elements.TimedEvent].all.flatMap({ try TimedEvent(indexer: $0) })
    }

}
