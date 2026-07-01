// Data Service

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constant/api_key.dart';
import '../model/budget.dart';
import '../model/expense.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Expense> _expenses = [];
  List<Expense> _mockExpenses = [];
  bool _useMockData = false;

  // Gemini AI specific variables
  List<String> _cachedInsights = [];
  String _cachedInsightsMonthKey = '';
  bool _isInsightsDirty = true;

  Budget _budget = Budget(
    monthlyIncome: 20000,
    categoryLimits: {
      'Food & Dining': 5000,
      'Transportation': 2000,
      'Shopping': 3000,
      'Entertainment': 1000,
      'Groceries': 2000,
      'Bills & Utilities': 3000,
      'Health & Fitness': 2000,
    },
    savingsGoal: 2000,
  );

  List<Expense> get expenses => _useMockData
      ? List.unmodifiable(_mockExpenses)
      : List.unmodifiable(_expenses);

  Budget get budget => _budget;
  bool get useMockData => _useMockData;

  List<String> get apiKeys => ApiKeys.geminiKeys
      .where((k) => k.isNotEmpty && !k.startsWith('YOUR_API_KEY_'))
      .toList();

  /// Initialize and load saved data from SharedPreferences
  Future<void> init() async {
    await _loadExpenses();
    await _loadBudget();
    _generateMockExpenses();

    final prefs = await SharedPreferences.getInstance();
    _useMockData = prefs.getBool('useMockData') ?? false;

    // Load Cached Insights
    _cachedInsightsMonthKey = prefs.getString('cachedInsightsMonthKey') ?? '';
    _isInsightsDirty = prefs.getBool('isInsightsDirty') ?? true;
    final cachedData = prefs.getString('cachedInsights');
    if (cachedData != null) {
      try {
        _cachedInsights = List<String>.from(jsonDecode(cachedData));
      } catch (_) {
        _cachedInsights = [];
      }
    }
  }

  /// Toggle mock data mode and save selection
  Future<void> setMockMode(bool enable) async {
    _useMockData = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useMockData', enable);
    markInsightsDirty();
  }

  /// Add new expense and persist data (or only hold in-memory if in mock mode)
  Future<void> addExpense(Expense expense) async {
    if (_useMockData) {
      _mockExpenses.add(expense);
      _mockExpenses.sort((a, b) => b.date.compareTo(a.date));
    } else {
      _expenses.add(expense);
      _sortExpenses();
      await _saveExpenses();
    }
    markInsightsDirty();
  }

  /// Delete expense and update saved list (or only delete from in-memory if in mock mode)
  Future<void> deleteExpense(String id) async {
    if (_useMockData) {
      _mockExpenses.removeWhere((e) => e.id == id);
    } else {
      _expenses.removeWhere((e) => e.id == id);
      await _saveExpenses();
    }
    markInsightsDirty();
  }

  Future<void> updateBudget(Budget budget) async {
    _budget = budget;
    await _saveBudget();
    markInsightsDirty();
  }

  /// Invalidate cached insights
  void markInsightsDirty() {
    _isInsightsDirty = true;
    _saveInsightsMeta();
  }

  /// Cache successfully generated insights
  Future<void> cacheInsights(List<String> insights, String monthKey) async {
    _cachedInsights = insights;
    _cachedInsightsMonthKey = monthKey;
    _isInsightsDirty = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedInsights', jsonEncode(insights));
    await prefs.setString('cachedInsightsMonthKey', monthKey);
    await prefs.setBool('isInsightsDirty', false);
  }

  /// Retrieve cached insights if valid
  List<String> getCachedInsights(String monthKey) {
    if (_isInsightsDirty || _cachedInsightsMonthKey != monthKey) {
      return []; // Cache is dirty or month changed
    }
    return _cachedInsights;
  }

  Future<void> _saveInsightsMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInsightsDirty', _isInsightsDirty);
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> getMonthExpenses() {
    final now = DateTime.now();
    final list = _useMockData ? _mockExpenses : _expenses;
    return list
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  /// 🔹 Save all expenses as JSON in SharedPreferences
  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _expenses.map((e) => e.toJson()).toList();
    prefs.setString('expenses', jsonEncode(jsonList));
  }

  /// 🔹 Load expenses from SharedPreferences
  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('expenses');
    if (data != null) {
      final decoded = jsonDecode(data) as List<dynamic>;
      _expenses = decoded.map((e) => Expense.fromJson(e)).toList();
      _sortExpenses();
    }
  }

  /// 🔹 Save budget in SharedPreferences
  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('budget', jsonEncode(_budget.toJson()));
  }

  /// 🔹 Load budget from SharedPreferences
  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('budget');
    if (data != null) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        _budget = Budget.fromJson(decoded);
      } catch (_) {
        // Fallback to default budget if decoding fails
      }
    }
  }

  /// 🔹 Generate mock data for user convenience
  void _generateMockExpenses() {
    final now = DateTime.now();
    _mockExpenses = [
      Expense(
        id: 'mock1',
        title: 'Apartment Rent',
        amount: 8000.0,
        date: DateTime(now.year, now.month, 1),
        category: 'Bills & Utilities',
        notes: 'Monthly apartment rent payment',
      ),
      Expense(
        id: 'mock2',
        title: 'Weekly Supermarket',
        amount: 1200.0,
        date: DateTime(now.year, now.month, 3),
        category: 'Groceries',
        notes: 'Vegetables and dairy items',
      ),
      Expense(
        id: 'mock3',
        title: 'Uber to Office',
        amount: 250.0,
        date: DateTime(now.year, now.month, 4),
        category: 'Transportation',
      ),
      Expense(
        id: 'mock4',
        title: 'Starbucks Coffee',
        amount: 350.0,
        date: DateTime(now.year, now.month, 5),
        category: 'Food & Dining',
        notes: 'Caramel Macchiato with friends',
      ),
      Expense(
        id: 'mock5',
        title: 'Netflix Premium',
        amount: 650.0,
        date: DateTime(now.year, now.month, 6),
        category: 'Entertainment',
      ),
      Expense(
        id: 'mock6',
        title: 'Gym Membership',
        amount: 1000.0,
        date: DateTime(now.year, now.month, 7),
        category: 'Health & Fitness',
        notes: 'Monthly gym subscription',
      ),
      Expense(
        id: 'mock7',
        title: 'Amazon Shopping',
        amount: 2450.0,
        date: DateTime(now.year, now.month, 9),
        category: 'Shopping',
        notes: 'Wireless charger and phone stand',
      ),
      Expense(
        id: 'mock8',
        title: 'Dominos Pizza Party',
        amount: 850.0,
        date: DateTime(now.year, now.month, 11),
        category: 'Food & Dining',
      ),
      Expense(
        id: 'mock9',
        title: 'Metro SmartCard Recharge',
        amount: 500.0,
        date: DateTime(now.year, now.month, 14),
        category: 'Transportation',
      ),
      Expense(
        id: 'mock10',
        title: 'Local Groceries',
        amount: 450.0,
        date: DateTime(now.year, now.month, 16),
        category: 'Groceries',
      ),
      Expense(
        id: 'mock11',
        title: 'Movie Night Ticket',
        amount: 400.0,
        date: DateTime(now.year, now.month, 18),
        category: 'Entertainment',
      ),
      Expense(
        id: 'mock12',
        title: 'Pharmacy Medicine',
        amount: 320.0,
        date: DateTime(now.year, now.month, 20),
        category: 'Health & Fitness',
      ),
      Expense(
        id: 'mock13',
        title: 'Electricity Bill',
        amount: 1500.0,
        date: DateTime(now.year, now.month, 21),
        category: 'Bills & Utilities',
      ),
      Expense(
        id: 'mock14',
        title: 'Zara T-Shirt',
        amount: 1200.0,
        date: DateTime(now.year, now.month, 23),
        category: 'Shopping',
      ),
      Expense(
        id: 'mock15',
        title: 'Dine-out Cafe',
        amount: 1200.0,
        date: DateTime(now.year, now.month - 1, 15),
        category: 'Food & Dining',
      ),
      Expense(
        id: 'mock16',
        title: 'Internet Broadband Bill',
        amount: 800.0,
        date: DateTime(now.year, now.month - 1, 20),
        category: 'Bills & Utilities',
      ),
    ];
    _mockExpenses.sort((a, b) => b.date.compareTo(a.date));
  }
}
