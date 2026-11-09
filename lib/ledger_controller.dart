import 'package:flutter/foundation.dart';

import 'ledger_store.dart';
import 'models.dart';

class LedgerController extends ChangeNotifier {
  LedgerController(this._store);

  final LedgerStore _store;
  LedgerState state = LedgerState.initial();

  Future<void> init() async {
    state = await _store.load();
    notifyListeners();
  }

  void _set(LedgerState next) {
    state = next;
    notifyListeners();
    _store.save(next);
  }

  void saveSettings(double amount, YearMonth startMonth) {
    _set(state.copyWith(monthlyAmount: amount, startMonth: startMonth));
  }

  void addMember(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final member = Member(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: clean,
    );
    _set(state.copyWith(members: [...state.members, member]));
  }

  void removeMember(String id) {
    _set(state.copyWith(
      members: state.members.where((m) => m.id != id).toList(),
      payments: state.payments.where((p) => p.memberId != id).toList(),
    ));
  }

  /// Marks every month from [a] to [b] (either order, inclusive) as paid or
  /// unpaid for one member. Months already in the wanted state are left alone.
  void setRange(String memberId, YearMonth a, YearMonth b, bool paid) {
    final from = a.isAfter(b) ? b : a;
    final to = a.isAfter(b) ? a : b;
    final payments = [...state.payments];
    final now = DateTime.now().millisecondsSinceEpoch;
    var m = from;
    while (!m.isAfter(to)) {
      final month = m;
      final has = payments.any((p) => p.memberId == memberId && p.month == month);
      if (paid && !has) {
        payments.add(Payment(memberId: memberId, month: month, recordedAt: now));
      } else if (!paid && has) {
        payments.removeWhere((p) => p.memberId == memberId && p.month == month);
      }
      m = m.plusMonths(1);
    }
    _set(state.copyWith(payments: payments));
  }

  /// Tap on a name: marks paid for [month], or undoes it if already paid.
  void togglePaid(String memberId, YearMonth month) {
    if (state.isPaid(memberId, month)) {
      _set(state.copyWith(
        payments: state.payments
            .where((p) => !(p.memberId == memberId && p.month == month))
            .toList(),
      ));
    } else {
      final payment = Payment(
        memberId: memberId,
        month: month,
        recordedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _set(state.copyWith(payments: [...state.payments, payment]));
    }
  }
}
