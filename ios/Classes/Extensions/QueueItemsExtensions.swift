//
//  QueueItemsExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 30/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaQueueItem {
    static func fromMap(_ args : Dictionary<String, Any>) -> GCKMediaQueueItem {
        
        let activeTrackIds = args["activeTrackIds"] as? [NSNumber]
        let autoplay = args["autoplay"] as? Bool ?? true
        let mediaInformation  = GCKMediaInformation.fromMap(args[ "media"] as! Dictionary<String,Any>)
        let startTime = args["startTime"] as? TimeInterval ?? 0
        let preloadTime = args["preloadTime"] as?  TimeInterval ?? 0
        let customData = args["customData"] as? Dictionary<String,Any>
        
        let item = GCKMediaQueueItem.init(mediaInformation: mediaInformation!, autoplay: autoplay, startTime: startTime, preloadTime: preloadTime, activeTrackIDs: activeTrackIds, customData: customData)
        
        return item
        
    }
}
