import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/debt_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _amountCtrl = TextEditingController();
  final _creditorCtrl = TextEditingController();
  String _type = 'Кредит';
  final List<String> _types = ['Кредит', 'Ипотека', 'Рассрочка', 'Частный долг'];
  bool _isLoading = false;

  void _saveDebt() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0 || _creditorCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите корректные данные')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(debtProvider.notifier).addDebt(
      _type,
      _creditorCtrl.text,
      amount,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при добавлении долга')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить долг')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _type = val!),
              decoration: const InputDecoration(labelText: 'Тип долга'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _creditorCtrl,
              decoration: const InputDecoration(labelText: 'Кредитор (Банк/человек)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Сумма'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDebt,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
