import 'package:flutter/material.dart';

class ScrollToTopNavigatorObserver extends NavigatorObserver {
  final ValueNotifier<Route<dynamic>?> currentRoute =
      ValueNotifier<Route<dynamic>?>(null);

  void _update(Route<dynamic>? route) {
    if (!identical(currentRoute.value, route)) currentRoute.value = route;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (identical(currentRoute.value, route)) _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _update(newRoute);
  }
}

final ScrollToTopNavigatorObserver appScrollToTopNavigatorObserver =
    ScrollToTopNavigatorObserver();

class ScrollToTopLayer extends StatefulWidget {
  const ScrollToTopLayer({
    super.key,
    required this.child,
    required this.navigatorObserver,
    this.showOffset = 600,
  });

  final Widget child;
  final ScrollToTopNavigatorObserver navigatorObserver;
  final double showOffset;

  @override
  State<ScrollToTopLayer> createState() => _ScrollToTopLayerState();
}

class _ScrollToTopLayerState extends State<ScrollToTopLayer> {
  final Map<Route<dynamic>, ScrollableState> _routeTargets =
      <Route<dynamic>, ScrollableState>{};
  bool _visible = false;
  bool _routeSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.navigatorObserver.currentRoute.addListener(_scheduleRouteSync);
  }

  @override
  void didUpdateWidget(covariant ScrollToTopLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigatorObserver != widget.navigatorObserver) {
      oldWidget.navigatorObserver.currentRoute.removeListener(
        _scheduleRouteSync,
      );
      widget.navigatorObserver.currentRoute.addListener(_scheduleRouteSync);
      _scheduleRouteSync();
    }
  }

  void _scheduleRouteSync() {
    if (_routeSyncScheduled) return;
    _routeSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeSyncScheduled = false;
      if (mounted) _syncCurrentRoute();
    });
  }

  void _syncCurrentRoute() {
    final route = widget.navigatorObserver.currentRoute.value;
    _routeTargets.removeWhere(
      (candidate, _) => !candidate.isActive && !identical(candidate, route),
    );
    final target = route == null ? null : _routeTargets[route];
    _setVisible(_shouldShowFor(target));
  }

  bool _shouldShowFor(ScrollableState? target) {
    if (target == null || !target.mounted) return false;
    final position = target.position;
    return position.hasPixels &&
        position.axisDirection == AxisDirection.down &&
        position.maxScrollExtent > widget.showOffset &&
        position.pixels - position.minScrollExtent >= widget.showOffset;
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axisDirection != AxisDirection.down) return false;
    final notificationContext = notification.context;
    if (notificationContext == null) return false;
    final route = ModalRoute.of(notificationContext);
    final scrollable = Scrollable.maybeOf(notificationContext);
    if (route == null || scrollable == null) return false;
    _routeTargets[route] = scrollable;
    if (identical(route, widget.navigatorObserver.currentRoute.value)) {
      _setVisible(
        notification.metrics.maxScrollExtent > widget.showOffset &&
            notification.metrics.extentBefore >= widget.showOffset,
      );
    }
    return false;
  }

  void _setVisible(bool visible) {
    if (_visible == visible || !mounted) return;
    setState(() => _visible = visible);
  }

  Future<void> _scrollToTop() async {
    final route = widget.navigatorObserver.currentRoute.value;
    final target = route == null ? null : _routeTargets[route];
    if (target == null || !target.mounted) {
      _setVisible(false);
      return;
    }
    final position = target.position;
    final milliseconds = (position.pixels.abs() / 4).round().clamp(300, 700);
    await position.animateTo(
      position.minScrollExtent,
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    widget.navigatorObserver.currentRoute.removeListener(_scheduleRouteSync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final bottomInset = mediaQuery == null
        ? 0.0
        : mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom
        : mediaQuery.padding.bottom;
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          Positioned(
            right: 16,
            bottom: bottomInset + 156,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _visible
                  ? Semantics(
                      key: const ValueKey<String>(
                        'global_scroll_to_top_button',
                      ),
                      button: true,
                      label: '返回顶部',
                      child: SizedBox.square(
                        dimension: 42,
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 3,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _scrollToTop,
                            customBorder: const CircleBorder(),
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 25,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey<String>('global_scroll_to_top_hidden'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class KeyboardFocusDismissLayer extends StatefulWidget {
  const KeyboardFocusDismissLayer({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardFocusDismissLayer> createState() =>
      _KeyboardFocusDismissLayerState();
}

class _KeyboardFocusDismissLayerState extends State<KeyboardFocusDismissLayer>
    with WidgetsBindingObserver {
  bool _keyboardWasVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keyboardWasVisible = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final keyboardVisible = View.of(context).viewInsets.bottom > 0;
    final keyboardClosed = _keyboardWasVisible && !keyboardVisible;
    _keyboardWasVisible = keyboardVisible;
    if (keyboardClosed) FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handlePointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;
    final renderObject = focus.context?.findRenderObject();
    if (renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      final localPosition = renderObject.globalToLocal(event.position);
      if ((Offset.zero & renderObject.size).contains(localPosition)) return;
    }
    focus.unfocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: widget.child,
    );
  }
}

void dismissKeyboard(BuildContext context) {
  final focusScope = FocusScope.of(context);
  if (!focusScope.hasPrimaryFocus) focusScope.unfocus();
}

Widget dismissKeyboardWrapper(BuildContext context, Widget child) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => dismissKeyboard(context),
    child: child,
  );
}
