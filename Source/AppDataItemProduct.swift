//
//  AppDataItemProduct.swift
//

import Foundation
import SWXMLHash

open class AppDataItemProductCategory: ProductCategory {

    public var metadata: Metadata

    public var id: String {
        return metadata.id
    }

    public var name: String {
        return metadata.title
    }

    required public init(metadata: Metadata) {
        self.metadata = metadata
    }

}

open class AppDataItemProduct: AppDataItem, ProductItem {

    public var externalURL: URL?

    open var name: String {
        return (title ?? "")
    }

    open var brand: String? {
        return description
    }

    open lazy var category: ProductCategory? = { [unowned self] in
        if let metadata = self.parentMetadata {
            return AppDataItemProductCategory(metadata: metadata)
        }

        return nil
    }()

    public var price: Double?
    public var currencyCode = "USD"
    open var displayPrice: String? {
        if let price = price {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            return formatter.string(from: NSNumber(value: price))
        }

        return nil
    }

    open var productImageURL: URL? {
        return thumbnailImageURL
    }

    public var productVideoPresentationID: String?
    public var productVideoContentID: String?

    open var productVideoURL: URL? {
        return CPEXMLSuite.current?.manifest.presentationWithID(productVideoPresentationID)?.videoURL
    }

    open var productVideoPreviewImageURL: URL? {
        return CPEXMLSuite.current?.manifest.metadataWithID(productVideoContentID)?.largeImageURL
    }

    public var sceneImagePictureID: String?
    open var sceneImageURL: URL? {
        return CPEXMLSuite.current?.manifest.pictureWithID(sceneImagePictureID)?.imageURL
    }

    public var isExactMatch = false
    public var hasExactMatchData = false
    public var bullseyePoint = CGPoint.zero
    open var shareText: String {
        var shareText = name
        if let externalURLString = externalURL?.absoluteString {
            shareText += " - " + externalURLString
        }

        return shareText
    }

    override init(indexer: XMLIndexer) throws {
        try super.init(indexer: indexer)

        var productImageBullseyeX: Double?
        var productImageBullseyeY: Double?
        var sceneImageBullseyeX: Double?
        var sceneImageBullseyeY: Double?

        for indexer in indexer[Elements.NVPair].all {
            // Name
            guard let name: String = indexer.value(ofAttribute: Attributes.Name) else {
                throw ManifestError.missingRequiredAttribute(Attributes.Name, element: indexer.element)
            }

            switch name {
            case AppDataNVPairName.ExternalURL:
                // URL
                guard let externalURLString: String = try indexer[Elements.URL].value(), let externalURL = URL(string: externalURLString) else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.URL, element: indexer.element)
                }

                self.externalURL = externalURL
                break

            case AppDataNVPairName.Price:
                // Money
                guard let price: Double = try indexer[Elements.Money].value() else {
                    throw ManifestError.missingRequiredChildElement(name: Elements.Money, element: indexer.element)
                }

                self.price = price
                currencyCode = (indexer[Elements.Money].value(ofAttribute: Attributes.Currency) ?? "USD")
                break

            case AppDataNVPairName.ExactMatch:
                isExactMatch = try indexer[Elements.Text].value()
                hasExactMatchData = true
                break

            case AppDataNVPairName.SceneImage:
                sceneImagePictureID = try indexer[Elements.PictureID].value()
                break

            case AppDataNVPairName.ProductVideo:
                productVideoPresentationID = try indexer[Elements.PresentationID].value()
                break

            case AppDataNVPairName.ProductVideoContentID:
                productVideoContentID = try indexer[Elements.ContentID].value()
                break

            case AppDataNVPairName.ProductImageBullseyeX:
                productImageBullseyeX = try indexer[Elements.Decimal].value()
                break

            case AppDataNVPairName.ProductImageBullseyeY:
                productImageBullseyeY = try indexer[Elements.Decimal].value()
                break

            case AppDataNVPairName.SceneImageBullseyeX:
                sceneImageBullseyeX = try indexer[Elements.Decimal].value()
                break

            case AppDataNVPairName.SceneImageBullseyeY:
                sceneImageBullseyeY = try indexer[Elements.Decimal].value()
                break

            default:
                break
            }
        }

        if sceneImagePictureID != nil, let x = sceneImageBullseyeX, let y = sceneImageBullseyeY {
            bullseyePoint = CGPoint(x: x, y: y)
        } else if let x = productImageBullseyeX, let y = productImageBullseyeY {
            bullseyePoint = CGPoint(x: x, y: y)
        }
    }

}
