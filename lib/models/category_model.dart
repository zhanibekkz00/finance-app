class CategoryModel {
  final String id;
  final String name;
  final int colorValue; // Store color as int (ARGB)
  final bool isDefault;
  final int iconCode;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCode,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      colorValue: map['colorValue'],
      iconCode: map['iconCode'],
      isDefault: map['isDefault'] == 1,
    );
  }
}
