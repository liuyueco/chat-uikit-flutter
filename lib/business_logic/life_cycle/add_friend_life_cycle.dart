import 'package:flutter/cupertino.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/base_life_cycle.dart';

class AddFriendLifeCycle {
  /// Before requesting to add a user as friend or a contact,
  /// `true` means can add continually, while `false` will not add.
  /// You can make a second confirmation here by a modal, etc.
  FutureBool Function(
      String userID, String? remark, String? friendGroup, String? addWording,
      [BuildContext? context]) shouldAddFriend;

  /// Custom search friend implementation
  /// Return null to use default search logic
  Future<List<V2TimUserFullInfo>?> searchFriend(String userID) async {
    return null;
  }

  AddFriendLifeCycle({
    this.shouldAddFriend = DefaultLifeCycle.defaultAddFriend,
  });
}
