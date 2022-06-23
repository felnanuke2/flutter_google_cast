//
//  FlutterGoogleCastOption.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 23/06/22.
//

import Foundation
import GoogleCast

class FlutterGoogleCastOptions : GCKCastOptions {
    
}


extension  FlutterGoogleCastContext{
    
    static func fromMap(_ map : [String : Any]) ->  GCKCastOptions {
        
        let discoveryCriteriaData : [String : Any] = map["discoveryCriteria"] as! [String : Any]
        var discoveryCriteria: GCKDiscoveryCriteria?
        let discoveryCriteriaInitializeMethod = discoveryCriteriaData["method"] as! String
        
 
        switch discoveryCriteriaInitializeMethod {
        case "initWithApplicationID":
            discoveryCriteria = GCKDiscoveryCriteria.init(applicationID: discoveryCriteriaData["applicationID"] as! String)
            
            
            
            break;
        case "initWithNamespaces":
            discoveryCriteria = GCKDiscoveryCriteria.init(namespaces: discoveryCriteriaData["namespaces"] as! Set<String> )
            
        default:
            break
        }
        
        
        
        
        let option =  GCKCastOptions.init(
            discoveryCriteria: discoveryCriteria!)
        
        
       
        
      if  var physicalVolumeButtonsWillControlDeviceVolume = map["physicalVolumeButtonsWillControlDeviceVolume"]  as? Bool {
          option.physicalVolumeButtonsWillControlDeviceVolume = physicalVolumeButtonsWillControlDeviceVolume
      }
     
        
        
        
        return option
    }
    
    
    
    
    
}





