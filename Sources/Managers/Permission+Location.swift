//
//  Permission+Location.swift
//  ┌─┐      ┌───────┐ ┌───────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ │      │ └─────┐ │ └─────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ └─────┐│ └─────┐ │ └─────┐
//  └───────┘└───────┘ └───────┘
//
//  Created by lee on 2019/6/3.
//  Copyright © 2019年 lee. All rights reserved.
//

import CoreLocation

extension Permission {
    
    public static func location(_ type: Location) -> Provider {
        return .init(LocationManager(type))
    }
}

public enum Location {
    case whenInUse
    case alwaysAndWhenInUse
}

struct LocationManager: Permissionable {
    
    private static var delegate: LocationDelegate?
    
    private let type: Location
    
    init(_ type: Location) {
        self.type = type
    }
    
    var status: Permission.Status {
        guard CLLocationManager.locationServicesEnabled() else {
            return .disabled
        }
        
        switch _status {
        case .authorizedAlways:     return .authorized
        case .authorizedWhenInUse:  return type == .whenInUse ? .authorized : .denied
        case .denied:               return .denied
        case .restricted:           return .disabled
        case .notDetermined:        return .notDetermined
        @unknown default:           return .invalid
        }
    }
    
    var name: String { return "Location" }
    
    var usageDescriptions: [String] {
        switch type {
        case .whenInUse:
            return ["NSLocationUsageDescription",
                    "NSLocationWhenInUseUsageDescription"]
        case .alwaysAndWhenInUse:
            return ["NSLocationAlwaysUsageDescription",
                    "NSLocationAlwaysAndWhenInUseUsageDescription"]
        }
    }
    
    private var _status: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    func request(_ сompletion: @escaping () -> Void) {
        guard status == .notDetermined else {
            сompletion()
            return
        }
        let delegate = LocationDelegate(type) {
            LocationManager.delegate = nil
            сompletion()
        }
        LocationManager.delegate = delegate
    }
}

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    let manager = CLLocationManager()
    let type: Location
    let сompletion: () -> Void
    
    init(_ type: Location, _ сompletion: @escaping () -> Void) {
        self.type = type
        self.сompletion = сompletion
        super.init()
        
        manager.delegate = self
        
        switch type {
        case .whenInUse:
            manager.requestWhenInUseAuthorization()
            
        case .alwaysAndWhenInUse:
            manager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .notDetermined else {
            return
        }
        
        self.сompletion()
    }
    
    deinit {
        manager.delegate = nil
    }
}
