class DebtModel {
  final String id;
  final String type;
  final String creditorName;
  final double totalAmount;
  final double remainingAmount;

  DebtModel({
    required this.id,
    required this.type,
    required this.creditorName,
    required this.totalAmount,
    required this.remainingAmount,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'],
      type: json['type'],
      creditorName: json['creditorName'] ?? 'Неизвестно',
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      remainingAmount: double.tryParse(json['remainingAmount'].toString()) ?? 0.0,
    );
  }
}
