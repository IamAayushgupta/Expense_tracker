// Dashboard Page
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constant/AppColor.dart';
import '../services/AIFinanceService.dart';
import '../services/DataService.dart';

class DashboardPage extends StatelessWidget {
  final DataService dataService;
  final AIFinanceService aiService;

  const DashboardPage({
    Key? key,
    required this.dataService,
    required this.aiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthExpenses = dataService.getMonthExpenses();
    final totalSpent = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final budget = dataService.budget;
    final remaining = budget.monthlyIncome - totalSpent;
    final insights = aiService.generateInsights(dataService.expenses, budget);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Balance',
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\₹${remaining.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\₹${budget.monthlyIncome.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spent',
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\₹${totalSpent.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Insights
            const Text(
              'AI Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...insights.map((insight) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 24),

            // Recent Expenses
            const Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...monthExpenses.take(5).map((expense) => Card(
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
                  expense.category,
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
              ),
            )),
          ],
        ),
      ),
    );
  }
}