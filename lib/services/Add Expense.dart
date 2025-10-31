// Add Expense Sheet
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constant/AppColor.dart';
import '../model/expense.dart';
import 'AIFinanceService.dart';

class AddExpenseSheet extends StatefulWidget {
  final Function(Expense) onAdd;
  final AIFinanceService aiService;

  const AddExpenseSheet({
    Key? key,
    required this.onAdd,
    required this.aiService,
  }) : super(key: key);

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Other';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add Expense',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textDark),
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g., Starbucks coffee',
              prefixIcon: Icon(Icons.edit, color: AppColors.primary),
            ),
            onChanged: (_) => _autoDetectCategory(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textDark),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹',
              hintText: '0.00',
              prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            style: const TextStyle(color: AppColors.textDark),
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category, color: AppColors.primary),
            ),
            items: AIFinanceService.categoryKeywords.keys
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            style: const TextStyle(color: AppColors.textDark),
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any additional details',
              prefixIcon: Icon(Icons.notes, color: AppColors.primary),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Add Expense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _autoDetectCategory() {
    final detectedCategory = widget.aiService.detectCategory(
      _titleController.text,
      _notesController.text,
    );
    if (detectedCategory != 'Other' && _selectedCategory == 'Other') {
      setState(() => _selectedCategory = detectedCategory);
    }
  }

  void _addExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    widget.onAdd(expense);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense added successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}