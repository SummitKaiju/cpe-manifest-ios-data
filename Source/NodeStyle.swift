//
//  NodeStyle.swift
//

import Foundation
import SWXMLHash

/**
    Method to use when scaling the background media to the device's display
 
    - bestFit: Scale the image to the display so the image fills the display and is fully displayed along one axis
    - full: Scale the image to ensure the entire image is visible
    - tiled: Image is tiled
 */
public enum BackgroundScaleMethod: String {
    case bestFit = "BestFit"
    case full = "Full"
    case tiled = "Tiled"
}

/**
    Method to use when positioning the background media on the device's display
 
    - upperLeft: Position the upper left corner of the image in the upper left corner of the screen
    - upperRight: Same as upperleft, but positioned at the upper right
    - lowerLeft: Same as upperleft, but positioned at the lower left
    - lowerRight: Same as upperleft, but positioned at the lower right
    - centered: The center point of the image is at the center point of the screen
 */
public enum BackgroundPositioningMethod: String {
    case upperLeft = "upperleft"
    case upperRight = "upperright"
    case lowerLeft = "lowerleft"
    case lowerRight = "lowerright"
    case centered = "centered"
}

/**
    Supported `OverlayArea` types
 
    - button: Area for positioning and sizing buttons
    - title: Area for positioning and sizing title treatment
 */
public enum OverlayAreaType: String {
    case button = "button"
    case title = "title"
}

/// An area within the device's display to be used to position and size UI elements
public struct OverlayArea {

    /// Supported XML element tags
    private struct Elements {
        static let WidthPixels = "WidthPixels"
        static let HeightPixels = "HeightPixels"
        static let PixelsFromLeft = "PixelsFromLeft"
        static let PixelsFromBottom = "PixelsFromBottom"
    }

    /// Area's size in pixels relative to the background image (or background video, if no image is specified)
    public var size: CGSize

    /// Area's bottom left-hand point in pixels relative to the background image (or background video, if no image is specified)
    public var bottomLeftPoint: CGPoint

    /**
        Initializes a UI element area with the provided XML indexer
     
        - Parameter indexer: The root XML node
        - Throws:
            - `ManifestError.missingRequiredChildElement` if an expected XML element is not present
     */
    init(indexer: XMLIndexer) throws {
        // WidthPixels
        guard let width: Int = try indexer[Elements.WidthPixels].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.WidthPixels, element: indexer.element)
        }

        // HeightPixels
        guard let height: Int = try indexer[Elements.HeightPixels].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.HeightPixels, element: indexer.element)
        }

        // PixelsFromLeft
        guard let pixelsFromLeft: Int = try indexer[Elements.PixelsFromLeft].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.PixelsFromLeft, element: indexer.element)
        }

        // PixelsFromBottom
        guard let pixelsFromBottom: Int = try indexer[Elements.PixelsFromBottom].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.PixelsFromBottom, element: indexer.element)
        }

        size = CGSize(width: width, height: height)
        bottomLeftPoint = CGPoint(x: pixelsFromLeft, y: pixelsFromBottom)
    }

}

open class NodeStyle {

    /// Supported XML attribute keys
    private struct Attributes {
        static let NodeStyleID = "NodeStyleID"
        static let Looping = "looping"
        static let Tag = "tag"
    }

    /// Supported XML element tags
    private struct Elements {
        static let ThemeID = "ThemeID"
        static let Background = "Background"
        static let Color = "Color"
        static let Adaptation = "Adaptation"
        static let ScaleMethod = "ScaleMethod"
        static let PositioningMethod = "PositioningMethod"
        static let Video = "Video"
        static let PresentationID = "PresentationID"
        static let LoopTimecode = "LoopTimecode"
        static let Image = "Image"
        static let PictureGroupID = "PictureGroupID"
        static let AudioLoop = "AudioLoop"
        static let AudioTrackID = "AudioTrackID"
        static let OverlayArea = "OverlayArea"
    }

    /// Unique identifier
    public var id: String

    /// Flag for if this `NodeStyle` supports devices in landscape mode
    public var supportsLandscape = false

    /// Flag for if this `NodeStyle` supports devices in portrait mode
    public var supportsPortrait = false

    /// Flag for if this `NodeStyle` supports tablets
    public var supportsTablet = false

    /// Flag for if this `NodeStyle` supports phones
    public var supportsPhone = false

    /// ID for associated `Theme`
    public var themeID: String

    /// Associated `Theme` that defines UI elements such as buttons
    open var theme: Theme {
        return (CPEXMLSuite.current?.cpeStyle?.themeWithID(themeID))!
    }

    /// Color to use on UI behind any background videos or images
    public var backgroundColor = UIColor.black

