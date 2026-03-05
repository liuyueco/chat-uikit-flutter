import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/gestured_image.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

typedef DoubleClickAnimationListener = void Function();

/// 单张图片的预览项，用于上下翻页画廊
class ImageGalleryItem {
  final ImageProvider imageProvider;
  final String heroTag;
  final String? messageID;
  final Future<void> Function()? downloadFn;

  const ImageGalleryItem({
    required this.imageProvider,
    required this.heroTag,
    this.messageID,
    this.downloadFn,
  });
}

/// 支持上下翻页的图片预览画廊
class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({
    required this.items,
    required this.initialIndex,
    Key? key,
  }) : super(key: key);

  final List<ImageGalleryItem> items;
  final int initialIndex;

  @override
  State<StatefulWidget> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends TIMUIKitState<ImageGalleryScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool isLoading = false;

  final Map<int, List<double>> _doubleTapScalesMap = {};
  late DoubleClickAnimationListener _doubleClickAnimationListener;
  late AnimationController _doubleClickAnimationController;
  Animation<double>? _doubleClickAnimation;

  final Map<int, GlobalKey<ExtendedImageGestureState>> _gestureKeys = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    for (int i = 0; i < widget.items.length; i++) {
      _gestureKeys[i] = GlobalKey<ExtendedImageGestureState>();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _doubleClickAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _doubleClickAnimationController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.pop(context);
  }

  Future<void> _onDownload(int index) async {
    final item = widget.items[index];
    if (item.downloadFn != null) {
      setState(() => isLoading = true);
      await item.downloadFn!();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    return OrientationBuilder(builder: ((context, orientation) {
      return Material(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 左右翻页的 PageView
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return _buildImagePage(index);
              },
            ),
            // 关闭按钮
            Positioned(
              left: 10,
              bottom: 50,
              child: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Image.asset(
                    'images/close.png',
                    package: 'tencent_cloud_chat_uikit',
                  ),
                  iconSize: 30,
                  onPressed: _close,
                ),
              ),
            ),
            // 下载按钮（仅当有下载回调时显示）
            if (widget.items.isNotEmpty &&
                widget.items[_currentIndex].downloadFn != null)
              Positioned(
                right: 10,
                bottom: 50,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: Image.asset(
                      'images/download.png',
                      package: 'tencent_cloud_chat_uikit',
                    ),
                    iconSize: 30,
                    onPressed: () => _onDownload(_currentIndex),
                  ),
                ),
              ),
            // 页码指示器
            if (widget.items.length > 1)
              Positioned(
                bottom: 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            if (isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Color(0xB22b2b2b),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    size: 35,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    }));
  }

  Widget _buildImagePage(int index) {
    final item = widget.items[index];
    _doubleTapScalesMap[index] ??= [1.0, 2.0];

    return GestureDetector(
      onTap: _close,
      child: ExtendedImage(
        image: item.imageProvider,
        extendedImageGestureKey: _gestureKeys[index],
        fit: BoxFit.contain,
        initGestureConfigHandler: (state) {
          return GestureConfig(
            minScale: 0.8,
            animationMinScale: 0.6,
            maxScale: 2.5,
            animationMaxScale: 3.0,
            speed: 1.0,
            inertialSpeed: 100.0,
            initialScale: 1.0,
            initialAlignment: InitialAlignment.center,
            hitTestBehavior: HitTestBehavior.opaque,
          );
        },
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            case LoadState.completed:
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              final imgHeight = state.extendedImageInfo?.image.height ?? 1;
              final imgWidth = state.extendedImageInfo?.image.width ?? 0;
              final imgRatio = imgWidth / imgHeight;
              final screenRatio = screenWidth / screenHeight;
              final fitWidthScale = screenRatio / imgRatio;
              final scales = _doubleTapScalesMap[index]!;
              if (screenRatio > imgRatio) {
                scales[1] = fitWidthScale;
              } else {
                scales[1] = 1 / fitWidthScale;
              }
              return GesturedImage(
                state,
                key: _gestureKeys[index],
              );
            case LoadState.failed:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      TIM_t("加载失败"),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
          }
          return null;
        },
        onDoubleTap: (ExtendedImageGestureState state) {
          final scales = _doubleTapScalesMap[index] ?? [1.0, 2.0];
          final pointerDownPosition = state.pointerDownPosition;
          final begin = state.gestureDetails!.totalScale;
          double end = begin == scales[0] ? scales[1] : scales[0];

          _doubleClickAnimation?.removeListener(_doubleClickAnimationListener);
          _doubleClickAnimationController.stop();
          _doubleClickAnimationController.reset();

          _doubleClickAnimationListener = () {
            state.handleDoubleTap(
              scale: _doubleClickAnimation!.value,
              doubleTapPosition: pointerDownPosition,
            );
          };
          _doubleClickAnimation = _doubleClickAnimationController.drive(
            Tween<double>(begin: begin, end: end),
          );
          _doubleClickAnimation!.addListener(_doubleClickAnimationListener);
          _doubleClickAnimationController.forward();
        },
        mode: ExtendedImageMode.gesture,
      ),
    );
  }
}
