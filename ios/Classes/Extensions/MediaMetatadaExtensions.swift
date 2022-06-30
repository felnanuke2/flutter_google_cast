//
//  MediaMetatadaExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 28/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaMetadata {
    func toMap() -> Dictionary<String,Any> {
        var dict = Dictionary<String,Any>()
        
//        for key in self.allKeys(){
//            let value = self.value(forKey: key)
//            dict[key] = value
//        }
  
//        let images = self.images() as! [GCKImage]
//     dict["images"] =  images.map{
//            image in
//            image.toMap()
//        }
        
      
        
        return dict
        
    }
    
    
    static func fromMap(_ imulatbleDict : Dictionary<String, Any >) ->  GCKMediaMetadata? {
        var mutableDict = imulatbleDict
       
        
       guard  let metadataType = GCKMediaMetadataType.init(rawValue: mutableDict["metadataType"] as! Int) else {
           return nil
           
       }
        mutableDict.removeValue(forKey: "metadataType")
        let metadata = GCKMediaMetadata.init(metadataType: metadataType)
        
        if let images = mutableDict["images"] as? [Dictionary<String, Any>] {
            for image in images {
                
                metadata.addImage(GCKImage.init(url: URL.init(string: image["url"] as! String)!, width: image["width"] as? Int ?? 0 , height: image["height"] as? Int ?? 0 ))
                
            }
        }
        
        mutableDict.removeValue(forKey: "images")
        
        
      
        for mapValue in mutableDict{
            switch mapValue.value {
            case is String:
                metadata.setString(mapValue.value as! String, forKey: mapValue.key)
                break
            case is Int:
                metadata.setInteger(mapValue.value as! Int, forKey: mapValue.key)
                break
            default:
                break
            }
            
            switch mapValue.key {
            case "broadcastDate":
                let  date = Date(timeIntervalSince1970:  mapValue.value as! TimeInterval / 1000)
                metadata.setDate(date, forKey: kGCKMetadataKeyBroadcastDate)
                break
            case "releaseDate":
                let  date = Date(timeIntervalSince1970:  mapValue.value as! TimeInterval / 1000)
                metadata.setDate(date, forKey: kGCKMetadataKeyReleaseDate)
                break
            case "creationDate":
                let  date = Date(timeIntervalSince1970:  mapValue.value as! TimeInterval / 1000)
                metadata.setDate(date, forKey: kGCKMetadataKeyCreationDate)
                
                break
            default:
                break
            }
            
        }

        
        return metadata
        
        
    }
}
