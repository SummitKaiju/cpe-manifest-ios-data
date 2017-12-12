//
//  Presentation.swift
//

import Foundation
import SWXMLHash

open class Presentation {

    /// Supported XML attribute keys
    private struct Attributes {
        static let PresentationID = "PresentationID"
    }

    /// Supported XML element tags
    private struct Elements {
        static let TrackMetadata = "TrackMetadata"
        static let VideoTrackReference = "VideoTrackReference"
        static let VideoTrackID = "VideoTrackID"
        static let AudioTrackReference = "AudioTrackReference"
        static let AudioTrackID = "AudioTrackID"
    }

    /// Unique identifier
    public var id: String
    public var videoIDs: [String]?
    public var audioIDs: [String]?

    open var audio: Audio? {
        return CPEXMLSuite.current?.manifest.audioWithID(audioIDs?.first)
    }

    open var audioURL: URL? {
        return audio?.url
    }

    open var video: Video? {
        return CPEXMLSuite.current?.manifest.videoWithID(videoIDs?.first)
    }

    open var videoURL: URL? {
        return video?.url
    }

    init(indexer: XMLIndexer) throws {
        // PresentationID
        guard let id: String = indexer.value(ofAttribute: Attributes.PresentationID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.PresentationID, element: indexer.element)
        }

        self.id = id

        // TrackMetadata
        guard indexer.hasElement(Elements.TrackMetadata) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.TrackMetadata, element: indexer.element)
        }

        for indexer in indexer[Elements.TrackMetadata].all {
            // VideoTrackReference
            let videoIDs: [String] = try indexer[Elements.VideoTrackReference].all.flatMap({ try $0[Elements.VideoTrackID].value() })
            if videoIDs.count > 0 {
                if self.videoIDs == nil {
                    self.videoIDs = videoIDs
                } else {
                    self.videoIDs!.append(contentsOf: videoIDs)
                }
            }

            // AudioTrackReference
            let audioIDs: [String] = try indexer[Elements.AudioTrackReference].all.flatMap({ try $0[Elements.AudioTrackID].value() })
            if audioIDs.count > 0 {
                if self.audioIDs == nil {
                    self.audioIDs = audioIDs
                } else {
                    self.audioIDs!.append(contentsOf: audioIDs)
                }
            }
        }
    }

}
