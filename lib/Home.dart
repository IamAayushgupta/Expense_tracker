// Home Page
import 'package:expense_tracker/pages/Budget.dart';
import 'package:expense_tracker/pages/Dashboard.dart';
import 'package:expense_tracker/pages/Expenses.dart';
import 'package:expense_tracker/pages/Insights.dart';
import 'package:expense_tracker/services/AIFinanceService.dart';
import 'package:expense_tracker/services/Add%20Expense.dart';
import 'package:expense_tracker/services/DataService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'constant/AppColor.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _dataService = DataService();
  final _aiService = AIFinanceService();

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(dataService: _dataService, aiService: _aiService),
      ExpensesPage(dataService: _dataService, aiService: _aiService),
      InsightsPage(dataService: _dataService, aiService: _aiService),
      BudgetPage(dataService: _dataService),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppColors.cardBackground,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb, color: AppColors.primary),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
            label: 'Budget',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1 ? FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddExpenseSheet(
        onAdd: (expense) async {
          await _dataService.addExpense(expense);
          setState(() {});
        },
        aiService: _aiService,
      ),
    );
  }
}