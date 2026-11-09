import 'package:flutter/material.dart';

import 'ledger_controller.dart';
import 'models.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final YearMonth _now = YearMonth.now();
  late YearMonth _selected;

  @override
  void initState() {
    super.initState();
    _selected = _now;
    // First launch: ask for the monthly amount straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.state.monthlyAmount == 0) {
        _openSettings();
      }
    });
  }

  Future<void> _openSettings() async {
    final s = widget.controller.state;
    final result = await showDialog<_SettingsResult>(
      context: context,
      builder: (_) =>
          _SettingsDialog(amount: s.monthlyAmount, start: s.startMonth),
    );
    if (result != null) {
      widget.controller.saveSettings(result.amount, result.start);
    }
  }

  Future<void> _addPerson() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddPersonDialog(),
    );
    if (name != null) widget.controller.addMember(name);
  }

  void _openManage(Member member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ManageSheet(
        controller: widget.controller,
        memberId: member.id,
        now: _now,
        onRemove: () {
          Navigator.pop(ctx);
          _confirmRemove(member);
        },
      ),
    );
  }

  Future<void> _confirmRemove(Member member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: const Text('Their payment history will be deleted too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: rust)),
          ),
        ],
      ),
    );
    if (ok == true) widget.controller.removeMember(member.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPerson,
        backgroundColor: pine,
        foregroundColor: cream,
        icon: const Icon(Icons.add),
        label: const Text('Add person'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            final start = state.startMonth;
            final selected = _selected.isBefore(start) ? start : _selected;
            final monthsDue = state.monthsDue(_now);
            final amount = state.monthlyAmount;
            final memberCount = state.members.length;
            final paidCount =
                state.members.where((m) => state.isPaid(m.id, selected)).length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 12),
                    child: Text(
                      'Group Savings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: pine,
                      ),
                    ),
                  ),
                  _SummaryCard(
                    amount: amount,
                    paidCount: paidCount,
                    memberCount: memberCount,
                    totalSaved: state.payments.length * amount,
                    onEdit: _openSettings,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: selected.isAfter(start)
                              ? () => setState(
                                  () => _selected = selected.plusMonths(-1))
                              : null,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              selected.label,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: pine,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: selected.isBefore(_now)
                              ? () => setState(
                                  () => _selected = selected.plusMonths(1))
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (state.members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'No one here yet. Tap "Add person" to add the members of your group.',
                        style: TextStyle(color: Color(0xB31B4332)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: state.members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final member = state.members[i];
                          final owed = monthsDue
                              .where((m) => !state.isPaid(member.id, m))
                              .length;
                          return _MemberRow(
                            name: member.name,
                            paid: state.isPaid(member.id, selected),
                            monthsOwed: owed,
                            amount: amount,
                            onTap: () => widget.controller
                                .togglePaid(member.id, selected),
                            onManage: () => _openManage(member),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.amount,
    required this.paidCount,
    required this.memberCount,
    required this.totalSaved,
    required this.onEdit,
  });

  final double amount;
  final int paidCount;
  final int memberCount;
  final double totalSaved;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        color: pine,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY AMOUNT PER PERSON',
            style: TextStyle(fontSize: 11, color: sage, letterSpacing: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _money(amount),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cream,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit amount',
                icon: const Icon(Icons.edit, color: cream),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'This month: $paidCount of $memberCount paid · '
              '${_money(paidCount * amount)} of ${_money(memberCount * amount)}',
              style: const TextStyle(fontSize: 14, color: cream),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Total saved so far: ${_money(totalSaved)}',
            style: const TextStyle(fontSize: 14, color: sage),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.paid,
    required this.monthsOwed,
    required this.amount,
    required this.onTap,
    required this.onManage,
  });

  final String name;
  final bool paid;
  final int monthsOwed;
  final double amount;
  final VoidCallback onTap;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final background = paid ? pine : parchment;
    final foreground = paid ? cream : pine;
    final subtitle = monthsOwed == 0
        ? 'All paid up'
        : 'Owes $monthsOwed month${monthsOwed == 1 ? '' : 's'} · '
            '${_money(monthsOwed * amount)}';

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onManage,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: foreground.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onManage,
                tooltip: 'Months and range',
                icon: Icon(
                  Icons.calendar_month,
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: paid ? sage : Colors.transparent,
                  border: Border.all(
                    width: 2,
                    color: paid ? sage : pine.withValues(alpha: 0.4),
                  ),
                ),
                child: paid
                    ? const Icon(Icons.check, color: pine, semanticLabel: 'Paid')
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-person sheet: tick individual months, or mark a whole range at once.
class _ManageSheet extends StatefulWidget {
  const _ManageSheet({
    required this.controller,
    required this.memberId,
    required this.now,
    required this.onRemove,
  });

  final LedgerController controller;
  final String memberId;
  final YearMonth now;
  final VoidCallback onRemove;

  @override
  State<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<_ManageSheet> {
  late YearMonth _from;
  late YearMonth _to;

  @override
  void initState() {
    super.initState();
    final start = widget.controller.state.startMonth;
    _from = start;
    _to = widget.now.isBefore(start) ? start : widget.now;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final matches = state.members.where((m) => m.id == widget.memberId);
        if (matches.isEmpty) return const SizedBox.shrink();
        final member = matches.first;
        final months = state.monthsDue(widget.now);
        final amount = state.monthlyAmount;
        final paidCount =
            months.where((m) => state.isPaid(member.id, m)).length;

        if (months.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No months to show yet.'),
          );
        }

        DropdownButton<YearMonth> picker(
          YearMonth value,
          ValueChanged<YearMonth> onChanged,
        ) {
          return DropdownButton<YearMonth>(
            isExpanded: true,
            value: value,
            items: [
              for (final m in months)
                DropdownMenuItem(value: m, child: Text(m.label)),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: pine,
                  ),
                ),
                Text(
                  'Paid $paidCount of ${months.length} months · '
                  '${_money(paidCount * amount)}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mark a range of months',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Expanded(
                      child: picker(_from, (v) => setState(() => _from = v)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: picker(_to, (v) => setState(() => _to = v)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: pine),
                        onPressed: () => widget.controller
                            .setRange(member.id, _from, _to, true),
                        child: const Text('Mark paid'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.controller
                            .setRange(member.id, _from, _to, false),
                        child: const Text('Mark unpaid'),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Or tick individual months',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in months)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: pine,
                          title: Text(m.label),
                          value: state.isPaid(member.id, m),
                          onChanged: (_) =>
                              widget.controller.togglePaid(member.id, m),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline, color: rust),
                  label: const Text(
                    'Remove this person',
                    style: TextStyle(color: rust),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsResult {
  const _SettingsResult(this.amount, this.start);

  final double amount;
  final YearMonth start;
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.amount, required this.start});

  final double amount;
  final YearMonth start;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late final TextEditingController _amountController;
  late YearMonth _start;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amount > 0 ? _plainNumber(widget.amount) : '',
    );
    _start = widget.start;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (value == null || value < 0) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, _SettingsResult(value, _start));
  }

  @override
  Widget build(BuildContext context) {
    final now = YearMonth.now();
    return AlertDialog(
      title: const Text('Group settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountController,
            autofocus: widget.amount == 0,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monthly amount per person',
              prefixText: '\$ ',
              errorText: _invalid ? 'Enter a number' : null,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Collection started'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _start = _start.plusMonths(-1)),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _start.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _start.isBefore(now)
                    ? () => setState(() => _start = _start.plusMonths(1))
                    : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _AddPersonDialog extends StatefulWidget {
  const _AddPersonDialog();

  @override
  State<_AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<_AddPersonDialog> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _name.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add person'),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

String _plainNumber(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

String _money(double v) =>
    v == v.roundToDouble() ? '\$${v.toStringAsFixed(0)}' : '\$${v.toStringAsFixed(2)}';
