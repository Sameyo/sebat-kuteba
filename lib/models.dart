const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A calendar month, e.g. April 2026. Stored as "2026-04".
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month);

  final int year;
  final int month; // 1-12

  factory YearMonth.now() {
    final d = DateTime.now();
    return YearMonth(d.year, d.month);
  }

  factory YearMonth.parse(String s) {
    final parts = s.split('-');
    return YearMonth(int.parse(parts[0]), int.parse(parts[1]));
  }

  YearMonth plusMonths(int n) {
    final index = year * 12 + (month - 1) + n;
    return YearMonth(index ~/ 12, index % 12 + 1);
  }

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  String get label => '${_monthNames[month - 1]} $year';

  bool isBefore(YearMonth other) => compareTo(other) < 0;

  bool isAfter(YearMonth other) => compareTo(other) > 0;

  @override
  int compareTo(YearMonth other) =>
      (year * 12 + month).compareTo(other.year * 12 + other.month);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => year * 12 + month;
}

class Member {
  const Member({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Member.fromJson(Map<String, dynamic> j) =>
      Member(id: j['id'] as String, name: j['name'] as String);
}

/// One contribution by one member for one month.
///
/// [source] is "manual" for taps in the app. A future account-activity
/// importer can add payments with a different source (e.g. "auto") without
/// changing the model.
class Payment {
  const Payment({
    required this.memberId,
    required this.month,
    required this.recordedAt,
    this.source = 'manual',
  });

  final String memberId;
  final YearMonth month;
  final int recordedAt; // milliseconds since epoch
  final String source;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'month': month.key,
        'source': source,
        'recordedAt': recordedAt,
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        memberId: j['memberId'] as String,
        month: YearMonth.parse(j['month'] as String),
        source: (j['source'] as String?) ?? 'manual',
        recordedAt: (j['recordedAt'] as num?)?.toInt() ?? 0,
      );
}

class LedgerState {
  const LedgerState({
    required this.monthlyAmount,
    required this.startMonth,
    required this.members,
    required this.payments,
  });

  final double monthlyAmount;
  final YearMonth startMonth;
  final List<Member> members;
  final List<Payment> payments;

  factory LedgerState.initial() => const LedgerState(
        monthlyAmount: 0,
        startMonth: YearMonth(2026, 4),
        members: [],
        payments: [],
      );

  LedgerState copyWith({
    double? monthlyAmount,
    YearMonth? startMonth,
    List<Member>? members,
    List<Payment>? payments,
  }) =>
      LedgerState(
        monthlyAmount: monthlyAmount ?? this.monthlyAmount,
        startMonth: startMonth ?? this.startMonth,
        members: members ?? this.members,
        payments: payments ?? this.payments,
      );

  bool isPaid(String memberId, YearMonth month) =>
      payments.any((p) => p.memberId == memberId && p.month == month);

  /// Every month from the start month up to and including [now].
  List<YearMonth> monthsDue(YearMonth now) {
    final result = <YearMonth>[];
    var m = startMonth;
    while (!m.isAfter(now)) {
      result.add(m);
      m = m.plusMonths(1);
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'monthlyAmount': monthlyAmount,
        'startMonth': startMonth.key,
        'members': members.map((m) => m.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
      };

  factory LedgerState.fromJson(Map<String, dynamic> j) => LedgerState(
        monthlyAmount: (j['monthlyAmount'] as num).toDouble(),
        startMonth: YearMonth.parse(j['startMonth'] as String),
        members: (j['members'] as List)
            .map((e) => Member.fromJson(e as Map<String, dynamic>))
            .toList(),
        payments: (j['payments'] as List)
            .map((e) => Payment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
