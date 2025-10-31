import 'package:flutter/material.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/add_friend_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';
import 'package:tencent_cloud_chat_demo/utils/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SendApplication extends StatefulWidget {
  final V2TimUserFullInfo friendInfo;
  final TUISelfInfoViewModel model;
  final bool? isShowDefaultGroup;
  final AddFriendLifeCycle? lifeCycle;

  const SendApplication(
      {Key? key, this.lifeCycle, required this.friendInfo, required this.model, this.isShowDefaultGroup = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SendApplicationState();
}

class _SendApplicationState extends TIMUIKitState<SendApplication> {
  final TextEditingController _verficationController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final showName = widget.model.loginInfo?.nickName ?? widget.model.loginInfo?.userID;
    _verficationController.text = TIM_t_para("我是: {{option1}}", "我是: $showName")(option1: showName);
  }

  /// 保存待发送的验证消息
  Future<void> _savePendingMessage(String userID, String message) async {
    if (message.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final pendingMessages = prefs.getStringList('pending_friend_messages') ?? [];
    
    // 创建消息数据
    final messageData = jsonEncode({
      'userID': userID,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // 避免重复保存同一用户的消息
    pendingMessages.removeWhere((item) {
      final data = jsonDecode(item);
      return data['userID'] == userID;
    });
    
    pendingMessages.add(messageData);
    await prefs.setStringList('pending_friend_messages', pendingMessages);
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final FriendshipServices _friendshipServices = serviceLocator<FriendshipServices>();

    final faceUrl = widget.friendInfo.faceUrl ?? "";
    final userID = widget.friendInfo.userID ?? "";
    final String showName = ((widget.friendInfo.nickName != null && widget.friendInfo.nickName!.isNotEmpty)
            ? widget.friendInfo.nickName
            : userID) ??
        "";
    final option2 = widget.friendInfo.selfSignature ?? "";

    Widget sendApplicationBody() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(

              color: theme.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12, top: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 16),
                    child: Avatar(faceUrl: faceUrl, showName: showName, borderRadius: BorderRadius.all(Radius.circular(23))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showName,
                        style: TextStyle(color: theme.darkTextColor, fontSize: 14),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "ID: $userID",
                        style: TextStyle(fontSize: 13, color: theme.weakTextColor),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      if (TencentUtils.checkString(option2) != null)
                        Text(
                          TIM_t_para("个性签名: {{option2}}", "个性签名: $option2")(option2: option2),
                          style: TextStyle(fontSize: 13, color: theme.weakTextColor),
                        ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                TIM_t("填写验证信息"),
                style: TextStyle(fontSize: 12, color: theme.weakTextColor),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              color: theme.white,
              child: TextField(
                // minLines: 1,
                maxLines: 4,
                controller: _verficationController,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: theme.textgrey, fontSize: 14),
                  hintText: '',

                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                TIM_t("请填写备注"),
                style: TextStyle(fontSize: 12, color: theme.weakTextColor),
              ),
            ),
            Container(
              color: theme.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              margin: const EdgeInsets.only(top: 6),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TIM_t("备注"),
                    style: TextStyle(color: theme.darkTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(

                    child: TextField(
                      controller: _nickNameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: theme.textgrey,
                          fontSize: 14,
                        ),
                        hintText: '',
                      ),
                    ),
                  )
                ],
              ),
            ),
            if (widget.isShowDefaultGroup == true)
              Container(
                color: theme.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TIM_t("分组"),
                      style: TextStyle(color: theme.darkTextColor, fontSize: 16),
                    ),
                    Text(
                      TIM_t("我的好友"),
                      style: TextStyle(color: theme.darkTextColor, fontSize: 16),
                    )
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 100, left: 47, right: 47),
              decoration: BoxDecoration(
                color: const Color(0xff0072FC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                  onPressed: () async {
                    final remark = _nickNameController.text;
                    final addWording = _verficationController.text;
                    final friendGroup = TIM_t("我的好友");

                    if (widget.lifeCycle?.shouldAddFriend != null &&
                        await widget.lifeCycle!.shouldAddFriend(userID, remark, friendGroup, addWording, context) ==
                            false) {
                      return;
                    }
                    
                    // 保存验证消息，用于好友通过后自动发送
                    await _savePendingMessage(userID, addWording);
                    
                    ToastUtils.showLoading();
                    _friendshipServices.addFriend(
                        userID: userID,
                        addType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH,
                        remark: remark,
                        addWording: addWording,
                        friendGroup: friendGroup).then((res){
                              Navigator.pop(context);
                    }).whenComplete((){
                      ToastUtils.hideLoading();
                    });
                  },

                  child: Text(TIM_t("发送"), style: TextStyle(color: theme.white),)
                ),
            )
          ],
        ),
      );
    }

    return TUIKitScreenUtils.getDeviceWidget(
        context: context,

        desktopWidget: Container(
          padding: const EdgeInsets.only(top: 10),
          color: theme.weakBackgroundColor,
          child: sendApplicationBody(),
        ),
        defaultWidget: Scaffold(

          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: theme.appbarTextColor),
              onPressed: () {
                Navigator.pop(context); // 返回上一个页面
              },
            ),

            title: Text(
              TIM_t("添加好友"),
              style: TextStyle(color: theme.appbarTextColor, fontSize: 16),
            ),
            shadowColor: theme.white,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            iconTheme: IconThemeData(
              color: theme.appbarTextColor,
            ),
          ),
          body: sendApplicationBody(),
        ));
  }
}
