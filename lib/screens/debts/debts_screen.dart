import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/debt_provider.dart';
import '../../models/debt_model.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  void _showPayModal(BuildContext context, WidgetRef ref, DebtModel debt) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Внести платеж'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Сумма (Остаток: ${debt.remainingAmount})',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0 && val <= debt.remainingAmount) {
                Navigator.pop(ctx);
                await ref.read(debtProvider.notifier).payDebt(debt.id, val);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Неверная сумма платежа')),
                );
              }
            },
            child: const Text('Оплатить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Долги и кредиты')),
      body: state.isLoading && state.debts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.debts.isEmpty
              ? const Center(child: Text('Нет активных долгов'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.debts.length,
                  itemBuilder: (context, index) {
                    final d = state.debts[index];
                    final progress = 1 - (d.remainingAmount / d.totalAmount);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(d.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.grey),
                                  onPressed: () {
                                     ref.read(debtProvider.notifier).deleteDebt(d.id);
                                  },
                                ),
                              ],
                            ),
                            Text(d.creditorName, style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Осталось: ${d.remainingAmount.toStringAsFixed(2)}'),
                                Text('Всего: ${d.totalAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: d.remainingAmount > 0
                                    ? () => _showPayModal(context, ref, d)
                                    : null,
                                child: const Text('Внести платеж'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_debt'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
