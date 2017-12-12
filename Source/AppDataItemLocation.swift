//
//  AppDataItemLocation.swift
//

import Foundation
import SWXMLHash
import CoreLocation

open class AppDataItemLocation: AppDataItem {

    public var location: Location!
    public var zoomLevel: Int = 0
    public var zoomLocked = false

    open var name: String? {
        return location.name
    }

    open var address: String? {
        return location.address
    }

    open var centerPoint: CLLocationCoordinate2D {
        return location.centerPoint
    }

    override open var thumbnailImageURL: URL? {
        return (super.thumbnailImageURL ?? mapImageURL)
    }

    open var mapImageURL: URL? {
        return location.mapImageURL(forZoomLevel: zoomLevel)
    }

    open var iconImage: UIImage? {
        return location.iconImage
    }

    open var iconImageID: String? {
        return location.iconImageID
    }

    override init(indexer: XMLIndexer) throws {
        try super.init(indexer: indexer)

        for indexer in indexer[Elements.NVPair].all {
            // Name
            guard let name: String = indexer.value(ofAttribute: Attributes.Name) else {
                throw ManifestError.missingRequiredAttribute(Attributes.Name, element: indexer.element)
            }

            switch name {
            case AppDataNVPairName.Location:
                // LocationSet
                guard indexer.hasElement(Elements.LocationSet) else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.LocationSet, element: indexer.element)
                }

                // Location
                guard indexer[Elements.LocationSet].hasElement(Elements.Location) else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.Location, element: indexer[Elements.LocationSet].element)
                }

                location = Location(indexer: indexer[Elements.LocationSet][Elements.Location])
                break

            case AppDataNVPairName.Zoom:
                guard let zoomLevel: Int = try indexer[Elements.Integer].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.Integer, element: indexer.element)
                }

                self.zoomLevel = zoomLevel
                break

            case AppDataNVPairName.ZoomLocked:
                self.zoomLocked = try indexer.value()
                break

            default:
                break
            }
        }
    }

}
