// Insights Page
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constant/AppColor.dart';
import '../services/AIFinanceService.dart';
import '../services/DataService.dart';

class InsightsPage extends StatelessWidget {
  final DataService dataService;
  final AIFinanceService aiService;

  const InsightsPage({
    Key? key,
    required this.dataService,
    required this.aiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final insights = aiService.generateInsights(dataService.expenses, dataService.budget);
    final optimizations = aiService.generateOptimizations(dataService.expenses, dataService.budget);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Insights & Tips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Financial Health',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  insight,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            )),

            if (optimizations.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Smart Savings Tips',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ...optimizations.map((tip) => Card(
                color: AppColors.primary.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}