enum TransactionType {
  income,
  expense,
}

enum RecurrenceInterval {
  daily,
  weekly,
  monthly,
  none,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String note;
  final bool isRecurring;
  final String currency;
  final RecurrenceInterval recurrenceInterval;
  final DateTime? nextOccurrence;
  final bool isPinned;
  final String? userId; // Added for joint budget
  final String? groupId; // Added for joint budget

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note = '',
    this.isRecurring = false,
    this.currency = 'USD',
    this.recurrenceInterval = RecurrenceInterval.none,
    this.nextOccurrence,
    this.isPinned = false,
    this.userId,
    this.groupId,
  });

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    bool? isRecurring,
    String? currency,
    RecurrenceInterval? recurrenceInterval,
    DateTime? nextOccurrence,
    bool? isPinned,
    String? userId,
    String? groupId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      currency: currency ?? this.currency,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      isPinned: isPinned ?? this.isPinned,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'isRecurring': isRecurring, // Use native bool
      'currency': currency,
      'recurrenceInterval': recurrenceInterval.name,
      'nextOccurrence': nextOccurrence?.toIso8601String(),
      'isPinned': isPinned, // Use native bool
      'userId': userId,
      'groupId': groupId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // Robust parsing of amount (handles both String and num from Decimal)
    double parsedAmount = 0.0;
    final amountVal = map['amount'];
    if (amountVal is num) {
      parsedAmount = amountVal.toDouble();
    } else if (amountVal is String) {
      parsedAmount = double.tryParse(amountVal) ?? 0.0;
    }

    return TransactionModel(
      id: map['id'],
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      amount: parsedAmount,
      categoryId: map['categoryId'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      isRecurring: map['isRecurring'] == true || map['isRecurring'] == 1,
      currency: map['currency'],
      recurrenceInterval: RecurrenceInterval.values
          .firstWhere((e) => e.name == map['recurrenceInterval']),
      nextOccurrence: map['nextOccurrence'] != null
          ? DateTime.parse(map['nextOccurrence'])
          : null,
      isPinned: map['isPinned'] == true || map['isPinned'] == 1,
      userId: map['userId'],
      groupId: map['groupId'],
    );
  }
}
