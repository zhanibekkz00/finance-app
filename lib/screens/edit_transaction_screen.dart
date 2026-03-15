import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import 'package:intl/intl.dart';
import 'package:finance_app/l10n/generated/app_localizations.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late TransactionType _type;
  late bool _isRecurring;
  late RecurrenceInterval _recurrenceInterval;
  late String _selectedCategoryId;
  late String _selectedCurrency;
  late DateTime _selectedDate;

  final _currencies = ['USD', 'EUR', 'RUB', 'KZT'];

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.transaction.amount.toString());
    _noteCtrl = TextEditingController(text: widget.transaction.note);
    _type = widget.transaction.type;
    _isRecurring = widget.transaction.isRecurring;
    _recurrenceInterval = widget.transaction.recurrenceInterval;
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedCurrency = widget.transaction.currency;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editTransaction)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: Text(l10n.expense),
                    value: TransactionType.expense,
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: Text(l10n.income),
                    value: TransactionType.income,
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ],
            ),

            // Currency Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCurrency = v!),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _amountCtrl,
              decoration: InputDecoration(labelText: l10n.amount),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(labelText: l10n.category),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(
                                IconData(c.iconCode,
                                    fontFamily: 'MaterialIcons'),
                                color: Color(c.colorValue),
                                size: 16),
                            const SizedBox(width: 8),
                            Text(c.getLocalizedName(context)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v!),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(labelText: l10n.note),
            ),

            const SizedBox(height: 16),

            // Date Picker
            ListTile(
              title: Text(l10n.date),
              subtitle: Text(
                  DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),

            // Recurring UI
            SwitchListTile(
              title: Text(l10n.recurring),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            if (_isRecurring)
              DropdownButton<RecurrenceInterval>(
                value: _recurrenceInterval,
                items: RecurrenceInterval.values
                    .where((e) => e != RecurrenceInterval.none)
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => setState(() => _recurrenceInterval = v!),
              ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final updatedTx = widget.transaction.copyWith(
                        type: _type,
                        amount: double.tryParse(_amountCtrl.text) ??
                            widget.transaction.amount,
                        categoryId: _selectedCategoryId,
                        date: _selectedDate,
                        note: _noteCtrl.text,
                        isRecurring: _isRecurring,
                        currency: _selectedCurrency,
                        recurrenceInterval: _isRecurring
                            ? _recurrenceInterval
                            : RecurrenceInterval.none,
                      );

                      ref.read(transactionProvider.notifier).update(updatedTx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.transactionUpdated)),
                      );

                      Navigator.pop(context);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
