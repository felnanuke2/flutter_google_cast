///VAST ad request configuration.
class VastAdsRequest {
  /// Specifies a VAST document to be used as
  /// the ads response instead of making a request
  /// via an ad tag URL. This can be useful for debugging
  /// and other situations where a VAST
  ///  response is already available.

  final String? adsResponse;

  /// URL for VAST file.

  final String? adTagUrl;

  /// Creates a new [VastAdsRequest] instance.
  ///
  /// [adsResponse] - Specifies a VAST document to be used as the ads response.
  /// [adTagUrl] - URL for VAST file.
  VastAdsRequest({
    this.adsResponse,
    this.adTagUrl,
  });
}
