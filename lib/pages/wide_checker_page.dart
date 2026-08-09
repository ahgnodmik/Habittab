import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/constants.dart';
import '../models/habit.dart';

class WideCheckerPage extends StatefulWidget {
  final List<Habit> habits;
  final Map<String, Set<String>> checkedByDate;

  const WideCheckerPage({
    super.key,
    required this.habits,
    required this.checkedByDate,
  });

  @override
  State<WideCheckerPage> createState() => _WideCheckerPageState();
}

class _WideCheckerPageState extends State<WideCheckerPage> {
  int _selectedHabitIndex = 0;

  bool _checkedOn(DateTime day) {
    final id = widget.habits[_selectedHabitIndex].id;
    return widget.checkedByDate[dateKey(day)]?.contains(id) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.wideChecker)),
        body: Center(child: Text(l10n.noHabitsYet)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wideChecker)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              value: _selectedHabitIndex,
              items: List.generate(widget.habits.length, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(widget.habits[index].name),
                );
              }),
              onChanged: (value) {
                if (value != null) setState(() => _selectedHabitIndex = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: kPointColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: kPointColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: kPointColor,
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: _checkedOn,
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_checkedOn(day)) {
                      return Container(
                        decoration: BoxDecoration(
                          color: kPointColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: kPointColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: kPointColor),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: kPointColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
