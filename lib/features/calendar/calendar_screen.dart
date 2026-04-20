import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/theme.dart';
import '../../shared/providers/database_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime(2026, 4, 20);
  DateTime? _selectedDay = DateTime(2026, 4, 20);

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(databaseProvider).watchEventsForMonth(_focusedDay);

    return StreamBuilder(
      stream: events,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
          children: [
            Row(
              children: [
                Text(
                  '月曆',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                SegmentedButton<CalendarFormat>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarFormat.month,
                      label: Text('月'),
                    ),
                    ButtonSegment(
                      value: CalendarFormat.twoWeeks,
                      label: Text('雙週'),
                    ),
                    ButtonSegment(value: CalendarFormat.week, label: Text('週')),
                  ],
                  selected: {_format},
                  onSelectionChanged: (value) =>
                      setState(() => _format = value.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2035),
              focusedDay: _focusedDay,
              calendarFormat: _format,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) => setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              }),
              onFormatChanged: (format) => setState(() => _format = format),
              eventLoader: (day) => items
                  .where(
                    (event) =>
                        event.startAt.year == day.year &&
                        event.startAt.month == day.month &&
                        event.startAt.day == day.day,
                  )
                  .toList(),
              headerStyle: const HeaderStyle(formatButtonVisible: false),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  items.isEmpty ? '尚無記錄' : '本月有 ${items.length} 個事件',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
