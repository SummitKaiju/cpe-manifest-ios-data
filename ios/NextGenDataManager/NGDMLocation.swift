//
//  NGDMLocation.swift
//  NextGen
//
//  Created by Alec Ananian on 3/15/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

// Wrapper class for `NGEEventLocationType` Manifest object
class NGDMLocation {
    
    // MARK: Instance Variables
    /// Reference to the root Manifest object
    private var _manifestObject: NGEEventLocationType!
    
    /// Name of this Location
    var name: String? {
        return _manifestObject.Name
    }
    
    /// Address of this Location
    var address: String? {
        return _manifestObject.Address
    }
    
    /// Latitude value for this Location's coordinates
    var latitude: Double {
        if let coordinates = _manifestObject.EarthCoordinate {
            return coordinates.Latitude
        }
        
        return 0
    }
    
    /// Longitude value for this Location's coordinates
    var longitude: Double {
        if let coordinates = _manifestObject.EarthCoordinate {
            return coordinates.Longitude
        }
        
        return 0
    }
    
    // MARK: Initialization
    /**
        Initializes a new NGETimedEventType
    
        - Parameters:
            - manifestObject: Raw Manifest data object
    */
    init(manifestObject: NGEEventLocationType) {
        _manifestObject = manifestObject
    }
    
}