// main.dart
import 'package:expense_tracker/services/DataService.dart';
import 'package:flutter/material.dart';
import 'ExpenseTrackerApp.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataService().init(); // 👈 Load saved expenses before app starts
  runApp(const ExpenseTrackerApp());
}


