import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:finance_app/l10n/generated/app_localizations.dart';

class TransactionShareHelper {
  static Future<void> shareTransaction(
    BuildContext context,
    TransactionModel transaction,
    String categoryName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

    final typeText =
        transaction.type == TransactionType.income ? l10n.income : l10n.expense;

    final shareText = '''
${l10n.appTitle}

$typeText: ${transaction.amount} ${transaction.currency}
${l10n.category}: $categoryName
${l10n.date}: ${dateFormat.format(transaction.date)}
${transaction.note.isNotEmpty ? '${l10n.note}: ${transaction.note}' : ''}
''';

    try {
      await Share.share(
        shareText,
        subject: '${l10n.appTitle} - $typeText',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
