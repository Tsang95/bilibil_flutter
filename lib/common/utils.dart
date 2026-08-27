import 'package:flutter/material.dart';

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
