import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Categories used in the EcoWallet FYP prototype.
/// The emission factors are simplified kg CO2 estimates per RM spent.
enum TransactionCategory {
  food,
  transport,
  shopping,
  utilities,
  entertainment,
  housing,
  healthcare,
  education,
  travel,
  others,
}

extension TransactionCategoryX on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.housing:
        return 'Housing';
      case TransactionCategory.healthcare:
        return 'Healthcare';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.others:
        return 'Others';
    }
  }

  String get storageValue => name;

  static TransactionCategory fromStorageValue(String? value) {
    return TransactionCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => TransactionCategory.others,
    );
  }

  String get emoji {
    switch (this) {
      case TransactionCategory.food:
        return '🍱';
      case TransactionCategory.transport:
        return '🚆';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.utilities:
        return '💡';
      case TransactionCategory.entertainment:
        return '🎬';
      case TransactionCategory.housing:
        return '🏠';
      case TransactionCategory.healthcare:
        return '🩺';
      case TransactionCategory.education:
        return '🎓';
      case TransactionCategory.travel:
        return '✈️';
      case TransactionCategory.others:
        return '🌿';
    }
  }

  /// kg CO2 per RM. These are prototype factors for academic demonstration.
  double get emissionFactor {
    switch (this) {
      case TransactionCategory.transport:
        return 0.50;
      case TransactionCategory.food:
        return 0.20;
      case TransactionCategory.shopping:
        return 0.30;
      case TransactionCategory.utilities:
        return 0.40;
      case TransactionCategory.entertainment:
        return 0.12;
      case TransactionCategory.housing:
        return 0.18;
      case TransactionCategory.healthcare:
        return 0.10;
      case TransactionCategory.education:
        return 0.08;
      case TransactionCategory.travel:
        return 0.70;
      case TransactionCategory.others:
        return 0.15;
    }
  }

  Color get color {
    switch (this) {
      case TransactionCategory.food:
        return const Color(0xFF22C55E);
      case TransactionCategory.transport:
        return const Color(0xFF38BDF8);
      case TransactionCategory.shopping:
        return const Color(0xFFA78BFA);
      case TransactionCategory.utilities:
        return const Color(0xFFFBBF24);
      case TransactionCategory.entertainment:
        return const Color(0xFFF472B6);
      case TransactionCategory.housing:
        return const Color(0xFF34D399);
      case TransactionCategory.healthcare:
        return const Color(0xFFF87171);
      case TransactionCategory.education:
        return const Color(0xFF60A5FA);
      case TransactionCategory.travel:
        return const Color(0xFFFB923C);
      case TransactionCategory.others:
        return const Color(0xFFA7F3D0);
    }
  }

  Color get backgroundColor => color.withOpacity(0.14);
}

class EcoTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionCategory category;
  final DateTime date;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EcoTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  double get co2Kg => amount * category.emissionFactor;

  CarbonLevel get carbonLevel {
    if (co2Kg < 10) return CarbonLevel.low;
    if (co2Kg < 40) return CarbonLevel.medium;
    return CarbonLevel.high;
  }

  EcoTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionCategory? category,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EcoTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category.storageValue,
      'categoryLabel': category.label,
      'date': Timestamp.fromDate(date),
      'note': note,
      'emissionFactor': category.emissionFactor,
      'co2Kg': co2Kg,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory EcoTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['date'];
    final createdTimestamp = data['createdAt'];
    final updatedTimestamp = data['updatedAt'];

    return EcoTransaction(
      id: document.id,
      title: (data['title'] ?? 'Untitled expense').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: TransactionCategoryX.fromStorageValue(data['category'] as String?),
      date: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      note: (data['note'] ?? '').toString(),
      createdAt: createdTimestamp is Timestamp ? createdTimestamp.toDate() : null,
      updatedAt: updatedTimestamp is Timestamp ? updatedTimestamp.toDate() : null,
    );
  }
}

class CategorySummary {
  final TransactionCategory category;
  final double amount;
  final double co2Kg;

  const CategorySummary({
    required this.category,
    required this.amount,
    required this.co2Kg,
  });
}

enum CarbonLevel { low, medium, high }

extension CarbonLevelX on CarbonLevel {
  String get label {
    switch (this) {
      case CarbonLevel.low:
        return 'Low';
      case CarbonLevel.medium:
        return 'Medium';
      case CarbonLevel.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case CarbonLevel.low:
        return const Color(0xFF4ADE80);
      case CarbonLevel.medium:
        return const Color(0xFFFBBF24);
      case CarbonLevel.high:
        return const Color(0xFFF87171);
    }
  }

  Color get bgColor => color.withOpacity(0.14);
}
