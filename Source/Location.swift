//
//  Location.swift
//

import Foundation
import SWXMLHash
import CoreLocation

/// World location point for display within interactive maps
open class Location {

    /// Supported XML attribute keys
    private struct Attributes {
        static let Icon = "icon"
    }

    /// Supported XML element tags
    private struct Elements {
        static let Name = "Name"
        static let Address = "Address"
        static let EarthCoordinate = "EarthCoordinate"
        static let Latitude = "Latitude"
        static let Longitude = "Longitude"
    }

    /// Display name
    public var name: String?

    /// Street address
    public var address: String?

    /// Latitude value
    public var latitude: Double = 0

    /// Longitude value
    public var longitude: Double = 0

    /// Latitude and longitude values specified as a point
    public var centerPoint: CLLocationCoordinate2D

    /// Unique identifier of map marker `Image`
    public var iconImageID: String?

    /// Image asset of map marker
    open var iconImage: UIImage? {
        return CPEXMLSuite.current?.appData?.cachedImageWithID(iconImageID)
    }

    /**
        Initializes a new location reference with the provided XML indexer
     
        - Parameter indexer: The root XML node
     */
    init(indexer: XMLIndexer) {
        do {
            // Icon
            iconImageID = indexer.value(ofAttribute: Attributes.Icon)

            // Name
            name = try indexer[Elements.Name].value()

            // Address
            address = try indexer[Elements.Address].value()

            // EarthCoordinate
            if indexer.hasElement(Elements.EarthCoordinate) {
                let coordinateIndexer = indexer[Elements.EarthCoordinate]
                latitude = (try coordinateIndexer[Elements.Latitude].value() ?? 0)
                longitude = (try coordinateIndexer[Elements.Longitude].value() ?? 0)
            }
        } catch {

        }

        // Custom
        centerPoint = CLLocationCoordinate2DMake(latitude, longitude)
    }

    /**
        Generates a URL for a static map of this location at the desired zoom level
     
        - Parameter zoomLevel: The desired zoom level of the static map
        - Returns: URL of the static map screenshot if the retailer has configured a Google Maps API key
     */
    open func mapImageURL(forZoomLevel zoomLevel: Int? = nil) -> URL? {
        if CPEXMLSuite.Settings.mapsAPIService == .googleMaps, let key = CPEXMLSuite.Settings.mapsAPIKey {
            var urlString = "https://maps.googleapis.com/maps/api/staticmap?"
            urlString += "center=\(latitude),\(longitude)"

            if let zoomLevel = zoomLevel {
                let zoomString = String(max(zoomLevel - 4, 1))
                urlString += "&zoom=\(zoomString)"
            }

            urlString += "&scale=2&size=480x270&maptype=roadmap&format=png&visual_refresh=true"
            urlString += "&key=\(key)"
            return URL(string: urlString)
        }

        return nil
    }

}