    /// Scale method to use to match the device's display
    public var backgroundScaleMethod = BackgroundScaleMethod.bestFit

    /// Positioning method to use to match the device's display
    public var backgroundPositioningMethod = BackgroundPositioningMethod.centered

    /// Background image
    public var backgroundImagePictureGroupID: String?
    open var backgroundImage: Image? {
        return CPEXMLSuite.current?.manifest.pictureGroupWithID(backgroundImagePictureGroupID)?.pictures.first?.image
    }

    /// Background video
    public var backgroundPresentationID: String?
    open var backgroundPresentation: Presentation? {
        return CPEXMLSuite.current?.manifest.presentationWithID(backgroundPresentationID)
    }

    open var backgroundVideo: Video? {
        return backgroundPresentation?.video
    }

    public var backgroundVideoLoops = false
    public var backgroundVideoLoopTimecode = 0.0

    /// Background audio
    public var backgroundAudioID: String?
    open var backgroundAudio: Audio? {
        return CPEXMLSuite.current?.manifest.audioWithID(backgroundAudioID)
    }

    // Overlays
    public var buttonOverlayArea: OverlayArea?
    public var titleOverlayArea: OverlayArea?

    init(indexer: XMLIndexer) throws {
        // NodeStyleID
        guard let id: String = indexer.value(ofAttribute: Attributes.NodeStyleID) else {
            throw ManifestError.missingRequiredAttribute(Attributes.NodeStyleID, element: indexer.element)
        }

        self.id = id

        // ThemeID
        guard let themeID: String = try indexer[Elements.ThemeID].value() else {
            throw ManifestError.missingRequiredChildElement(name: Elements.ThemeID, element: indexer.element)
        }

        self.themeID = themeID

        // Background
        if indexer.hasElement(Elements.Background) {
            let backgroundIndexer = indexer[Elements.Background]

            // Looping
            backgroundVideoLoops = (backgroundIndexer.value(ofAttribute: Attributes.Looping) ?? false)

            // Color
            if let colorString: String = try backgroundIndexer[Elements.Color].value() {
                backgroundColor = UIColor(hexString: colorString)
            }

            // Adaption
            if backgroundIndexer.hasElement(Elements.Adaptation) {
                // ScaleMethod
                if let string: String = try backgroundIndexer[Elements.Adaptation][Elements.ScaleMethod].value(), let scaleMethod = BackgroundScaleMethod(rawValue: string) {
                    backgroundScaleMethod = scaleMethod
                }

                // PositioningMethod
                if let string: String = try backgroundIndexer[Elements.Adaptation][Elements.PositioningMethod].value(), let positioningMethod = BackgroundPositioningMethod(rawValue: string) {
                    backgroundPositioningMethod = positioningMethod
                }
            }

            // Video
            if backgroundIndexer.hasElement(Elements.Video) {
                // PresentationID
                guard let presentationID: String = try backgroundIndexer[Elements.Video][Elements.PresentationID].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.PresentationID, element: backgroundIndexer[Elements.Video].element)
                }

                backgroundPresentationID = presentationID

                // LoopTimecode
                backgroundVideoLoopTimecode = (try backgroundIndexer[Elements.Video][Elements.LoopTimecode].value() ?? 0)
            }

            // Image
            if backgroundIndexer.hasElement(Elements.Image) {
                // PictureGroupID
                guard let pictureGroupID: String = try backgroundIndexer[Elements.Image][Elements.PictureGroupID].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.PictureGroupID, element: backgroundIndexer[Elements.Image].element)
                }

                backgroundImagePictureGroupID = pictureGroupID
            }

            // AudioLoop
            if backgroundIndexer.hasElement(Elements.AudioLoop) {
                // AudioTrackID
                guard let audioID: String = try backgroundIndexer[Elements.AudioLoop][Elements.AudioTrackID].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.AudioTrackID, element: backgroundIndexer[Elements.AudioLoop].element)
                }

                backgroundAudioID = audioID
            }

            // OverlayArea
            if backgroundIndexer.hasElement(Elements.OverlayArea) {
                for overlayIndexer in backgroundIndexer[Elements.OverlayArea].all {
                    // Type
                    guard let type: String = overlayIndexer.value(ofAttribute: Attributes.Tag) else {
                        throw ManifestError.missingRequiredAttribute(Attributes.Tag, element: overlayIndexer.element)
                    }

                    if type.lowercased() == OverlayAreaType.button.rawValue {
                        buttonOverlayArea = try OverlayArea(indexer: overlayIndexer)
                    } else if type.lowercased() == OverlayAreaType.title.rawValue {
                        titleOverlayArea = try OverlayArea(indexer: overlayIndexer)
                    }
                }
            }
        }
    }

}
