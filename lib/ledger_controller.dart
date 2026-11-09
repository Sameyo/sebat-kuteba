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
