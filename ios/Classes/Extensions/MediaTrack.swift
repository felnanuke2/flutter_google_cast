//
//  MediaTrack.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 29/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaTrack {
    
    static func fromMap(_ args : Dictionary<String, Any> ) -> GCKMediaTrack{
        
        let identifier = args["trackId"] as? Int ?? 0
        let contentIdentifier = args["trackContentId"] as? String
        let contentType = args["trackContentType"] as? String ?? ""
        var trackType :  GCKMediaTrackType
        if let trackTypeInt = args["type"] as? Int {
            trackType = GCKMediaTrackType.init(rawValue: trackTypeInt) ?? .unknown
        }else {
            trackType = .unknown
        }
        
        var trackSubtype: GCKMediaTextTrackSubtype
        if let trackSubtypeInt = args["subtype"] as? Int {
            trackSubtype = GCKMediaTextTrackSubtype.init(rawValue: trackSubtypeInt) ?? .unknown
        }else {
            trackSubtype = .unknown
        }
        
        let name = args["name"] as? String
        let language = args["language"] as? String
        
        let mediaTrack = GCKMediaTrack.init(
            identifier: identifier,
            contentIdentifier: contentIdentifier,
            contentType: contentType,
            type: trackType,
            textSubtype: trackSubtype,
            name: name,
            languageCode: language,
            customData: nil)
        
       
     print("\(mediaTrack)")
        
        
        return mediaTrack!
    }
}
