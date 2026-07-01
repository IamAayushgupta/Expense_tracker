class Budget {
  final double monthlyIncome;
  final Map<String, double> categoryLimits;
  final double savingsGoal;

  Budget({
    required this.monthlyIncome,
    required this.categoryLimits,
    required this.savingsGoal,
  });

  Map<String, dynamic> toJson() => {
    'monthlyIncome': monthlyIncome,
    'categoryLimits': categoryLimits,
    'savingsGoal': savingsGoal,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
    categoryLimits: Map<String, double>.from(
      (json['categoryLimits'] as Map<dynamic, dynamic>).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    ),
    savingsGoal: (json['savingsGoal'] as num).toDouble(),
  );
}