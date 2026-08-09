import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';

class BadgesPage extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, Set<String>> checkedByDate;

  const BadgesPage({
    super.key,
    required this.habits,
    required this.checkedByDate,
  });

  bool _checked(String key, String id) =>
      checkedByDate[key]?.contains(id) ?? false;

  int _computeStreak(String id) {
    int streak = 0;
    DateTime day = DateTime.now();
    while (_checked(dateKey(day), id)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _computeWeeklyBest(String id) {
    int best = 0;
    final start = DateTime.now();
    for (int w = 0; w < 8; w++) {
      int count = 0;
      for (int i = 0; i < 7; i++) {
        final day = start.subtract(Duration(days: w * 7 + i));
        if (_checked(dateKey(day), id)) count++;
      }
      if (count > best) best = count;
    }
    return best;
  }

  int _computeTotal(String id) {
    int total = 0;
    for (final ids in checkedByDate.values) {
      if (ids.contains(id)) total++;
    }
    return total;
  }

  List<_Badge> _badgesFor(int streak, AppLocalizations l10n) {
    return [
      if (streak >= 1)
        _Badge(l10n.badgeDay1Title, l10n.badgeDay1Subtitle, Icons.star_border),
      if (streak >= 3)
        _Badge(l10n.badge3DaysTitle, l10n.badge3DaysSubtitle, Icons.star_half),
      if (streak >= 7)
        _Badge(l10n.badge7DaysTitle, l10n.badge7DaysSubtitle, Icons.star),
      if (streak >= 14)
        _Badge(
          l10n.badge14DaysTitle,
          l10n.badge14DaysSubtitle,
          Icons.emoji_events_outlined,
        ),
      if (streak >= 30)
        _Badge(
          l10n.badge30DaysTitle,
          l10n.badge30DaysSubtitle,
          Icons.military_tech_outlined,
        ),
      if (streak >= 60)
        _Badge(
          l10n.badge60DaysTitle,
          l10n.badge60DaysSubtitle,
          Icons.workspace_premium_outlined,
        ),
      if (streak >= 90)
        _Badge(
          l10n.badge90DaysTitle,
          l10n.badge90DaysSubtitle,
          Icons.workspace_premium,
        ),
      if (streak >= 180)
        _Badge(
          l10n.badge180DaysTitle,
          l10n.badge180DaysSubtitle,
          Icons.verified,
        ),
      if (streak >= 365)
        _Badge(
          l10n.badge365DaysTitle,
          l10n.badge365DaysSubtitle,
          Icons.verified_user,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.badges)),
        body: Center(child: Text(l10n.noHabitsYet)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.badges)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          final streak = _computeStreak(habit.id);
          final badges = _badgesFor(streak, l10n);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: kPointColor),
                      const SizedBox(width: 8),
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.streakCount(streak),
                        style: TextStyle(
                          color: kPointColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_view_week,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.weeklyBestTotal(
                          _computeWeeklyBest(habit.id),
                          _computeTotal(habit.id),
                        ),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        badges.isEmpty
                            ? [
                              Text(
                                l10n.noBadgesYet,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ]
                            : badges
                                .map(
                                  (b) => GestureDetector(
                                    onTap: () => _showBadgeDetail(context, b),
                                    child: Chip(
                                      avatar: Icon(
                                        b.icon,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: Text(b.title),
                                      backgroundColor: kPointColor,
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Badge(this.title, this.subtitle, this.icon);
}

void _showBadgeDetail(BuildContext context, _Badge badge) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(badge.icon, color: kPointColor),
              const SizedBox(width: 8),
              Text(badge.title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.whatshot, size: 72, color: kPointColor),
              const SizedBox(height: 12),
              Text(badge.subtitle),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.ok),
            ),
          ],
        ),
  );
}
