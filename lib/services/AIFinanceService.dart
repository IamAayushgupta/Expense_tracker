// AI Service - Intelligent Categorization & Insights
import '../model/expense.dart';
import 'budget.dart';

class AIFinanceService {
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

  // Generate spending insights
  List<String> generateInsights(List<Expense> expenses, Budget budget) {
    final insights = <String>[];
    final now = DateTime.now();
    final thisMonth = expenses.where((e) =>
    e.date.year == now.year && e.date.month == now.month
    ).toList();

    if (thisMonth.isEmpty) {
      insights.add('🎯 Start tracking expenses to get personalized insights!');
      return insights;
    }

    // Calculate category spending
    final categorySpending = <String, double>{};
    for (var expense in thisMonth) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    final totalSpent = thisMonth.fold<double>(0, (sum, e) => sum + e.amount);

    // Insight 1: Overall spending vs income
    final spendingPercent = (totalSpent / budget.monthlyIncome * 100).toStringAsFixed(1);
    if (totalSpent > budget.monthlyIncome * 0.8) {
      insights.add('⚠️ You\'ve spent $spendingPercent% of your monthly income. Consider reducing expenses.');
    } else {
      insights.add('✅ Good job! You\'ve spent $spendingPercent% of your monthly income.');
    }

    // Insight 2: Savings progress
    final saved = budget.monthlyIncome - totalSpent;
    if (saved >= budget.savingsGoal) {
      insights.add('🎉 Congratulations! You\'ve met your savings goal of \₹${budget.savingsGoal.toStringAsFixed(0)}!');
    } else {
      final remaining = budget.savingsGoal - saved;
      insights.add('💰 Save \₹${remaining.toStringAsFixed(0)} more to reach your monthly goal.');
    }

    // Insight 3: Top spending category
    if (categorySpending.isNotEmpty) {
      final topCategory = categorySpending.entries.reduce((a, b) =>
      a.value > b.value ? a : b
      );
      insights.add('📊 ${topCategory.key} is your top spending category at \₹${topCategory.value.toStringAsFixed(0)}.');
    }

    // Insight 4: Budget alerts
    budget.categoryLimits.forEach((category, limit) {
      final spent = categorySpending[category] ?? 0;
      if (spent > limit) {
        insights.add('🚨 You\'ve exceeded your ${category} budget by \₹${(spent - limit).toStringAsFixed(0)}!');
      }
    });

    // Insight 5: Spending patterns
    final avgDaily = totalSpent / now.day;
    final projectedMonthly = avgDaily * 30;
    if (projectedMonthly > budget.monthlyIncome) {
      insights.add('📈 At your current pace, you\'ll overspend by \₹${(projectedMonthly - budget.monthlyIncome).toStringAsFixed(0)} this month.');
    }

    return insights;
  }

  // Generate optimization suggestions
  List<String> generateOptimizations(List<Expense> expenses, Budget budget) {
    final suggestions = <String>[];
    final now = DateTime.now();
    final thisMonth = expenses.where((e) =>
    e.date.year == now.year && e.date.month == now.month
    ).toList();

    if (thisMonth.isEmpty) return suggestions;

    final categorySpending = <String, double>{};
    for (var expense in thisMonth) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Food & Dining optimization
    final foodSpending = categorySpending['Food & Dining'] ?? 0;
    if (foodSpending > budget.monthlyIncome * 0.15) {
      suggestions.add('🍽️ Consider meal prepping to reduce dining expenses. Could save \₹${(foodSpending * 0.3).toStringAsFixed(0)}/month.');
    }

    // Transportation optimization
    final transportSpending = categorySpending['Transportation'] ?? 0;
    if (transportSpending > budget.monthlyIncome * 0.10) {
      suggestions.add('🚗 Explore carpooling or public transit options to cut transportation costs.');
    }

    // Entertainment optimization
    final entertainmentSpending = categorySpending['Entertainment'] ?? 0;
    if (entertainmentSpending > budget.monthlyIncome * 0.10) {
      suggestions.add('🎬 Look for free entertainment alternatives or share subscriptions with family.');
    }

    // Shopping optimization
    final shoppingSpending = categorySpending['Shopping'] ?? 0;
    if (shoppingSpending > budget.monthlyIncome * 0.15) {
      suggestions.add('🛍️ Try the 24-hour rule: wait a day before non-essential purchases.');
    }

    return suggestions;
  }
}