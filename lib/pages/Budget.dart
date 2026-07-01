// Budget Page
import 'package:flutter/material.dart';

import '../constant/app_color.dart';
import '../model/budget.dart';
import '../services/data_service.dart';

class BudgetPage extends StatefulWidget {
  final DataService dataService;

  const BudgetPage({super.key, required this.dataService});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late TextEditingController _incomeController;
  late TextEditingController _savingsController;
  late Map<String, TextEditingController> _categoryControllers;

  // Default/ideal category limits
  final Map<String, double> _idealLimits = {
    'Food & Dining': 3000,
    'Transportation': 1000,
    'Shopping': 2000,
    'Entertainment': 1000,
    'Groceries': 1000,
    'Bills & Utilities': 2000,
    'Health & Fitness': 1000,
  };

  @override
  void initState() {
    super.initState();
    final budget = widget.dataService.budget;

    _incomeController = TextEditingController(
        text: budget.monthlyIncome.toStringAsFixed(0));
    _savingsController =
        TextEditingController(text: budget.savingsGoal.toStringAsFixed(0));

    // Create controllers for each category (pre-fill existing or ideal)
    _categoryControllers = {};
    for (final category in _idealLimits.keys) {
      final currentValue =
          budget.categoryLimits[category]?.toStringAsFixed(0) ??
              _idealLimits[category]!.toStringAsFixed(0);
      _categoryControllers[category] = TextEditingController(text: currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // nice for web
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Income',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _incomeController,
                  keyboardType: TextInputType.number,
                  style: textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    prefixText: '₹',
                    prefixStyle: TextStyle(color: AppColors.textDark),
                    hintText: 'Enter monthly income',
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Savings Goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _savingsController,
                  keyboardType: TextInputType.number,
                  style: textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    prefixText: '₹',
                    prefixStyle: TextStyle(color: AppColors.textDark),
                    hintText: 'Enter savings goal',
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Category Limits (₹)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Category Fields
                ..._categoryControllers.entries.map(
                      (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: entry.value,
                      keyboardType: TextInputType.number,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        prefixText: '₹',
                        prefixStyle:
                        const TextStyle(color: AppColors.textDark),
                        hintText:
                        'Default: ₹${_idealLimits[entry.key]!.toStringAsFixed(0)}',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveBudget,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Save Budget Settings',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveBudget() async {
    final income = double.tryParse(_incomeController.text);
    final savings = double.tryParse(_savingsController.text);

    if (income == null || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly income greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (savings == null || savings < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive savings goal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use provided or ideal values for each category
    final updatedLimits = <String, double>{};
    for (final category in _categoryControllers.keys) {
      final value = double.tryParse(_categoryControllers[category]!.text);
      if (value == null || value < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid positive limit for $category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      updatedLimits[category] = value;
    }

    final newBudget = Budget(
      monthlyIncome: income,
      categoryLimits: updatedLimits,
      savingsGoal: savings,
    );

    await widget.dataService.updateBudget(newBudget);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget settings saved successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}