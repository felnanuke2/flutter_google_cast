import 'dart:convert';

import 'package:google_cast/common/queue_item.dart';
import 'package:google_cast/common/repeat_mode.dart';
export 'package:google_cast/common/queue_item.dart';
export 'package:google_cast/common/repeat_mode.dart';

class CastQueueData {
  final String? id;
  final String? name;
  final String? description;
  final QueueRepeatMode? repeatMode;

  /// if you will run LOAD command, you will
  ///  prefer put only one item
  /// in queue with id equals 0 and
  /// then you can use QUEUE_INSERT
  ///  command to add items to queue
  final List<CastQueueItem>? items;
  final int? startIndex;
  final Duration? startTime;
  CastQueueData({
    this.id,
    this.name,
    this.description,
    this.repeatMode,
    this.items,
    this.startIndex,
    this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'repeatMode': repeatMode?.name,
      'items': items?.map((x) => x.toMap()).toList(),
      'startIndex': startIndex,
      'startTime': startTime?.inSeconds,
    };
  }

  factory CastQueueData.fromMap(Map<String, dynamic> map) {
    return CastQueueData(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      repeatMode: map['repeatMode'] != null
          ? QueueRepeatMode.fromMap(map['repeatMode'])
          : null,
      items: map['items'] != null
          ? List<CastQueueItem>.from(
              map['items']?.map((x) => CastQueueItem.fromMap(x)))
          : null,
      startIndex: map['startIndex']?.toInt(),
      startTime: map['startTime'] != null
          ? Duration(seconds: map['startTime']?.toInt() ?? 0)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CastQueueData.fromJson(String source) =>
      CastQueueData.fromMap(json.decode(source));
}
