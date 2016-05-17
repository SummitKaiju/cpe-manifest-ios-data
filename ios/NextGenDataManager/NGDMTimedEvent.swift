//
//  NGDMTimedEvent.swift
//  NextGen
//
//  Created by Alec Ananian on 3/8/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import Foundation

enum TimedEventType {
    case AudioVisual
    case Gallery
    case AppGroup
    case TextItem
    case AppData
    case Location
    case Talent
    case Product
}

func ==(lhs: NGDMTimedEvent, rhs: NGDMTimedEvent) -> Bool {
    return lhs.id == rhs.id
}

// Wrapper class for `NGETimedEventType` Manifest object
class NGDMTimedEvent: Equatable {
    
    // MARK: Instance Variables
    /// Unique identifier
    var id: String = ""
    
    /// Timecodes
    var startTime: Double = -1
    var endTime: Double = -1
    
    /// Text value associated with this TimedEvent if it exists
    var text: String? {
        return textItem ?? appData?.location?.name
    }
    
    var descriptionText: String? {
        return gallery?.title ?? audioVisual?.metadata?.title ?? text ?? appData?.location?.name
    }
    
    /// Image to be used for display
    private var _imageURL: NSURL?
    var imageURL: NSURL? {
        return _imageURL ?? gallery?.imageURL ?? audioVisual?.imageURL ?? experienceApp?.imageURL
    }
    
    /// TimedEvent objects
    var textItem: String?
    var appGroup: NGDMAppGroup?
    var gallery: NGDMGallery?
    var audioVisual: NGDMAudioVisual?
    var experienceApp: NGDMExperienceApp?
    var productNamespace: String?
    
    private var _talentId: String?
    var talent: Talent? {
        if let id = _talentId {
            return CurrentManifest.mainExperience.talents[id]
        }
        
        return nil
    }
    
    private var _appDataId: String?
    var appData: NGDMAppData? {
        if let id = _appDataId {
            return CurrentManifest.allAppData?[id]
        }
        
        return nil
    }
    
    // MARK: Initialization
    /**
        Initializes a new NGETimedEventType
    
        - Parameters:
            - manifestObject: Raw Manifest data object
    */
    init(manifestObject: NGETimedEventType) {
        // Timecodes
        if let str = manifestObject.StartTimecode.value {
            startTime = Double(str)!
        }
        
        if let str = manifestObject.EndTimecode.value {
            endTime = Double(str)!
        }
        
        // FIXME: Making assumption that PictureID is in the Initialization property
        if let id = manifestObject.Initialization {
            _imageURL = NGDMPicture.getById(id)?.imageURL
        }
        
        // TimedEvent objects
        if let textGroupId = manifestObject.TextGroupIDList?.first, textGroupIndex = textGroupId.index, textGroup = NGDMTextGroup.getById(textGroupId.value!) {
            textItem = textGroup.textItem(textGroupIndex)
        }
        
        if let id = manifestObject.AppGroupID {
            appGroup = NGDMAppGroup.getById(id)
        }
        
        if let id = manifestObject.GalleryID {
            gallery = NGDMGallery.getById(id)
        }
        
        if let id = manifestObject.PresentationID {
            audioVisual = NGDMAudioVisual.getById(id)
        }
        
        if let id = manifestObject.AppGroupID {
            experienceApp = NGDMExperienceApp.getById(id)
        }
        
        productNamespace = manifestObject.ProductID?.Namespace
        _talentId = manifestObject.OtherID?.Identifier
        if let otherId = manifestObject.OtherID where otherId.Namespace == Namespaces.AppDataID {
            _appDataId = otherId.Identifier
        }
        
        id = audioVisual?.id ?? gallery?.id ?? appGroup?.id ?? appData?.id ?? NSUUID().UUIDString
    }
    
    // MARK: Helper Methods
    /**
        Check if TimedEvent is of the specified type
 
        - Parameters:
            - type: Type of TimedEvent
 
        - Returns: `true` if the TimedEvent is of the specified type
    */
    func isType(type: TimedEventType) -> Bool {
        switch type {
        case .AudioVisual:
            return audioVisual != nil
            
        case .Gallery:
            return gallery != nil
            
        case .TextItem:
            return textItem != nil
            
        case .AppGroup:
            return appGroup != nil
            
        case .AppData:
            return appData != nil
            
        case .Location:
            return appData?.location != nil
            
        case .Talent:
            return talent != nil

        case .Product:
            return productNamespace == kTheTakeIdentifierNamespace
        }
    }
    
}