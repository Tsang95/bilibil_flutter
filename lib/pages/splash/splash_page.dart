import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/stores/startup_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  late final StartupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<StartupController>();
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InkWell(onTap: () {}, child: const SizedBox.expand()),
      ),
    );
  }
}
