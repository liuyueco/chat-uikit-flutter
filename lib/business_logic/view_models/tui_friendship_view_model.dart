import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_application_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_response_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_application.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_application.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_operation_result.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_member_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_status.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_user_status.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/block_list_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/friend_list_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/new_contact_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/group/group_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TUIFriendShipViewModel extends ChangeNotifier {
  final FriendshipServices _friendshipServices = serviceLocator<FriendshipServices>();
  final GroupServices _groupServices = serviceLocator<GroupServices>();
  final MessageService _messageService = serviceLocator<MessageService>();
  final TUISelfInfoViewModel selfInfoViewModel = serviceLocator<TUISelfInfoViewModel>();
  late V2TimFriendshipListener friendShipListener;
  List<V2TimFriendApplication?>? _friendApplicationList;
  List<V2TimFriendInfo>? _friendList;
  List<V2TimGroupInfo>? _groupList;
  List<V2TimUserStatus>? _userStatusList;
  int _friendApplicationAmount = 0;
  List<V2TimFriendInfo>? _blockList;
  NewContactLifeCycle? _newContactLifeCycle;
  FriendListLifeCycle? _contactListLifeCycle;
  BlockListLifeCycle? _blockListLifeCycle;

  set newContactLifeCycle(NewContactLifeCycle? value) {
    _newContactLifeCycle = value;
  }

  set contactListLifeCycle(FriendListLifeCycle? value) {
    _contactListLifeCycle = value;
  }

  set blockListLifeCycle(BlockListLifeCycle? value) {
    _blockListLifeCycle = value;
  }

  set userStatusList(List<V2TimUserStatus> value) {
    _userStatusList = value;
    notifyListeners();
  }

  List<V2TimUserStatus> get userStatusList => _userStatusList ?? [];

  List<V2TimFriendInfo> get blockList {
    return _blockList ?? [];
  }

  List<V2TimGroupInfo> get groupList {
    return _groupList ?? [];
  }

  List<V2TimFriendInfo>? get friendList {
    return _friendList;
  }

  int get friendApplicationAmount => _friendApplicationAmount;

  List<V2TimFriendApplication?>? get friendApplicationList => _friendApplicationList;

  TUIFriendShipViewModel() {
    friendShipListener = V2TimFriendshipListener(
      onFriendApplicationListAdded: (applicationList) {
        loadContactApplicationData();
      },
      onFriendApplicationListDeleted: (userIDList) {
        loadContactApplicationData();
      },
      onFriendApplicationListRead: () {
        loadContactApplicationData();
      },
      onFriendInfoChanged: (infoList) {
        loadContactListData();
      },
      onFriendListAdded: (users) async {
        await loadContactListData();
        loadUserStatus();
        // 检查并发送待发送的验证消息
        await _checkAndSendPendingMessages(users);
      },
      onFriendListDeleted: (userList) async {
        await loadContactListData();
        loadUserStatus();
      },
      onBlackListAdd: (infoList) async {
        await loadBlockListData();
        loadUserStatus();
      },
      onBlackListDeleted: (userList) async {
        await loadBlockListData();
        loadUserStatus();
      },
    );
  }

  initFriendShipModel() {
    loadData();
  }

  loadData() async {
    loadContactApplicationData();
    loadBlockListData();
    await loadContactListData();
    loadUserStatus();
  }

  clearData() {
    _friendApplicationList = [];
    _friendApplicationAmount = 0;
    _friendList = [];
    _userStatusList = [];
    _blockList = [];
    notifyListeners();
  }

  loadUserStatus() async {
    if (selfInfoViewModel.globalConfig?.isShowOnlineStatus == false || friendList == null || friendList!.isEmpty) {
      return;
    }

    final List<List<String>> userIDSet = [];
    final int needHowManyRequest = ((friendList!.length) / 500).ceil();
    final int amountEachRequest = ((friendList!.length) / needHowManyRequest).ceil();

    for (int i = 0; i < needHowManyRequest; i++) {
      userIDSet.add(friendList!
          .getRange(i * amountEachRequest, min(friendList!.length, (i + 1) * amountEachRequest))
          .map((e) => e.userID)
          .toList());
    }

    final List<List<V2TimUserStatus>> userStatus = await Future.wait([
      ...userIDSet.map((userIDList) async {
        return await _friendshipServices.getUserStatus(userIDList: userIDList);
      })
    ]);

    final List<V2TimUserStatus> flatUserStatus = [];
    for (var e in userStatus) {
      flatUserStatus.addAll(e);
    }
    userStatusList = flatUserStatus;
  }

  loadContactApplicationData() async {
    final newContactRes = await _friendshipServices.getFriendApplicationList();
    // Only Received Application
    _friendApplicationList = newContactRes?.friendApplicationList
        ?.where((item) => item!.type == FriendApplicationTypeEnum.V2TIM_FRIEND_APPLICATION_COME_IN.index)
        .toList();
    _friendApplicationAmount = _friendApplicationList?.length ?? 0;
    notifyListeners();
  }

  Future<void> loadContactListData() async {
    final List<V2TimFriendInfo> res = await _friendshipServices.getFriendList() ?? [];
    final memberList = await _contactListLifeCycle?.friendListWillMount(res) ?? res;
    _friendList = memberList;
    notifyListeners();
    return;
  }

  Future<bool> isFriend(String userID) async {
    final List<V2TimFriendInfo> res = await _friendshipServices.getFriendList() ?? [];
    for (V2TimFriendInfo info in res) {
      if (info.userID == userID) {
        return true;
      }
    }

    return false;
  }

  Future<void> loadBlockListData() async {
    final blockListRes = await _friendshipServices.getBlackList();
    _blockList = blockListRes ?? [];
    notifyListeners();
    return;
  }

  loadGroupListData() async {
    final groupListRes = await _groupServices.getJoinedGroupList();
    _groupList = groupListRes ?? [];
    if (_groupList != null && _groupList!.isNotEmpty) {
      notifyListeners();
    }
    return;
  }

  Future<List<V2TimFriendOperationResult>?> deleteFromBlockList(List<String> userIDList) async {
    if (_blockListLifeCycle?.shouldDeleteFromBlockList != null &&
        await _blockListLifeCycle!.shouldDeleteFromBlockList(userIDList) == false) {
      return null;
    }
    final res = await _friendshipServices.deleteFromBlackList(userIDList: userIDList);
    if (res != null) {
      return res;
    }
    return null;
  }

  Future<V2TimFriendOperationResult?> acceptFriendApplication(
    String userID,
    int type,
  ) async {
    if (_newContactLifeCycle?.shouldAcceptContactApplication != null &&
        await _newContactLifeCycle!.shouldAcceptContactApplication(userID) == false) {
      return null;
    }
    final res = await _friendshipServices.acceptFriendApplication(
      responseType: FriendResponseTypeEnum.V2TIM_FRIEND_ACCEPT_AGREE_AND_ADD,
      type: FriendApplicationTypeEnum.values[type],
      userID: userID,
    );
    if (res != null) {
      return res;
    }
    return null;
  }

  Future<V2TimFriendOperationResult?> refuseFriendApplication(
    String userID,
    int type,
  ) async {
    if (_newContactLifeCycle?.shouldRefuseContactApplication != null &&
        await _newContactLifeCycle!.shouldRefuseContactApplication(userID) == false) {
      return null;
    }
    final res = await _friendshipServices.refuseFriendApplication(
      type: FriendApplicationTypeEnum.values[type],
      userID: userID,
    );
    if (res != null) {
      return res;
    }
    return null;
  }

  Future<List<V2TimGroupMemberFullInfo?>> getGroupMembersInfo(
      {required String groupID, required List<String> memberList}) async {
    final res = await _groupServices.getGroupMembersInfo(groupID: groupID, memberList: memberList);
    return res.data ?? [];
  }

  /// 检查并发送待发送的验证消息
  Future<void> _checkAndSendPendingMessages(List<V2TimFriendInfo> newFriends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingMessages = prefs.getStringList('pending_friend_messages') ?? [];
      
      if (pendingMessages.isEmpty) return;
      
      final List<String> messagesToRemove = [];
      
      for (final messageDataStr in pendingMessages) {
        final messageData = jsonDecode(messageDataStr);
        final String userID = messageData['userID'];
        final String message = messageData['message'];
        
        // 检查是否有新添加的好友匹配待发送消息
        final bool isFriendAdded = newFriends.any((friend) => friend.userID == userID);
        
        if (isFriendAdded) {
          // 发送验证消息
          await _sendVerificationMessage(userID, message);
          messagesToRemove.add(messageDataStr);
        }
      }
      
      // 移除已发送的消息
      if (messagesToRemove.isNotEmpty) {
        pendingMessages.removeWhere((item) => messagesToRemove.contains(item));
        await prefs.setStringList('pending_friend_messages', pendingMessages);
      }
    } catch (e) {
      print('检查并发送待发送消息时出错: $e');
    }
  }

  /// 发送验证消息给新添加的好友
  Future<void> _sendVerificationMessage(String userID, String message) async {
    try {
      // 创建文本消息
      final textMessageResult = await _messageService.createTextMessage(text: message);
      
      if (textMessageResult?.id != null) {
        // 发送消息
        await _messageService.sendMessage(
          id: textMessageResult!.id!,
          receiver: userID,
          groupID: '',
        );
        print('验证消息已发送给用户: $userID');
      }
    } catch (e) {
      print('发送验证消息失败: $e');
    }
  }

  addFriendListener({V2TimFriendshipListener? listener}) {
    _friendshipServices.addFriendListener(listener: friendShipListener);
  }

  removeFriendshipListener({V2TimFriendshipListener? listener}) {
    _friendshipServices.removeFriendListener(listener: friendShipListener);
  }
}
