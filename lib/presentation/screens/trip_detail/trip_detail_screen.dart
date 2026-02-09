import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/trip_plan.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/line_badge.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.itinerary});

  final TripItinerary itinerary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final totalMinutes = itinerary.totalDurationSeconds ~/ 60;
    final depTime = DateTimeUtils.formatTime(itinerary.departureSeconds);
    final arrTime = DateTimeUtils.formatTime(itinerary.arrivalSeconds);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripDetail),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$depTime  \u2192  $arrTime',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.totalDuration(totalMinutes),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: itinerary.isDirect
                          ? theme.colorScheme.primaryContainer
                          : itinerary.hasWalkingTransfer
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      itinerary.isDirect
                          ? l10n.direct
                          : itinerary.hasWalkingTransfer
                              ? l10n.walkingTransfer
                              : l10n.transfer,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: itinerary.isDirect
                            ? theme.colorScheme.onPrimaryContainer
                            : itinerary.hasWalkingTransfer
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Each leg with all intermediate stops
          ...itinerary.legs.asMap().entries.expand((entry) {
            final legIndex = entry.key;
            final leg = entry.value;
            if (leg.isWalking) {
              return [_buildWalkingIndicator(context, leg)];
            }
            return [
              if (legIndex > 0 && !itinerary.legs[legIndex - 1].isWalking)
                _buildTransferIndicator(context, leg, legIndex),
              _LegTimeline(leg: leg),
            ];
          }),
        ],
      ),
    );
  }

  Widget _buildTransferIndicator(
      BuildContext context, TripLeg leg, int legIndex) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prevLeg = itinerary.legs[legIndex - 1];
    final waitSeconds = leg.departureSeconds - prevLeg.arrivalSeconds;
    final waitMinutes = waitSeconds ~/ 60;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.transfer_within_a_station,
              size: 18,
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.transferAt(leg.boardStopName),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const Spacer(),
          Text(
            l10n.waitMinutes(waitMinutes),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingIndicator(BuildContext context, TripLeg walkLeg) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final walkMin = walkLeg.durationSeconds ~/ 60;
    final distMeters = walkLeg.walkingDistanceMeters?.round() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_walk,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.walkTo(walkLeg.alightStopName),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Text(
                  l10n.walkDistance(distMeters),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '~$walkMin min',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegTimeline extends ConsumerWidget {
  const _LegTimeline({required this.leg});

  final TripLeg leg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final stopTimesAsync = ref.watch(tripStopTimesProvider(leg.tripId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leg header with line badge
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              LineBadge(
                lineNumber: leg.routeShortName,
                color: leg.routeColor,
              ),
              const SizedBox(width: 8),
              if (leg.tripHeadsign != null)
                Expanded(
                  child: Text(
                    leg.tripHeadsign!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        // Timeline stops
        stopTimesAsync.when(
          data: (allStops) {
            // Filter to only stops in this leg's range
            final legStops = allStops
                .where((s) =>
                    s.stopSequence >= leg.boardSequence &&
                    s.stopSequence <= leg.alightSequence)
                .toList();

            if (legStops.isEmpty) {
              return _buildFallbackTimeline(theme, l10n);
            }

            return Column(
              children: legStops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                final isFirst = index == 0;
                final isLast = index == legStops.length - 1;
                final isIntermediate = !isFirst && !isLast;
                final time = DateTimeUtils.formatTime(
                    DateTimeUtils.parseGtfsTime(stop.departureTime));

                return _buildTimelineStop(
                  theme: theme,
                  l10n: l10n,
                  stopName: stop.stopName,
                  time: time,
                  isFirst: isFirst,
                  isLast: isLast,
                  isIntermediate: isIntermediate,
                  label: isFirst
                      ? l10n.board
                      : isLast
                          ? l10n.alight
                          : null,
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => _buildFallbackTimeline(theme, l10n),
        ),
      ],
    );
  }

  Widget _buildFallbackTimeline(ThemeData theme, AppLocalizations l10n) {
    final depTime = DateTimeUtils.formatTime(leg.departureSeconds);
    final arrTime = DateTimeUtils.formatTime(leg.arrivalSeconds);

    return Column(
      children: [
        _buildTimelineStop(
          theme: theme,
          l10n: l10n,
          stopName: leg.boardStopName,
          time: depTime,
          isFirst: true,
          isLast: false,
          isIntermediate: false,
          label: l10n.board,
        ),
        _buildIntermediateIndicator(theme, l10n),
        _buildTimelineStop(
          theme: theme,
          l10n: l10n,
          stopName: leg.alightStopName,
          time: arrTime,
          isFirst: false,
          isLast: true,
          isIntermediate: false,
          label: l10n.alight,
        ),
      ],
    );
  }

  Widget _buildIntermediateIndicator(ThemeData theme, AppLocalizations l10n) {
    final count = leg.stopCount - 1;
    if (count <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(width: 18),
          Text(
            l10n.intermediateStops(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStop({
    required ThemeData theme,
    required AppLocalizations l10n,
    required String stopName,
    required String time,
    required bool isFirst,
    required bool isLast,
    required bool isIntermediate,
    String? label,
  }) {
    final dotSize = isIntermediate ? 8.0 : 14.0;
    final dotColor = isFirst
        ? Colors.green
        : isLast
            ? theme.colorScheme.error
            : theme.colorScheme.primary.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Timeline dot
          SizedBox(
            width: 32,
            child: Center(
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: (isFirst || isLast)
                      ? Border.all(
                          color: dotColor,
                          width: 2,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Time
          SizedBox(
            width: 46,
            child: Text(
              time,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight:
                    isIntermediate ? FontWeight.normal : FontWeight.bold,
                color: isIntermediate
                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Stop name + label
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    stopName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isIntermediate ? FontWeight.normal : FontWeight.w600,
                      color: isIntermediate
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? Colors.green.withOpacity(0.15)
                          : theme.colorScheme.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isFirst ? Colors.green : theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
