import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

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
      'isDefault': isDefault,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      colorValue: map['colorValue'],
      iconCode: map['iconCode'],
      isDefault: map['isDefault'] == true || map['isDefault'] == 1,
    );
  }
}

extension CategoryLocalization on CategoryModel {
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return name;

    if (isDefault) {
      switch (name) {
        case 'Еда':
        case 'Food':
        case 'Тамақ':
          return l10n.categoryFood;
        case 'Развлечения':
        case 'Entertainment':
        case 'Ойын-сауық':
          return l10n.categoryEntertainment;
        case 'Поездки':
        case 'Trips':
        case 'Сапарлар':
          return l10n.categoryTrips;
        case 'Зарплата':
        case 'Salary':
        case 'Жалақы':
          return l10n.categorySalary;
      }
    }
    return name;
  }
}
