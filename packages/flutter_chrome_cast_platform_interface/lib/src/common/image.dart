/// Represents an image for Google Cast.
class GoogleCastImage {
  ///url 	URI 	URI for the image
  final Uri url;

  ///height 	integer 	optional Height of the image
  final int? height;

  ///width 	integer 	optional Width of the image
  final int? width;

  /// Creates a new [GoogleCastImage] instance.
  GoogleCastImage({required this.url, this.height, this.width});
}
