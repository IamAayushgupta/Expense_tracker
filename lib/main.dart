// main.dart
import 'package:expense_tracker/services/data_service.dart';
import 'package:flutter/material.dart';
import 'expense_tracker_app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataService().init(); // 👈 Load saved expenses before app starts
  runApp(const ExpenseTrackerApp());
}


