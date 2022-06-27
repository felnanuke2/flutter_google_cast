import 'dart:convert';

class CastImage {
  ///url 	URI 	URI for the image
  final Uri url;

  ///height 	integer 	optional Height of the image
  final int? height;

  ///width 	integer 	optional Width of the image
  final int? width;
  CastImage({
    required this.url,
    this.height,
    this.width,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url.toString(),
      'height': height,
      'width': width,
    };
  }

  factory CastImage.fromMap(Map<String, dynamic> map) {
    return CastImage(
      url: Uri.parse(map['url']),
      height: map['height']?.toInt(),
      width: map['width']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CastImage.fromJson(String source) =>
      CastImage.fromMap(json.decode(source));
}
