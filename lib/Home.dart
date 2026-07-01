// Home Page
import 'package:expense_tracker/pages/budget.dart';
import 'package:expense_tracker/pages/dashboard.dart';
import 'package:expense_tracker/pages/expenses.dart';
import 'package:expense_tracker/pages/graph.dart';
import 'package:expense_tracker/pages/insights.dart';
import 'package:expense_tracker/services/ai_finance_service.dart';
import 'package:expense_tracker/services/add_expense.dart';
import 'package:expense_tracker/services/data_service.dart';
import 'package:flutter/material.dart';

import 'constant/app_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
      DashboardPage(
        dataService: _dataService,
        aiService: _aiService,
        onRefresh: () => setState(() {}),
      ),
      GraphPage(dataService: _dataService),
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
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Analytics',
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
      floatingActionButton: _selectedIndex == 2 ? FloatingActionButton(
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