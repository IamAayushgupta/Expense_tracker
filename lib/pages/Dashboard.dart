// Dashboard Page
import 'package:flutter/material.dart';

import '../constant/app_color.dart';
import '../services/ai_finance_service.dart';
import '../services/data_service.dart';

class DashboardPage extends StatefulWidget {
  final DataService dataService;
  final AIFinanceService aiService;
  final VoidCallback onRefresh;

  const DashboardPage({
    super.key,
    required this.dataService,
    required this.aiService,
    required this.onRefresh,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<String>> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadInsights();
  }

  void _loadInsights() {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month}';
    final cached = widget.dataService.getCachedInsights(currentMonthKey);

    if (cached.isNotEmpty) {
      _insightsFuture = Future.value(cached);
    } else if (widget.dataService.apiKeys.isEmpty) {
      // Fallback to static rule-based insights if key is empty
      final staticInsights = widget.aiService.generateStaticInsights(
        widget.dataService.expenses,
        widget.dataService.budget,
      );
      _insightsFuture = Future.value(staticInsights);
    } else {
      // Fetch real insights asynchronously
      _insightsFuture = widget.aiService.generateRealInsights(
        expenses: widget.dataService.expenses,
        budget: widget.dataService.budget,
        apiKeys: widget.dataService.apiKeys,
      ).then((res) async {
        await widget.dataService.cacheInsights(res, currentMonthKey);
        return res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthExpenses = widget.dataService.getMonthExpenses();
    final totalSpent = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final budget = widget.dataService.budget;
    final remaining = budget.monthlyIncome - totalSpent;

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
            // Demo Mode Switch Card
            Card(
              elevation: 0,
              color: widget.dataService.useMockData
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: widget.dataService.useMockData
                      ? AppColors.primary
                      : AppColors.textDark.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Demo Mode (Mock Data)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  widget.dataService.useMockData
                      ? 'Displaying mock transactions. Actual database is safe.'
                      : 'Show sample transactions to test graphs and insights.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                ),
                value: widget.dataService.useMockData,
                activeTrackColor: AppColors.primary,
                activeThumbColor: Colors.white,
                onChanged: (bool value) async {
                  await widget.dataService.setMockMode(value);
                  widget.onRefresh();
                },
              ),
            ),
            const SizedBox(height: 16),

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
                    color: AppColors.primary.withValues(alpha: 0.3),
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
                      color: AppColors.textLight.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${remaining.toStringAsFixed(2)}',
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
                                color: AppColors.textLight.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${budget.monthlyIncome.toStringAsFixed(0)}',
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
                                color: AppColors.textLight.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalSpent.toStringAsFixed(0)}',
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
            FutureBuilder<List<String>>(
              future: _insightsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                final insights = snapshot.data ?? [];

                if (insights.isEmpty) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No insights available yet.',
                        style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6)),
                      ),
                    ),
                  );
                }

                final showKeyBanner = widget.dataService.apiKeys.isEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showKeyBanner)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                        child: Text(
                          '💡 Tip: Configure Gemini API Keys in settings to unlock real AI analysis.',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textDark.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
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
                  ],
                );
              },
            ),

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
            if (monthExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(
                  'No expenses recorded this month.',
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...monthExpenses.take(5).map((expense) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
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
                    style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6)),
                  ),
                  trailing: Text(
                    '₹${expense.amount.toStringAsFixed(2)}',
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