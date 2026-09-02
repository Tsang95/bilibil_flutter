import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import 'package:b_flutter/common/styles.dart';

const _birthdayCalendarBlue = Color(0xFF2F9BFF);
const _birthdayCalendarBackground = Color(0xFFFFFBFF);

Future<DateTime?> showBirthdayCalendarPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => BirthdayCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class BirthdayCalendarDialog extends StatefulWidget {
  const BirthdayCalendarDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<BirthdayCalendarDialog> createState() => _BirthdayCalendarDialogState();
}

class _BirthdayCalendarDialogState extends State<BirthdayCalendarDialog> {
  static const _weekdays = <String>['一', '二', '三', '四', '五', '六', '日'];

  late final DateTime _firstDate;
  late final DateTime _lastDate;
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late int _yearPageStart;
  bool _showYearPicker = false;

  @override
  void initState() {
    super.initState();
    _firstDate = DateUtils.dateOnly(widget.firstDate);
    _lastDate = DateUtils.dateOnly(widget.lastDate);
    assert(!_lastDate.isBefore(_firstDate));
    final requestedDate = DateUtils.dateOnly(widget.initialDate);
    _selectedDate = requestedDate.isBefore(_firstDate)
        ? _firstDate
        : requestedDate.isAfter(_lastDate)
            ? _lastDate
            : requestedDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _yearPageStart = _yearPageFor(_displayedMonth.year);
  }

  static int _yearPageFor(int year) => year - (year % 12);

  bool get _canGoToPreviousMonth {
    final previous = DateTime(
      _displayedMonth.year,
      _displayedMonth.month - 1,
    );
    return !previous.isBefore(DateTime(_firstDate.year, _firstDate.month));
  }

  bool get _canGoToNextMonth {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    return !next.isAfter(DateTime(_lastDate.year, _lastDate.month));
  }

