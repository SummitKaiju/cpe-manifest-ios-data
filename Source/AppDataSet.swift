//
//  AppDataSet.swift
//

import Foundation
import SWXMLHash

open class AppDataSet {

    private struct Attributes {
        static let Name = "Name"
        static let AppDataType = "type"
    }

    private struct Elements {
        static let ManifestAppData = "ManifestAppData"
        static let NVPair = "NVPair"
        static let Text = "Text"
    }

    private enum AppDataType: String {
        case product = "PRODUCT"
        case person = "PERSON"
        case location = "LOCATION"
    }

    // Inventory
    public var locations: [String: AppDataItemLocation]?
    public var products: [String: AppDataItemProduct]?
    public var people: [String: AppDataItem]?
    public var imageCache: [String: UIImage]?

    init(indexer: XMLIndexer) throws {
        // ManifestAppData
        guard indexer.hasElement(Elements.ManifestAppData) else {
            throw ManifestError.missingRequiredChildElement(name: Elements.ManifestAppData, element: indexer.element)
        }

        for indexer in indexer[Elements.ManifestAppData].all {
            if try indexer[Elements.NVPair].withAttribute(Attributes.Name, Attributes.AppDataType)[Elements.Text].value() == AppDataType.product.rawValue {
                if products == nil {
                    products = [String: AppDataItemProduct]()
                }

                let product = try AppDataItemProduct(indexer: indexer)
                products![product.id] = product
            } else if try indexer[Elements.NVPair].withAttribute(Attributes.Name, Attributes.AppDataType)[Elements.Text].value() == AppDataType.person.rawValue {
                if people == nil {
                    people = [String: AppDataItem]()
                }

                let person = try AppDataItem(indexer: indexer)
                people![person.id] = person
            } else {
                if locations == nil {
                    locations = [String: AppDataItemLocation]()
                }

                let location = try AppDataItemLocation(indexer: indexer)
                locations![location.id] = location
            }
        }
    }

    open func postProcess() {
        if let locations = locations {
            for location in Array(locations.values) {
                if let imageID = location.iconImageID, let url = CPEXMLSuite.current?.manifest.imageWithID(imageID)?.url {
                    _ = UIImageRemoteLoader.loadImage(url, completion: { [weak self] (image) in
                        if let strongSelf = self {
                            if strongSelf.imageCache == nil {
                                strongSelf.imageCache = [String: UIImage]()
                            }

                            strongSelf.imageCache![imageID] = image
                        }
                    })
                }
            }
        }

        if let appDataPeople = people {
            if let people = CPEXMLSuite.current?.manifest.people {
                for person in people {
                    if let appDataID = person.appDataID, let appDataItem = appDataPeople[appDataID] {
                        person.biographyHeader = appDataItem.descriptionHeader
                        person.biography = appDataItem.description
                        if let pictures = appDataItem.pictures {
                            person.pictureGroup = PictureGroup(pictures: pictures)
                        }

                        person.detailsLoaded = true
                    }
                }
            }

            self.people = nil
        }
    }

    open func cachedImageWithID(_ id: String?) -> UIImage? {
        return (id != nil ? imageCache?[id!] : nil)
    }

    open func locationWithID(_ id: String?) -> AppDataItemLocation? {
        return (id != nil ? locations?[id!] : nil)
    }

    open func productWithID(_ id: String?) -> AppDataItemProduct? {
        return (id != nil ? products?[id!] : nil)
    }

}
