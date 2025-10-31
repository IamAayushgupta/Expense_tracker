// Expenses Page
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constant/AppColor.dart';
import '../services/AIFinanceService.dart';
import '../services/DataService.dart';

class ExpensesPage extends StatelessWidget {
  final DataService dataService;
  final AIFinanceService aiService;

  const ExpensesPage({
    Key? key,
    required this.dataService,
    required this.aiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenses = dataService.expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Expenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: expenses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: TextStyle(
                color: AppColors.textDark.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first expense',
              style: TextStyle(color: AppColors.textDark.withOpacity(0.5)),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        itemBuilder: (ctx, i) {
          final expense = expenses[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  expense.category[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                expense.title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${expense.category} • ${_formatDate(expense.date)}',
                style: TextStyle(color: AppColors.textDark.withOpacity(0.6)),
              ),
              trailing: Text(
                '\₹${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.secondary,
                ),
              ),
              onLongPress: () => _showDeleteDialog(context, expense.id),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Expense',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: const Text(
          'Are you sure you want to delete this expense?',
          style: TextStyle(color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              await dataService.deleteExpense(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense deleted'), backgroundColor: AppColors.secondary),
              );
              (context as Element).markNeedsBuild(); // To refresh the list
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}