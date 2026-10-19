class ReviewEntry {
  final String id;
  int stage;
  DateTime due;

  /// How many times the word was missed (revealed or solved with a hint).
  /// Records saved before this was tracked count as one miss.
  int misses;

  /// When it was last missed; unknown for records saved before tracking.
  DateTime? lastMissed;
  ReviewEntry(this.id,
      {this.stage = 0, DateTime? due, this.misses = 1, this.lastMissed})
      : due = due ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'stage': stage,
        'due': due.toIso8601String(),
        'misses': misses,
        if (lastMissed != null) 'lastMissed': lastMissed!.toIso8601String(),
      };
  factory ReviewEntry.fromJson(Map<String, dynamic> data) {
    final stage = (data['stage'] as num).toInt();
    final due = DateTime.parse(data['due'] as String);
    final missed = data['lastMissed'] as String?;
    return ReviewEntry(data['id'] as String,
        stage: stage,
        due: due,
        misses: ((data['misses'] as num?)?.toInt() ?? 1).clamp(1, 999),
        // Older records: a miss set stage 0 and due to that moment, so an
        // entry not yet answered correctly since still holds the miss time.
        lastMissed: missed != null
            ? DateTime.parse(missed)
            : (stage == 0 ? due : null));
  }

  /// When it was last missed, e.g. `오늘`, `어제`, `5일 전`; `전에` if unknown.
  String missedAgo(DateTime now) {
    final missed = lastMissed;
    if (missed == null) return '전에';
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(missed.year, missed.month, missed.day))
        .inDays;
    return switch (days) {
      <= 0 => '오늘',
      1 => '어제',
      < 30 => '$days일 전',
      _ => '${missed.month}/${missed.day}',
    };
  }
}
