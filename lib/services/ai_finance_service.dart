// AI Service - Intelligent Categorization & Insights
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constant/api_key.dart';
import '../model/budget.dart';
import '../model/expense.dart';

class AIFinanceService {
  int _activeKeyIndex = 0;

  // Category keywords for intelligent categorization
  static const Map<String, List<String>> categoryKeywords = {
    'Food & Dining': ['restaurant', 'food', 'cafe', 'pizza', 'burger', 'lunch', 'dinner', 'breakfast', 'starbucks', 'mcdonalds'],
    'Transportation': ['uber', 'lyft', 'gas', 'fuel', 'parking', 'taxi', 'bus', 'train', 'metro'],
    'Shopping': ['amazon', 'store', 'mall', 'shop', 'clothing', 'electronics', 'retail'],
    'Entertainment': ['movie', 'cinema', 'netflix', 'spotify', 'game', 'concert', 'theater'],
    'Bills & Utilities': ['electric', 'water', 'internet', 'phone', 'rent', 'mortgage', 'insurance'],
    'Health & Fitness': ['gym', 'doctor', 'pharmacy', 'hospital', 'medicine', 'fitness'],
    'Groceries': ['grocery', 'supermarket', 'walmart', 'target', 'market', 'vegetables'],
    'Other': [],
  };

