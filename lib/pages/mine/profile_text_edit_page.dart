import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';

class ProfileTextEditArguments {
  const ProfileTextEditArguments({
    required this.title,
    required this.maxLength,
    this.initialValue = '',
  });

  final String title;
  final int maxLength;
  final String initialValue;
}

class ProfileTextEditPage extends StatefulWidget {
  const ProfileTextEditPage({super.key, required this.arguments});
  final ProfileTextEditArguments arguments;

  @override
  State<ProfileTextEditPage> createState() => _ProfileTextEditPageState();
}

class _ProfileTextEditPageState extends State<ProfileTextEditPage> {
  late final TextEditingController _input = TextEditingController(
    text: widget.arguments.initialValue,
  );

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_input.text);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: LegacyAppBar(title: widget.arguments.title),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 150,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _input,
                  maxLength: widget.arguments.maxLength,
                  maxLines: null,
                  expands: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: '说点什么吧',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _input,
                  builder: (_, value, _) => Text(
                    '${value.text.length}/${widget.arguments.maxLength}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LegacyActionButton(label: '保存', onPressed: _save),
        ],
      ),
    ),
  );
}
