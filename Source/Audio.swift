//
//  Audio.swift
//

import Foundation
import SWXMLHash

public enum AudioType: String {
    case primary                            // primary audio track. There may be multiple primary tracks, with one for each language
    case commentary                         // Commentary on the video
}

private enum AudioCodec: String {
    case aac            = "AAC"             // Advanced audio CODEC
    case aacLC          = "AAC-LC"
    case aacLCMPS       = "AAC-LC+MPS"
    case aacSLS         = "AAC-SLS"
    case mp3            = "MP3"             // MPEG 1 Layer 3
    case wav            = "WAV"             // used when specific CODEC (e.g., PCM) is unknown or not listed
}

private class AudioEncoding: DigitalAssetEncoding {

    private struct Elements {
        static let Codec = "Codec"
        static let SampleRate = "SampleRate"
        static let SampleBitDepth = "SampleBitDepth"
        static let ChannelMapping = "ChannelMapping"
    }

    var codec: AudioCodec
    var sampleRate: Int?
    var sampleBitDepth: Int?
    var channelMapping: String?

    override init?(indexer: XMLIndexer) throws {
        // Codec
        if let codecString: String = try indexer[Elements.Codec].value() {
            guard let codec = AudioCodec(rawValue: codecString) else {
                print("Ignoring unsupported Audio Encoding object with Codec \"\(codecString)\"")
                return nil
            }

            self.codec = codec
        } else {
            codec = .wav
        }

        // SampleRate
        sampleRate = try indexer[Elements.SampleRate].value()

        // SampleBitDepth
        sampleBitDepth = try indexer[Elements.SampleBitDepth].value()

        // ChannelMapping
        channelMapping = try indexer[Elements.ChannelMapping].value()

        // DigitalAssetEncoding
        try super.init(indexer: indexer)
    }

}

open class Audio: DigitalAsset {

    private struct Attributes {
        static let AudioTrackID = "AudioTrackID"
        static let Dubbed = "dubbed"
    }

    private struct Elements {
        static let AudioType = "Type"
        static let Encoding = "Encoding"
        static let Language = "Language"
        static let Channels = "Channels"
    }

    var id: String
    var type: AudioType
    private var encoding: AudioEncoding?
    var isDubbed = false
    var channels: String?

    open var isCommentary: Bool {
        return isType(.commentary)
    }

    override init?(indexer: XMLIndexer) throws {
        // AudioTrackID
        guard let id: String = indexer.value(ofAttribute: Attributes.AudioTrackID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.AudioTrackID, element: indexer.element)
        }

        self.id = id

        // Type
        if let typeString: String = try indexer[Elements.AudioType].value() {
            guard let type = AudioType(rawValue: typeString) else {
                print("Ignoring unsupported Audio object with Type \"\(typeString)\"")
                return nil
            }

            self.type = type
        } else {
            type = .primary
        }

        // Encoding
        if indexer.hasElement(Elements.Encoding) {
            encoding = try AudioEncoding(indexer: indexer[Elements.Encoding])
        }

        // Language
        isDubbed = (indexer[Elements.Language].value(ofAttribute: Attributes.Dubbed) ?? false)

        // Channels
        channels = try indexer[Elements.Channels].value()

        // DigitalAsset
        try super.init(indexer: indexer)
    }

    // MARK: Helper Methods
    /**
        Check if Audio is of the specified type
     
        - Parameters:
            - type: Type of Audio
     
        - Returns: `true` if the Audio is of the specified type
     */
    open func isType(_ type: AudioType) -> Bool {
        return (type == self.type)
    }

}
