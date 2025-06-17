import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/add_friend_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/core_services_implements.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitAddFriend/tim_uikit_send_application.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';

class TIMUIKitAddFriend extends StatefulWidget {
  final bool? isShowDefaultGroup;

  /// You may navigate to user profile page, if friendship relationship exists.
  final Function(String userID) onTapAlreadyFriendsItem;

  /// The life cycle hooks for adding friends and contact business logic
  final AddFriendLifeCycle? lifeCycle;

  /// The callback function to close the widget upon completion by the parent component.
  final VoidCallback? closeFunc;

  const TIMUIKitAddFriend(
      {Key? key,
      this.isShowDefaultGroup = false,
      this.lifeCycle,
      required this.onTapAlreadyFriendsItem,
      this.closeFunc})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitAddFriendState();
}

class _TIMUIKitAddFriendState extends TIMUIKitState<TIMUIKitAddFriend> {
  final TextEditingController _controller = TextEditingController();
  final CoreServicesImpl _coreServicesImpl = serviceLocator<CoreServicesImpl>();
  final FriendshipServices _friendshipServices =
      serviceLocator<FriendshipServices>();
  final TUISelfInfoViewModel _selfInfoViewModel =
      serviceLocator<TUISelfInfoViewModel>();
  final FocusNode _focusNode = FocusNode();
  bool isFocused = false;
  bool showResult = false;
  List<V2TimUserFullInfo>? searchResult;

  Widget _searchResultItemBuilder(
      V2TimUserFullInfo friendInfo, TUITheme theme) {
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    final faceUrl = friendInfo.faceUrl ?? "";
    final userID = friendInfo.userID ?? "";
    final String showName =
        ((friendInfo.nickName != null && friendInfo.nickName!.isNotEmpty)
                ? friendInfo.nickName
                : userID) ??
            "";
    return InkWell(
      onTap: () async {
        final checkFriend = await _friendshipServices.checkFriend(
            userIDList: [userID],
            checkType: FriendTypeEnum.V2TIM_FRIEND_TYPE_SINGLE);
        if (checkFriend != null) {
          final res = checkFriend.first;
          if (res.resultCode == 0 && res.resultType != 0) {
            widget.onTapAlreadyFriendsItem(userID);
            return;
          }
        }

        if (userID == _selfInfoViewModel.loginInfo?.userID) {
          widget.onTapAlreadyFriendsItem(userID);
          return;
        }

        if (isDesktopScreen) {
          if (widget.closeFunc != null) {
            widget.closeFunc!();
          }
          TUIKitWidePopup.showPopupWindow(
            operationKey: TUIKitWideModalOperationKey.addFriend,
            context: context,
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.width * 0.4,
            title: TIM_t("添加好友"),
            child: (closeFuncSendApplication) => SendApplication(
                lifeCycle: widget.lifeCycle,
                isShowDefaultGroup: widget.isShowDefaultGroup ?? false,
                friendInfo: friendInfo,
                model: _selfInfoViewModel),
          );
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => SendApplication(
                      lifeCycle: widget.lifeCycle,
                      isShowDefaultGroup: widget.isShowDefaultGroup ?? false,
                      friendInfo: friendInfo,
                      model: _selfInfoViewModel)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.white,
        child: Row(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isDesktopScreen ? 38 : 46,
              height: isDesktopScreen ? 38 : 46,
              margin: const EdgeInsets.only(right: 16),
              child: Avatar(faceUrl: faceUrl, showName: showName, borderRadius: BorderRadius.all(Radius.circular(23))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showName,
                  style: TextStyle(
                      color: Color(0xff333333),
                      fontWeight: FontWeight.w500,
                      fontSize: isDesktopScreen ? 16 : 14),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "ID: $userID",
                  style: TextStyle(fontSize: 12, color: Color(0xffBBBBBB)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _searchResultBuilder(
      List<V2TimUserFullInfo>? searchResult, TUITheme theme) {
    final noResult = searchResult == null || searchResult.isEmpty;
    if (noResult) {
      return [
        Container(
          margin: const EdgeInsets.only(top: 20),
          child: Center(
            child: Text(TIM_t("该用户不存在"),
                style: TextStyle(color: theme.weakTextColor, fontSize: 14)),
          ),
        )
      ];
    }
    return searchResult.map((e) => _searchResultItemBuilder(e, theme)).toList();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      final _isFocused = _focusNode.hasFocus;
      isFocused = _isFocused;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  searchFriend(String params) async {
    final response = await _coreServicesImpl.getUsersInfo(userIDList: [params]);
    if (response.code == 0) {
      setState(() {
        searchResult = response.data;
      });
    } else {
      setState(() {
        searchResult = null;
      });
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _selfInfoViewModel),
      ],
      builder: (BuildContext context, Widget? w) {
        return Column(
          children: [
            Container(
              height: 50,
              color: Colors.white,
              padding:
                  const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    autofocus: true,
                    focusNode: _focusNode,
                    controller: _controller,
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        setState(() {
                          showResult = false;
                        });
                      }
                    },
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      final searchParams = _controller.text;
                      if (searchParams.trim().isNotEmpty) {
                        searchFriend(searchParams);
                        showResult = true;
                        _focusNode.requestFocus();
                        setState(() {});
                      }
                    },
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        fillColor: const Color(0xffF5F5F5), // 设置背景颜色
                        filled: true,
                        prefixIcon: Icon(
                          Icons.search_outlined,
                          color: theme.weakTextColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        hintStyle: TextStyle(
                          color: theme.weakTextColor,
                        ),
                        hintText: TIM_t("搜索用户 ID")),
                  )),
                  const SizedBox(
                    width: 8,
                  ),
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() {
                        _controller.text = "";
                        showResult = false;
                      });
                    },
                    child: const Text("取消"),
                  ),
                ],
              ),
            ),
            if (showResult)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(top: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _searchResultBuilder(searchResult, theme),
                    ),
                  ),
                ),
              )
          ],
        );
      },
    );
  }
}
