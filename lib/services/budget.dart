class Budget {
  final double monthlyIncome;
  final Map<String, double> categoryLimits;
  final double savingsGoal;

  Budget({
    required this.monthlyIncome,
    required this.categoryLimits,
    required this.savingsGoal,
  });
}