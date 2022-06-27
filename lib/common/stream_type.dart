/// Describes the type of media artifact as one of the following:

///     NONE
///     BUFFERED
///     LIVE

enum CastStreamType {
  none('NONE'),
  buffered('BUFFERED'),
  live('LIVE');

  final String value;
  const CastStreamType(this.value);
}