  // AI-powered category detection
  String detectCategory(String title, String? notes) {
    final text = '${title.toLowerCase()} ${notes?.toLowerCase() ?? ''}'.trim();

    for (var entry in categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Other';
  }

  // Generate real dynamic insights using Gemini API with Key Pooling
  Future<List<String>> generateRealInsights({
    required List<Expense> expenses,
    required Budget budget,
    required List<String> apiKeys,
  }) async {
    if (apiKeys.isEmpty) {
      return [
        '🔑 Real AI Insights deactivated.',
        '💡 Enter one or more Gemini API Keys in Budget Settings to get personalized advice.'
      ];
    }

    final now = DateTime.now();
    final thisMonth = expenses.where((e) =>
      e.date.year == now.year && e.date.month == now.month
    ).toList();

    if (thisMonth.isEmpty) {
      return ['🎯 Start tracking expenses in Demo or Personal mode to get AI insights!'];
    }

    // Build data summary for the prompt
    final totalSpent = thisMonth.fold<double>(0, (sum, e) => sum + e.amount);
    final categorySpending = <String, double>{};
    for (var e in thisMonth) {
      categorySpending[e.category] = (categorySpending[e.category] ?? 0) + e.amount;
    }

    final budgetAlerts = <String>[];
    budget.categoryLimits.forEach((cat, limit) {
      final spent = categorySpending[cat] ?? 0;
      if (spent > limit) {
        budgetAlerts.add('$cat (Spent ₹${spent.toStringAsFixed(0)} vs Limit ₹${limit.toStringAsFixed(0)})');
      }
    });

    final recentTx = thisMonth.take(10).map((e) => '- ${e.title}: ₹${e.amount} (${e.category})').join('\n');

    final prompt = '''
You are a personal financial advisor AI.
Here is the financial data for this month:
- Monthly Income: ₹${budget.monthlyIncome.toStringAsFixed(0)}
- Savings Goal: ₹${budget.savingsGoal.toStringAsFixed(0)}
- Total Spent: ₹${totalSpent.toStringAsFixed(0)}
- Category Spending: $categorySpending
- Budget Exceeded Categories: $budgetAlerts
- Recent Transactions:
$recentTx

Analyze this data and provide exactly 4 concise, highly actionable financial insights or optimization tips.
Rules:
1. Return exactly 4 insights.
2. Format them as a list of strings, with each item starting with an appropriate emoji.
3. Keep each tip short (under 2 sentences) and directly related to the user's spending data.
4. Output them separated by newline characters (e.g., each insight on a new line).
''';

    // Key Rotation Pooling Loop
    int attempts = 0;
    int keyIndex = _activeKeyIndex;

    while (attempts < apiKeys.length) {
      final apiKey = apiKeys[keyIndex % apiKeys.length];
      try {
        final model = GenerativeModel(
          model: ApiKeys.geminiModel,
          apiKey: apiKey,
        );

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;

        if (text != null && text.isNotEmpty) {
          // Save successful key index
          _activeKeyIndex = keyIndex % apiKeys.length;

          // Parse response into lines
          final lines = text
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .map((l) {
                var cleaned = l;
                if (cleaned.startsWith('- ')) {
                  cleaned = cleaned.substring(2);
                } else if (cleaned.startsWith('* ')) {
                  cleaned = cleaned.substring(2);
                } else if (RegExp(r'^\d+\.\s').hasMatch(cleaned)) {
                  cleaned = cleaned.replaceFirst(RegExp(r'^\d+\.\s'), '');
                }
                return cleaned;
              })
              .toList();

          if (lines.isNotEmpty) {
            return lines.take(4).toList();
          }
        }
      } catch (e) {
        debugPrint('Gemini call failed with key index $keyIndex. Error: $e. Rotating...');
      }

      keyIndex++;
      attempts++;
    }

    // Fallback if all keys fail or get rate limited
    return [
      '🚨 All Gemini API keys failed or rate-limited. Rotating to backups failed.',
      '💡 Tip: Free tier keys are limited to 15 Requests Per Minute. Try again shortly.'
    ];
  }

  // Generate spending insights (Static fallback rules for mock / test safety)
  List<String> generateStaticInsights(List<Expense> expenses, Budget budget) {
    final insights = <String>[];
    final now = DateTime.now();
    final thisMonth = expenses.where((e) =>
    e.date.year == now.year && e.date.month == now.month
    ).toList();

    if (thisMonth.isEmpty) {
      insights.add('🎯 Start tracking expenses to get personalized insights!');
      return insights;
    }

    final categorySpending = <String, double>{};
    for (var expense in thisMonth) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    final totalSpent = thisMonth.fold<double>(0, (sum, e) => sum + e.amount);

    if (budget.monthlyIncome <= 0) {
      insights.add('⚠️ Please set a valid positive monthly income in Budget Settings.');
    } else {
      final spendingPercent = (totalSpent / budget.monthlyIncome * 100).toStringAsFixed(1);
      if (totalSpent > budget.monthlyIncome * 0.8) {
        insights.add('⚠️ You\'ve spent $spendingPercent% of your monthly income. Consider reducing expenses.');
      } else {
        insights.add('✅ Good job! You\'ve spent $spendingPercent% of your monthly income.');
      }
    }

    final saved = budget.monthlyIncome - totalSpent;
    if (saved >= budget.savingsGoal) {
      insights.add('🎉 Congratulations! You\'ve met your savings goal of ₹${budget.savingsGoal.toStringAsFixed(0)}!');
    } else {
      final remaining = budget.savingsGoal - saved;
      insights.add('💰 Save ₹${remaining.toStringAsFixed(0)} more to reach your monthly goal.');
    }

    if (categorySpending.isNotEmpty) {
      final topCategory = categorySpending.entries.reduce((a, b) =>
      a.value > b.value ? a : b
      );
      insights.add('📊 ${topCategory.key} is your top spending category at ₹${topCategory.value.toStringAsFixed(0)}.');
    }

    budget.categoryLimits.forEach((category, limit) {
      final spent = categorySpending[category] ?? 0;
      if (spent > limit) {
        insights.add('🚨 You\'ve exceeded your $category budget by ₹${(spent - limit).toStringAsFixed(0)}!');
      }
    });

    final avgDaily = totalSpent / now.day;
    final projectedMonthly = avgDaily * 30;
    if (budget.monthlyIncome > 0 && projectedMonthly > budget.monthlyIncome) {
      insights.add('📈 At your current pace, you\'ll overspend by ₹${(projectedMonthly - budget.monthlyIncome).toStringAsFixed(0)} this month.');
    }

    return insights;
  }

  // Generate optimization suggestions (Static fallback rules)
  List<String> generateStaticOptimizations(List<Expense> expenses, Budget budget) {
    final suggestions = <String>[];
    final now = DateTime.now();
    final thisMonth = expenses.where((e) =>
    e.date.year == now.year && e.date.month == now.month
    ).toList();

    if (thisMonth.isEmpty || budget.monthlyIncome <= 0) return suggestions;

    final categorySpending = <String, double>{};
    for (var expense in thisMonth) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    final foodSpending = categorySpending['Food & Dining'] ?? 0;
    if (foodSpending > budget.monthlyIncome * 0.15) {
      suggestions.add('🍽️ Consider meal prepping to reduce dining expenses. Could save ₹${(foodSpending * 0.3).toStringAsFixed(0)}/month.');
    }

    final transportSpending = categorySpending['Transportation'] ?? 0;
    if (transportSpending > budget.monthlyIncome * 0.10) {
      suggestions.add('🚗 Explore carpooling or public transit options to cut transportation costs.');
    }

    final entertainmentSpending = categorySpending['Entertainment'] ?? 0;
    if (entertainmentSpending > budget.monthlyIncome * 0.10) {
      suggestions.add('🎬 Look for free entertainment alternatives or share subscriptions with family.');
    }

    final shoppingSpending = categorySpending['Shopping'] ?? 0;
    if (shoppingSpending > budget.monthlyIncome * 0.15) {
      suggestions.add('🛍️ Try the 24-hour rule: wait a day before non-essential purchases.');
    }

    return suggestions;
  }
}