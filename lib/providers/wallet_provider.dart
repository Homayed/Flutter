import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:carbon_emmision_app/models/transaction.dart';
import 'package:carbon_emmision_app/services/firebase_connection.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider();

  static const double defaultCarbonBudget = 170.0;
  static const double defaultSpendingBudget = 650.0;
  static const double defaultMonthlyBenchmark = 1200.0;
  static const double treeAnnualAbsorptionKg = 21.0;

  final FirebaseFirestore? _firestore = FirebaseConnection.isEnabled
      ? FirebaseFirestore.instance
      : null;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _transactionsSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSubscription;

  String? _boundUid;
  bool _isLoading = false;
  String? _backendError;

  double _monthlyCarbonBudget = defaultCarbonBudget;
  double _monthlySpendingBudget = defaultSpendingBudget;
  double _monthlyAverageSpendingBenchmark = defaultMonthlyBenchmark;
  TransactionCategory? _filterCategory;
  String _searchQuery = '';

  final List<EcoTransaction> _transactions = List<EcoTransaction>.from(_demoTransactions());

  bool get isFirebaseEnabled => FirebaseConnection.isEnabled;
  bool get isLoading => _isLoading;
  String? get backendError => _backendError;
  double get monthlyCarbonBudget => _monthlyCarbonBudget;
  double get monthlySpendingBudget => _monthlySpendingBudget;
  double get monthlyAverageSpendingBenchmark => _monthlyAverageSpendingBenchmark;
  TransactionCategory? get filterCategory => _filterCategory;
  String get searchQuery => _searchQuery;

  void bindUser(String? uid) {
    if (!FirebaseConnection.isEnabled) return;
    if (_boundUid == uid) return;

    _transactionsSubscription?.cancel();
    _settingsSubscription?.cancel();
    _boundUid = uid;

    if (uid == null) {
      _transactions
        ..clear()
        ..addAll(_demoTransactions());
      _monthlySpendingBudget = defaultSpendingBudget;
      _monthlyCarbonBudget = defaultCarbonBudget;
      _monthlyAverageSpendingBenchmark = defaultMonthlyBenchmark;
      _isLoading = false;
      _backendError = null;
      notifyListeners();
      return;
    }

    _listenToFirestore(uid);
  }

  List<EcoTransaction> get allTransactions {
    final items = List<EcoTransaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<EcoTransaction> get visibleTransactions {
    final query = _searchQuery.trim().toLowerCase();
    return allTransactions.where((transaction) {
      final matchesCategory =
          _filterCategory == null || transaction.category == _filterCategory;
      final matchesQuery = query.isEmpty ||
          transaction.title.toLowerCase().contains(query) ||
          transaction.category.label.toLowerCase().contains(query) ||
          transaction.note.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  double get totalSpent => _transactions.fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalCO2 => _transactions.fold(0.0, (sum, tx) => sum + tx.co2Kg);

  double get averageCO2PerTransaction =>
      _transactions.isEmpty ? 0 : totalCO2 / _transactions.length;

  double get averageSpendingPerTransaction =>
      _transactions.isEmpty ? 0 : totalSpent / _transactions.length;

  double get carbonBudgetProgress => _monthlyCarbonBudget == 0
      ? 0
      : (totalCO2 / _monthlyCarbonBudget).clamp(0.0, 1.0);

  double get spendingBudgetProgress => _monthlySpendingBudget == 0
      ? 0
      : (totalSpent / _monthlySpendingBudget).clamp(0.0, 1.0);

  double get spendingBenchmarkProgress => _monthlyAverageSpendingBenchmark == 0
      ? 0
      : (totalSpent / _monthlyAverageSpendingBenchmark).clamp(0.0, 1.0);

  bool get isAboveAverageMonthlySpending =>
      totalSpent > _monthlyAverageSpendingBenchmark;

  double get spendingBenchmarkDifference =>
      totalSpent - _monthlyAverageSpendingBenchmark;

  String get monthlySpendingBenchmarkTitle =>
      isAboveAverageMonthlySpending ? 'Above monthly average' : 'Below monthly average';

  String get monthlySpendingBenchmarkMessage {
    final difference = spendingBenchmarkDifference.abs();
    if (isAboveAverageMonthlySpending) {
      return 'You are RM ${difference.toStringAsFixed(2)} above the monthly benchmark. Review your highest categories before adding new expenses.';
    }
    return 'You are RM ${difference.toStringAsFixed(2)} below the monthly benchmark. Keep tracking daily expenses to stay in control.';
  }

  double get remainingCarbonBudget =>
      (_monthlyCarbonBudget - totalCO2).clamp(0.0, double.infinity);

  double get remainingSpendingBudget =>
      (_monthlySpendingBudget - totalSpent).clamp(0.0, double.infinity);

  String get carbonScore {
    final progress = carbonBudgetProgress;
    if (progress <= 0.35) return 'A+';
    if (progress <= 0.55) return 'A';
    if (progress <= 0.75) return 'B';
    if (progress <= 0.90) return 'C';
    return 'D';
  }

  String get scoreMessage {
    switch (carbonScore) {
      case 'A+':
        return 'Excellent! Your footprint is far below the monthly limit.';
      case 'A':
        return 'Great progress. Keep choosing low-carbon options.';
      case 'B':
        return 'Good, but transport and utilities can still improve.';
      case 'C':
        return 'You are close to the limit. Review high-emission categories.';
      default:
        return 'High footprint this month. Try reducing travel and shopping.';
    }
  }

  EcoTransaction? get highestEmissionTransaction {
    if (_transactions.isEmpty) return null;
    final sorted = List<EcoTransaction>.from(_transactions)
      ..sort((a, b) => b.co2Kg.compareTo(a.co2Kg));
    return sorted.first;
  }

  List<CategorySummary> get categorySummaries {
    final summaries = <TransactionCategory, CategorySummary>{};
    for (final tx in _transactions) {
      final previous = summaries[tx.category];
      summaries[tx.category] = CategorySummary(
        category: tx.category,
        amount: (previous?.amount ?? 0) + tx.amount,
        co2Kg: (previous?.co2Kg ?? 0) + tx.co2Kg,
      );
    }

    final list = summaries.values.toList()
      ..sort((a, b) => b.co2Kg.compareTo(a.co2Kg));
    return list;
  }

  Map<TransactionCategory, double> get co2ByCategory {
    return {
      for (final summary in categorySummaries) summary.category: summary.co2Kg,
    };
  }

  List<double> get weeklyCO2 {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      return _transactions.where((tx) {
        final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return date == day;
      }).fold(0.0, (sum, tx) => sum + tx.co2Kg);
    });
  }

  List<double> get weeklySpending {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      return _transactions.where((tx) {
        final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return date == day;
      }).fold(0.0, (sum, tx) => sum + tx.amount);
    });
  }

  List<double> get weeklyTransactionCounts {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      return _transactions.where((tx) {
        final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return date == day;
      }).length.toDouble();
    });
  }

  List<String> get lastSevenDayLabels {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return labels[day.weekday - 1];
    });
  }

  List<CategorySummary> get topSpendingCategories {
    final list = List<CategorySummary>.from(categorySummaries)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  List<double> get topCategoryCO2Values =>
      categorySummaries.take(5).map((summary) => summary.co2Kg).toList();

  List<String> get topCategoryLabels =>
      categorySummaries.take(5).map((summary) => summary.category.emoji).toList();

  List<double> get topCategorySpendingValues =>
      topSpendingCategories.take(5).map((summary) => summary.amount).toList();

  List<String> get topCategorySpendingLabels =>
      topSpendingCategories.take(5).map((summary) => summary.category.emoji).toList();

  double get highestWeeklySpending => weeklySpending.fold(
        0.0,
        (highest, value) => value > highest ? value : highest,
      );

  double get averageDailySpendingFromHistory => weeklySpending.isEmpty
      ? 0
      : weeklySpending.fold(0.0, (sum, value) => sum + value) /
          weeklySpending.length;

  int get treesRequiredToOffsetMonthlyCO2 {
    if (totalCO2 <= 0) return 0;
    return (totalCO2 / treeAnnualAbsorptionKg).ceil();
  }

  double get estimatedTreeOffsetKg =>
      treesRequiredToOffsetMonthlyCO2 * treeAnnualAbsorptionKg;

  double get treeOffsetProgress => totalCO2 == 0
      ? 0
      : (estimatedTreeOffsetKg / totalCO2).clamp(0.0, 1.0).toDouble();

  List<double> get treeOffsetValues => [
        totalCO2,
        estimatedTreeOffsetKg,
      ];

  List<String> get treeOffsetLabels => const [
        'CO₂',
        'Trees',
      ];

  List<double> get categorySpendingValues =>
      topSpendingCategories.take(5).map((summary) => summary.amount).toList();

  List<String> get categorySpendingLabels =>
      topSpendingCategories.take(5).map((summary) => summary.category.emoji).toList();

  List<double> get categoryCarbonValues =>
      categorySummaries.take(5).map((summary) => summary.co2Kg).toList();

  List<String> get categoryCarbonLabels =>
      categorySummaries.take(5).map((summary) => summary.category.emoji).toList();

  List<String> get smartTips {
    final top = highestEmissionTransaction;
    final tips = <String>[
      'Use manual tracking daily so your dashboard stays accurate.',
      'Compare spending and CO₂ together before making purchase decisions.',
      'Public transport, walking, and grouped trips can reduce transport emissions.',
    ];

    if (top != null) {
      tips.insert(
        0,
        '${top.category.emoji} ${top.category.label} is your current biggest CO₂ source. Start reducing from there.',
      );
    }
    return tips;
  }

  Future<void> addTransaction(EcoTransaction transaction) async {
    if (_canUseFirestore) {
      try {
        final doc = _transactionsCollection.doc();
        await doc.set(transaction.copyWith(id: doc.id).toFirestore());
        return;
      } catch (error) {
        _backendError = 'Expense could not be saved to Firebase. ${error.toString()}';
        notifyListeners();
        return;
      }
    }

    _transactions.add(transaction);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    if (_canUseFirestore) {
      try {
        await _transactionsCollection.doc(id).delete();
        return;
      } catch (error) {
        _backendError = 'Expense could not be deleted from Firebase. ${error.toString()}';
        notifyListeners();
        return;
      }
    }

    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
  }

  void updateBudget(double value) {
    _monthlyCarbonBudget = value;
    notifyListeners();
    _saveSettings();
  }

  void updateSpendingBudget(double value) {
    _monthlySpendingBudget = value;
    notifyListeners();
    _saveSettings();
  }

  void updateMonthlyAverageSpendingBenchmark(double value) {
    _monthlyAverageSpendingBenchmark = value;
    notifyListeners();
    _saveSettings();
  }

  void updateSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateCategoryFilter(TransactionCategory? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    final demo = _demoTransactions();
    _monthlySpendingBudget = defaultSpendingBudget;
    _monthlyCarbonBudget = defaultCarbonBudget;
    _monthlyAverageSpendingBenchmark = defaultMonthlyBenchmark;

    if (_canUseFirestore) {
      try {
        final batch = _firestore!.batch();
        final snapshot = await _transactionsCollection.get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        for (final tx in demo) {
          final doc = _transactionsCollection.doc();
          batch.set(doc, tx.copyWith(id: doc.id).toFirestore());
        }
        batch.set(_settingsDocument, _settingsMap(), SetOptions(merge: true));
        await batch.commit();
        clearFilters();
        return;
      } catch (error) {
        _backendError = 'Demo data could not be reset in Firebase. ${error.toString()}';
        notifyListeners();
        return;
      }
    }

    _transactions
      ..clear()
      ..addAll(demo);
    clearFilters();
  }

  bool get _canUseFirestore =>
      FirebaseConnection.isEnabled && _firestore != null && _boundUid != null;

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore!.collection('users').doc(_boundUid).collection('transactions');

  DocumentReference<Map<String, dynamic>> get _settingsDocument =>
      _firestore!.collection('users').doc(_boundUid).collection('settings').doc('wallet');

  void _listenToFirestore(String uid) {
    _isLoading = true;
    _backendError = null;
    notifyListeners();

    _settingsSubscription = _settingsDocument.snapshots().listen(
      (snapshot) async {
        if (!snapshot.exists) {
          await _settingsDocument.set(_settingsMap(), SetOptions(merge: true));
          return;
        }
        final data = snapshot.data() ?? <String, dynamic>{};
        _monthlySpendingBudget =
            (data['monthlySpendingBudget'] as num?)?.toDouble() ?? defaultSpendingBudget;
        _monthlyCarbonBudget =
            (data['monthlyCarbonBudget'] as num?)?.toDouble() ?? defaultCarbonBudget;
        _monthlyAverageSpendingBenchmark =
            (data['monthlyAverageSpendingBenchmark'] as num?)?.toDouble() ?? defaultMonthlyBenchmark;
        notifyListeners();
      },
      onError: (Object error) {
        _backendError = 'Could not load budget settings from Firebase. ${error.toString()}';
        notifyListeners();
      },
    );

    _transactionsSubscription = _transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        if (snapshot.docs.isEmpty) {
          await _seedInitialDemoDataIfEmpty();
        }
        _transactions
          ..clear()
          ..addAll(snapshot.docs.map(EcoTransaction.fromFirestore));
        _isLoading = false;
        _backendError = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _backendError = 'Could not load transactions from Firebase. ${error.toString()}';
        notifyListeners();
      },
    );
  }

  Future<void> _seedInitialDemoDataIfEmpty() async {
    if (!_canUseFirestore) return;
    final snapshot = await _transactionsCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;
    final batch = _firestore!.batch();
    for (final tx in _demoTransactions()) {
      final doc = _transactionsCollection.doc();
      batch.set(doc, tx.copyWith(id: doc.id).toFirestore());
    }
    batch.set(_settingsDocument, _settingsMap(), SetOptions(merge: true));
    await batch.commit();
  }

  Map<String, dynamic> _settingsMap() {
    return {
      'monthlySpendingBudget': _monthlySpendingBudget,
      'monthlyCarbonBudget': _monthlyCarbonBudget,
      'monthlyAverageSpendingBenchmark': _monthlyAverageSpendingBenchmark,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _saveSettings() async {
    if (!_canUseFirestore) return;
    try {
      await _settingsDocument.set(_settingsMap(), SetOptions(merge: true));
    } catch (error) {
      _backendError = 'Budget settings could not be saved to Firebase. ${error.toString()}';
      notifyListeners();
    }
  }

  static List<EcoTransaction> _demoTransactions() {
    final now = DateTime.now();
    return [
      EcoTransaction(
        id: 'demo-1',
        title: 'Lunch at campus cafe',
        amount: 18.50,
        category: TransactionCategory.food,
        date: now.subtract(const Duration(hours: 4)),
        note: 'Manual expense entry',
      ),
      EcoTransaction(
        id: 'demo-2',
        title: 'MRT and bus reload',
        amount: 30.00,
        category: TransactionCategory.transport,
        date: now.subtract(const Duration(days: 1)),
        note: 'Public transport',
      ),
      EcoTransaction(
        id: 'demo-3',
        title: 'Groceries for the week',
        amount: 64.90,
        category: TransactionCategory.food,
        date: now.subtract(const Duration(days: 2)),
      ),
      EcoTransaction(
        id: 'demo-4',
        title: 'Phone and internet bill',
        amount: 89.00,
        category: TransactionCategory.utilities,
        date: now.subtract(const Duration(days: 3)),
      ),
      EcoTransaction(
        id: 'demo-5',
        title: 'Shopee essentials',
        amount: 72.20,
        category: TransactionCategory.shopping,
        date: now.subtract(const Duration(days: 4)),
      ),
      EcoTransaction(
        id: 'demo-6',
        title: 'Movie night',
        amount: 24.00,
        category: TransactionCategory.entertainment,
        date: now.subtract(const Duration(days: 5)),
      ),
      EcoTransaction(
        id: 'demo-7',
        title: 'Weekend trip booking',
        amount: 120.00,
        category: TransactionCategory.travel,
        date: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
