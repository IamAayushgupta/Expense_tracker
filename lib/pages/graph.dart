// Analytics / Graph Page
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constant/app_color.dart';
import '../model/expense.dart';
import '../services/data_service.dart';

class GraphPage extends StatefulWidget {
  final DataService dataService;

  const GraphPage({super.key, required this.dataService});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  late DateTime _selectedMonth;
  bool _showBreakdown = true; // true = Donut Chart, false = Weekly Bar Chart
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<DateTime> _getAvailableMonths() {
    final months = <DateTime>[];
    final now = DateTime.now();
    months.add(DateTime(now.year, now.month)); // Always include current month

    for (final expense in widget.dataService.expenses) {
      final expMonth = DateTime(expense.date.year, expense.date.month);
      if (!months.any((m) => m.year == expMonth.year && m.month == expMonth.month)) {
        months.add(expMonth);
      }
    }

    // Sort latest first
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  String _formatMonthYear(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return const Color(0xFF00B686); // Mint Green
      case 'Transportation':
        return const Color(0xFF00796B); // Teal Blue
      case 'Shopping':
        return const Color(0xFFFFD54F); // Accent Yellow
      case 'Entertainment':
        return const Color(0xFFE57373); // Soft Red
      case 'Bills & Utilities':
        return const Color(0xFF4FC3F7); // Sky Blue
      case 'Health & Fitness':
        return const Color(0xFFBA68C8); // Orchid Purple
      case 'Groceries':
        return const Color(0xFF81C784); // Soft Green
      default:
        return const Color(0xFF90A4AE); // Blue Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableMonths = _getAvailableMonths();
    
    // Ensure selected month is in available months list (could have been loaded/reset)
    if (!availableMonths.any((m) => m.year == _selectedMonth.year && m.month == _selectedMonth.month)) {
      _selectedMonth = availableMonths.first;
    }

    final filteredExpenses = widget.dataService.expenses.where((e) =>
      e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month
    ).toList();

    final totalSpent = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    // Group expenses by category
    final categoryTotals = <String, double>{};
    for (final exp in filteredExpenses) {
      categoryTotals[exp.category] = (categoryTotals[exp.category] ?? 0) + exp.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spending Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Controls (Month Dropdown + Tab Toggle)
            Card(
              elevation: 0,
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Month Dropdown selector
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DateTime>(
                          value: _selectedMonth,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          items: availableMonths.map((dt) {
                            return DropdownMenuItem<DateTime>(
                              value: dt,
                              child: Text(_formatMonthYear(dt)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedMonth = val;
                                _touchedPieIndex = -1; // Reset selection
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Toggle Views
                    ChoiceChip(
                      label: const Text('Breakdown'),
                      selected: _showBreakdown,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _showBreakdown ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _showBreakdown = true);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Trends'),
                      selected: !_showBreakdown,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: !_showBreakdown ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _showBreakdown = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Empty State
            if (filteredExpenses.isEmpty)
              _buildEmptyState()
            else if (_showBreakdown)
              _buildPieChartSection(categoryTotals, totalSpent)
            else
              _buildBarChartSection(filteredExpenses, totalSpent),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 100,
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Data to Analyze',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses for ${_formatMonthYear(_selectedMonth)} to see charts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection(Map<String, double> totals, double total) {
    final sections = <PieChartSectionData>[];
    int index = 0;

    totals.forEach((category, amount) {
      final isTouched = index == _touchedPieIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percent = (amount / total * 100).toStringAsFixed(0);

      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(category),
          value: amount,
          title: '$percent%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return Column(
      children: [
        // Donut Chart Container
        Card(
          elevation: 2,
          color: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 65,
                      sections: sections,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Spent',
                        style: TextStyle(
                          color: AppColors.textDark.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Custom Premium Legend
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Categories Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...totals.entries.map((entry) {
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBarChartSection(List<Expense> expenses, double total) {
    // Weekly grouping calculation
    final weeklySpending = [0.0, 0.0, 0.0, 0.0];
    for (final exp in expenses) {
      final day = exp.date.day;
      if (day <= 7) {
        weeklySpending[0] += exp.amount;
      } else if (day <= 14) {
        weeklySpending[1] += exp.amount;
      } else if (day <= 21) {
        weeklySpending[2] += exp.amount;
      } else {
        weeklySpending[3] += exp.amount;
      }
    }

    final maxVal = weeklySpending.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 100.0 : (maxVal * 1.15);

    return Column(
      children: [
        // Bar Chart Card
        Card(
          elevation: 2,
          color: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.only(top: 24, left: 12, right: 24, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Spending Pattern',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Average Weekly: ₹${(total / 4).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: AppColors.secondary,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'Week ${groupIndex + 1}\n₹${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final style = TextStyle(
                                color: AppColors.textDark.withValues(alpha: 0.6),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text('Week ${value.toInt() + 1}', style: style),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max) return const SizedBox();
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '₹${value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: AppColors.textDark.withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.textDark.withValues(alpha: 0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(4, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: weeklySpending[i],
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 22,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Week stats cards
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Weekly Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(4, (i) {
          final rangeText = [
            'Days 1 - 7',
            'Days 8 - 14',
            'Days 15 - 21',
            'Days 22 - End'
          ][i];
          final val = weeklySpending[i];
          final percent = total > 0 ? (val / total * 100).toStringAsFixed(0) : '0';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  'W${i + 1}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                'Week ${i + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              subtitle: Text(rangeText, style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5))),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${val.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                  ),
                  Text(
                    '$percent% of month',
                    style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
