import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/models/game_category.dart';

class GameDetailPage extends StatefulWidget {
  const GameDetailPage({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  Offset _closeOffset = const Offset(20, 80);
  bool _restoredSystemUi = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    if (widget.launch.isLandscape) {
      unawaited(
        SystemChrome.setPreferredOrientations(<DeviceOrientation>[
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]),
      );
    }
  }

  @override
  void dispose() {
    _restoreSystemUi();
    unawaited(GameApi.exitGame(platformId: widget.launch.platformId));
    super.dispose();
  }

  void _restoreSystemUi() {
    if (_restoredSystemUi) return;
    _restoredSystemUi = true;
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
  }

  Future<void> _requestExit() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定退出游戏？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('再玩会'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (exit == true && mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_requestExit());
    },
    child: Scaffold(
      body: Stack(
        children: <Widget>[
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.launch.url)),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) {
              controller.addJavaScriptHandler(
                handlerName: 'android',
                callback: (_) {},
              );
            },
          ),
          Positioned(
            left: _closeOffset.dx,
            top: _closeOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) => setState(() {
                final size = MediaQuery.sizeOf(context);
                _closeOffset = Offset(
                  (_closeOffset.dx + details.delta.dx).clamp(
                    0,
                    size.width - 30,
                  ),
                  (_closeOffset.dy + details.delta.dy).clamp(
                    0,
                    size.height - 30,
                  ),
                );
              }),
              child: GestureDetector(
                onTap: () => unawaited(_requestExit()),
                child: Image.asset(
                  'assets/images/ic_game_close.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
