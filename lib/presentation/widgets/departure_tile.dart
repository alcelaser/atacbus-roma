import 'package:flutter/material.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/departure.dart';
import 'line_badge.dart';

class DepartureTile extends StatelessWidget {
  const DepartureTile({super.key, required this.departure});

  final Departure departure;

  Color _delayColor(int? delaySeconds) {
    if (delaySeconds == null) return Colors.grey;
    if (delaySeconds <= 0) return Colors.green;
    if (delaySeconds <= 300) return Colors.orange;
    return Colors.red;
  }

  String _formatCountdown(int secondsUntil) {
    if (secondsUntil <= 0) return 'Now';
    final minutes = secondsUntil ~/ 60;
    if (minutes == 0) return '<1 min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTimeUtils.currentTimeAsSeconds();
    final secondsUntil = departure.effectiveSeconds - now;
    final countdown = _formatCountdown(secondsUntil);
    final scheduledDisplay = DateTimeUtils.formatTime(departure.scheduledSeconds);

    return ListTile(
      leading: LineBadge(
        lineNumber: departure.routeShortName,
        color: departure.routeColor,
      ),
      title: Text(
        departure.tripHeadsign ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(scheduledDisplay),
          if (departure.isRealtime) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _delayColor(departure.delaySeconds),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (departure.delaySeconds != null && departure.delaySeconds != 0)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  departure.delaySeconds! > 0
                      ? '+${departure.delaySeconds! ~/ 60}m'
                      : '${departure.delaySeconds! ~/ 60}m',
                  style: TextStyle(
                    color: _delayColor(departure.delaySeconds),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
      trailing: Text(
        countdown,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: secondsUntil <= 120
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
      ),
    );
  }
}