  void _changeMonth(int offset) {
    if (offset < 0 && !_canGoToPreviousMonth) return;
    if (offset > 0 && !_canGoToNextMonth) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
      _yearPageStart = _yearPageFor(_displayedMonth.year);
    });
  }

  void _changeYearPage(int offset) {
    final nextStart = _yearPageStart + offset * 12;
    final firstPage = _yearPageFor(_firstDate.year);
    final lastPage = _yearPageFor(_lastDate.year);
    if (nextStart < firstPage || nextStart > lastPage) return;
    setState(() => _yearPageStart = nextStart);
  }

  void _selectYear(int year) {
    if (year < _firstDate.year || year > _lastDate.year) return;
    var month = _displayedMonth.month;
    if (year == _firstDate.year && month < _firstDate.month) {
      month = _firstDate.month;
    }
    if (year == _lastDate.year && month > _lastDate.month) {
      month = _lastDate.month;
    }
    setState(() {
      _displayedMonth = DateTime(year, month);
      _showYearPicker = false;
    });
  }

  void _selectDate(DateTime date) {
    if (date.isBefore(_firstDate) || date.isAfter(_lastDate)) return;
    Navigator.of(context).pop(DateUtils.dateOnly(date));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 6,
      backgroundColor: _birthdayCalendarBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _showYearPicker
                    ? _buildYearPicker()
                    : _buildMonthCalendar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canGoBack = _showYearPicker
        ? _yearPageStart > _yearPageFor(_firstDate.year)
        : _canGoToPreviousMonth;
    final canGoForward = _showYearPicker
        ? _yearPageStart < _yearPageFor(_lastDate.year)
        : _canGoToNextMonth;
    final title = _showYearPicker
        ? '$_yearPageStart - ${_yearPageStart + 11}'
        : '${_displayedMonth.year}年${_displayedMonth.month}月';
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CalendarArrowButton(
            key: const ValueKey<String>('birthday_previous'),
            icon: Icons.chevron_left_rounded,
            enabled: canGoBack,
            onPressed: () =>
                _showYearPicker ? _changeYearPage(-1) : _changeMonth(-1),
          ),
          TextButton(
            key: const ValueKey<String>('birthday_year_month'),
            onPressed: () => setState(() {
              _showYearPicker = !_showYearPicker;
              _yearPageStart = _yearPageFor(_displayedMonth.year);
            }),
            style: TextButton.styleFrom(
              minimumSize: const Size(142, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          _CalendarArrowButton(
            key: const ValueKey<String>('birthday_next'),
            icon: Icons.chevron_right_rounded,
            enabled: canGoForward,
            onPressed: () =>
                _showYearPicker ? _changeYearPage(1) : _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final leadingDays = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
        ).weekday -
        DateTime.monday;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    return Column(
      key: ValueKey<String>(
        'birthday_month_${_displayedMonth.year}_${_displayedMonth.month}',
      ),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: _weekdays
                .map(
                  (weekday) => Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.06,
          ),
          itemCount: cellCount,
          itemBuilder: (_, index) {
            final day = index - leadingDays + 1;
            if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
            final date = DateTime(
              _displayedMonth.year,
              _displayedMonth.month,
              day,
            );
            return _BirthdayDayCell(
              key: ValueKey<String>(
                'birthday_day_${date.year}_${date.month}_${date.day}',
              ),
              date: date,
              secondaryText: _calendarSecondaryText(date),
              selected: DateUtils.isSameDay(date, _selectedDate),
              enabled: !date.isBefore(_firstDate) && !date.isAfter(_lastDate),
              onTap: () => _selectDate(date),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearPicker() {
    return SizedBox(
      key: ValueKey<String>('birthday_year_page_$_yearPageStart'),
      height: 240,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.35,
          crossAxisSpacing: 4,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (_, index) {
          final year = _yearPageStart + index;
          final enabled = year >= _firstDate.year && year <= _lastDate.year;
          final selected = year == _displayedMonth.year;
          return InkWell(
            key: ValueKey<String>('birthday_year_$year'),
            onTap: enabled ? () => _selectYear(year) : null,
            borderRadius: BorderRadius.circular(22),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _birthdayCalendarBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$year',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : enabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _calendarSecondaryText(DateTime date) {
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final solarFestival = _firstCompactFestival(solar.getFestivals());
    if (solarFestival != null) return solarFestival;
    final lunarFestival = _firstCompactFestival(lunar.getFestivals());
    if (lunarFestival != null) return lunarFestival;
    final solarTerm = lunar.getJieQi();
    if (solarTerm.isNotEmpty) return solarTerm;
    if (lunar.getDay() == 1) return '${lunar.getMonthInChinese()}月';
    if (solar.getOtherFestivals().contains('平安夜')) return '平安夜';
    return lunar.getDayInChinese();
  }

  String? _firstCompactFestival(List<String> festivals) {
    for (final festival in festivals) {
      if (festival.length <= 4) return festival;
    }
    return null;
  }
}

class _CalendarArrowButton extends StatelessWidget {
  const _CalendarArrowButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      splashRadius: 20,
      icon: Icon(
        icon,
        size: 18,
        color: enabled ? AppColors.textSecondary : AppColors.divider,
      ),
    );
  }
}

class _BirthdayDayCell extends StatelessWidget {
  const _BirthdayDayCell({
    super.key,
    required this.date,
    required this.secondaryText,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final String secondaryText;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final primaryColor = selected
        ? Colors.white
        : !enabled
            ? AppColors.textTertiary
            : weekend
                ? _birthdayCalendarBlue
                : AppColors.textPrimary;
    final secondaryColor = selected
        ? Colors.white
        : !enabled
            ? AppColors.textTertiary
            : weekend
                ? _birthdayCalendarBlue
                : const Color(0xFFAAAAAA);
    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: selected ? _birthdayCalendarBlue : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  height: 1,
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                secondaryText,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  height: 1,
                  color: secondaryColor,
                  fontSize: secondaryText.length > 3 ? 8 : 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegacyBirthdayField extends StatelessWidget {
  const LegacyBirthdayField({
    super.key,
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? '请输入您的生日' : value,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
