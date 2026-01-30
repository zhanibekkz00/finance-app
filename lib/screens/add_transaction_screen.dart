import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../../providers/category_provider.dart';
import 'package:finance_app/l10n/generated/app_localizations.dart';
import '../widgets/category_quick_selector.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  bool _isRecurring = false;
  RecurrenceInterval _recurrenceInterval = RecurrenceInterval.monthly;
  String? _selectedCategoryId;
  String _selectedCurrency = 'USD';

  final _currencies = ['USD', 'EUR', 'RUB', 'KZT'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addTransaction)),
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
              decoration: InputDecoration(
                  labelText:
                      l10n.amount), // Reuse amount label context or add new key
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

            // Category Selector (Replacing Dropdown with Modal for better reliability)
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.category),
              subtitle: Text(
                _selectedCategoryId == null
                    ? l10n.selectCategory
                    : categories
                            .where((c) => c.id == _selectedCategoryId)
                            .firstOrNull
                            ?.name ??
                        l10n.selectCategory,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedCategoryId == null
                      ? Colors.grey.withOpacity(0.2)
                      : Color(categories
                                  .where((c) => c.id == _selectedCategoryId)
                                  .firstOrNull
                                  ?.colorValue ??
                              0xFF9E9E9E)
                          .withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedCategoryId == null
                      ? Icons.category
                      : IconData(
                          categories
                                  .where((c) => c.id == _selectedCategoryId)
                                  .firstOrNull
                                  ?.iconCode ??
                              0xe88a,
                          fontFamily: 'MaterialIcons',
                        ),
                  color: _selectedCategoryId == null
                      ? Colors.grey
                      : Color(categories
                              .where((c) => c.id == _selectedCategoryId)
                              .firstOrNull
                              ?.colorValue ??
                          0xFF9E9E9E),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CategoryQuickSelector(
                    currentCategoryId: _selectedCategoryId ?? '',
                    onCategorySelected: (id) {
                      setState(() => _selectedCategoryId = id);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(labelText: l10n.note),
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
            ElevatedButton(
              onPressed: () {
                if (_selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please select a category')));
                  return;
                }
                final tx = TransactionModel(
                  id: const Uuid().v4(),
                  type: _type,
                  amount: double.tryParse(_amountCtrl.text) ?? 0,
                  categoryId: _selectedCategoryId!,
                  date: DateTime.now(),
                  note: _noteCtrl.text,
                  isRecurring: _isRecurring,
                  recurrenceInterval: _isRecurring
                      ? _recurrenceInterval
                      : RecurrenceInterval.none,
                  currency: _selectedCurrency,
                );

                ref.read(transactionProvider.notifier).add(tx);
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            )
          ],
        ),
      ),
    );
  }
}
