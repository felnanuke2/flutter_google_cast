//
//  MediaInfoExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaInformation{
    
    
    static func fromMap(_ arguments: Dictionary<String, Any> ) -> GCKMediaInformation? {
        
        let contentID = arguments["contentID"] as! String
        let streamType = GCKMediaStreamType.unknown
       
        guard let  contentUrl = URL.init(string: arguments["contentURL"] as! String) else { return nil}
        
        
        let builder =  GCKMediaInformationBuilder.init()
        builder.contentID  = contentID
      
        builder.streamType = streamType
        builder.contentURL = contentUrl
        let buildedMediaInfo = builder.build()
    
        
        
        return buildedMediaInfo
    
    }
}
