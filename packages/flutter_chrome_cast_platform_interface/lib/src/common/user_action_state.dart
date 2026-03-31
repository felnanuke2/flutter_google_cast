import 'package:flutter_chrome_cast_platform_interface/src/common/user_action.dart';

/// Represents the state of a user action in a cast session.
class UserActionState {
  ///User actions custom data.
  final Map<String, dynamic>? customData;

  /// The user action associated with this state.
  final UserAction? userAction;

  /// Creates a new [UserActionState] instance.
  ///
  /// [customData] - Custom data associated with the user action.
  /// [userAction] - The user action.
  UserActionState({this.customData, this.userAction});
}
