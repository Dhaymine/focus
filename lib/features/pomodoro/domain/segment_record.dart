import 'timer_plan.dart';

/// One finished (or partially finished) segment, used for history/statistics.
class SegmentRecord {
  const SegmentRecord({
    required this.type,
    required this.startMs,
    required this.endMs,
    required this.plannedMs,
    required this.actualMs,
    required this.completed,
  });

  final SegmentType type;
  final int startMs;
  final int endMs;
  final int plannedMs;
  final int actualMs;
  final bool completed;

  Map<String, dynamic> toJson() => {
        't': type.name,
        's': startMs,
        'e': endMs,
        'p': plannedMs,
        'a': actualMs,
        'c': completed,
      };

  static SegmentRecord? tryFromJson(dynamic j) {
    try {
      final m = j as Map;
      final type = SegmentType.values.firstWhere((e) => e.name == m['t']);
      return SegmentRecord(
        type: type,
        startMs: (m['s'] as num).toInt(),
        endMs: (m['e'] as num).toInt(),
        plannedMs: (m['p'] as num).toInt(),
        actualMs: (m['a'] as num).toInt(),
        completed: m['c'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}
