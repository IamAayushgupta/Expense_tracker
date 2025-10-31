// Data Service

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/expense.dart';
import 'budget.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Expense> _expenses = [];
  int income = 10000;

  Budget _budget = Budget(
    monthlyIncome: 15000,
    categoryLimits: {
      'Food & Dining': 3000,
      'Transportation': 1000,
      'Shopping': 2000,
      'Entertainment': 1000,
      'Groceries': 1000,
    },
    savingsGoal: 1000,
  );

  List<Expense> get expenses => List.unmodifiable(_expenses);
  Budget get budget => _budget;

  /// Initialize and load saved data from SharedPreferences
  Future<void> init() async {
    await _loadExpenses();
  }

  /// Add new expense and persist data
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _sortExpenses();
    await _saveExpenses();
  }

  /// Delete expense and update saved list
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveExpenses();
  }

  void updateBudget(Budget budget) {
    _budget = budget;
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> getMonthExpenses() {
    final now = DateTime.now();
    return _expenses.where((e) =>
    e.date.year == now.year && e.date.month == now.month).toList();
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
}