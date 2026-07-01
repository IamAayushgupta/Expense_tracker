// Insights Page
import 'package:flutter/material.dart';

import '../constant/app_color.dart';
import '../services/ai_finance_service.dart';
import '../services/data_service.dart';

class InsightsPage extends StatefulWidget {
  final DataService dataService;
  final AIFinanceService aiService;

  const InsightsPage({
    super.key,
    required this.dataService,
    required this.aiService,
  });

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late Future<List<String>> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _loadInsights(forceRefresh: false);
  }

  @override
  void didUpdateWidget(covariant InsightsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadInsights(forceRefresh: false);
  }

  void _loadInsights({bool forceRefresh = false}) {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month}';

    if (forceRefresh) {
      widget.dataService.markInsightsDirty();
    }

    final cached = widget.dataService.getCachedInsights(currentMonthKey);

    if (cached.isNotEmpty) {
      _insightsFuture = Future.value(cached);
    } else if (widget.dataService.apiKeys.isEmpty) {
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
    final staticOptimizations = widget.aiService.generateStaticOptimizations(
      widget.dataService.expenses,
      widget.dataService.budget,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Insights & Tips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh AI Insights',
            onPressed: () {
              setState(() {
                _loadInsights(forceRefresh: true);
              });
            },
          ),
        ],
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

            FutureBuilder<List<String>>(
              future: _insightsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                final insights = snapshot.data ?? [];

                if (insights.isEmpty) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No insights generated yet. Add more expenses!',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark.withValues(alpha: 0.6),
                        ),
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
                        padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                        child: Text(
                          '💡 Tip: Configure Gemini API Keys in settings to unlock real AI analysis.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textDark.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ...insights.map((insight) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                insight,
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
                );
              },
            ),

            if (staticOptimizations.isNotEmpty) ...[
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
              ...staticOptimizations.map((tip) => Card(
                color: AppColors.primary.withValues(alpha: 0.1),
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