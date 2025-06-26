import 'package:flutter/material.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/optimize_utils.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/pureUI/tim_uikit_search_input.dart';
import 'package:tencent_cloud_chat_uikit/theme/color.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';

class GroupMemberSearchTextField extends TIMUIKitStatelessWidget {
  final Function(String text) onTextChange;
  GroupMemberSearchTextField({Key? key, required this.onTextChange})
      : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final FocusNode focusNode = FocusNode();

    var debounceFunc = OptimizeUtils.debounce(
        (text) => onTextChange(text), const Duration(milliseconds: 300));

    return Container(
      child: Column(children: [
        if (!isDesktopScreen)
          Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                color: Colors.white,
                child: Container(
                  height: 36, // 明确设置高度
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Image.asset(
                        'images/icon_search.png',
                        package: 'tencent_cloud_chat_uikit',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          onChanged: debounceFunc,
                          cursorHeight: 16,
                          decoration: InputDecoration(
                            hintText: TIM_t("搜索"),
                            hintStyle: const TextStyle(
                                color: Color(0xFF999999), fontSize: 14),
                            border: InputBorder.none,
                            isDense: true, // 使文本更紧凑
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              )),
        if (isDesktopScreen)
          TIMUIKitSearchInput(
            prefixIcon: Icon(
              Icons.search,
              size: 16,
              color: hexToColor("979797"),
            ),
            onChange: (text) {
              focusNode.requestFocus();
              debounceFunc(text);
            },
            focusNode: focusNode,
          ),
        Divider(
            thickness: 1,
            indent: 74,
            endIndent: 0,
            color: theme.weakBackgroundColor,
            height: 0)
      ]),
    );
  }
}
