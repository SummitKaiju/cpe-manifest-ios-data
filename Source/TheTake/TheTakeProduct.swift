//
//  TheTakeProduct.swift
//

import Foundation
import CoreGraphics

public class TheTakeProductCategory: ProductCategory {

    struct Keys {
        static let CategoryID = "categoryId"
        static let CategoryName = "categoryName"
        static let ChildCategories = "childCategories"
    }

    public var id: String
    public var name: String
    public var childCategories: [ProductCategory]?

    public init?(data: NSDictionary) {
        guard let id = (data[Keys.CategoryID] as? NSNumber)?.stringValue, let name = data[Keys.CategoryName] as? String else {
            print("Ignoring TheTake category with missing ID or name: \(data)")
            return nil
        }

        self.id = id
        self.name = name

        if let childCategories = data[Keys.ChildCategories] as? [NSDictionary] {
            self.childCategories = childCategories.flatMap({ return TheTakeProductCategory(data: $0) })
        }
    }

}

public class TheTakeProduct: ProductItem {

    private struct Constants {
        static let ProductURLPrefix = "https://thetake.com/product/"

        struct Keys {
            static let ProductId = "productId"
            static let ProductName = "productName"
            static let ProductBrand = "productBrand"
            static let ProductPrice = "productPrice"
            static let ProductImages = "productImages"
            static let ProductImage = "productImage"
            static let ProductImageThumbnail = "500pxLink"
            static let CropImages = "cropImages"
            static let CropImage = "cropImage"
            static let CropImageThumbnail = "500pxCropLink"
            static let KeyFrameImage = "keyFrameImage"
            static let KeyFrameImageThumbnail = "500pxKeyFrameLink"
            static let ExactMatch = "verified"
            static let PurchaseLink = "purchaseLink"
            static let BullseyeCropX = "keyCropProductX"
            static let BullseyeCropY = "keyCropProductY"
            static let BullseyeKeyFrameX = "keyFrameProductX"
            static let BullseyeKeyFrameY = "keyFrameProductY"
        }
    }

    public var id: String
    public var name: String
    public var brand: String?

    public var price: Double?
    open var displayPrice: String? {
        if let price = price {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: NSNumber(value: price))
        }

        return nil
    }

    public var productImageURL: URL?
    public var sceneImageURL: URL?
    public var hasExactMatchData = false
    public var isExactMatch = false
    public var externalURL: URL?
    public var bullseyePoint = CGPoint.zero
    open var shareText: String {
        var shareText = name
        if let externalURLString = externalURL?.absoluteString {
            shareText += " - " + externalURLString
        }

        return shareText
    }

    public init?(data: NSDictionary) {
        guard let id = (data[Constants.Keys.ProductId] as? String ?? (data[Constants.Keys.ProductId] as? NSNumber)?.stringValue), let name = data[Constants.Keys.ProductName] as? String else {
            print("Ignoring TheTake product with missing ID or name: \(data)")
            return nil
        }

        self.id = id
        self.name = name

        brand = data[Constants.Keys.ProductBrand] as? String

        if let priceString = data[Constants.Keys.ProductPrice] as? String {
            price = Double(priceString)
        }

        if let imagesData = (data[Constants.Keys.ProductImages] as? [String: String] ?? data[Constants.Keys.ProductImage] as? [String: String]), let imageString = imagesData[Constants.Keys.ProductImageThumbnail] {
            productImageURL = URL(string: imageString)
        }

        if let imagesData = data[Constants.Keys.KeyFrameImage] as? [String: String], let imageString = imagesData[Constants.Keys.KeyFrameImageThumbnail] {
            sceneImageURL = URL(string: imageString)

            if let x = data[Constants.Keys.BullseyeKeyFrameX] as? Double, let y = data[Constants.Keys.BullseyeKeyFrameY] as? Double {
                bullseyePoint = CGPoint(x: x, y: y)
            }
        } else if let imagesData = (data[Constants.Keys.KeyFrameImage] as? [String: String] ?? data[Constants.Keys.CropImages] as? [String: String] ?? data[Constants.Keys.CropImage] as? [String: String]), let imageString = imagesData[Constants.Keys.CropImageThumbnail] {
            sceneImageURL = URL(string: imageString)

            if let x = data[Constants.Keys.BullseyeCropX] as? Double, let y = data[Constants.Keys.BullseyeCropY] as? Double {
                bullseyePoint = CGPoint(x: x, y: y)
            }
        }

        if let verified = data[Constants.Keys.ExactMatch] as? Bool {
            isExactMatch = verified
            hasExactMatchData = true
        }

        if let purchaseLink = data[Constants.Keys.PurchaseLink] as? String, purchaseLink.count > 0 {
            externalURL = URL(string: purchaseLink)
        } else {
            externalURL = URL(string: Constants.ProductURLPrefix + id)
        }
    }

}
