import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../firestore_service.dart';
import '../settings_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentLanguage,
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.get('chart_title'))),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getTransactionsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text(AppStrings.get('no_data')));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final data = snapshot.data!.docs;
              Map<String, double> categoryTotals = {};
              double totalExpense = 0;

              for (var doc in data) {
                Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
                if (map['isExpense'] == true) {
                  String key = map['category'] ?? 'other';
                  String displayKey = AppStrings.data['vi']!.containsValue(key) ? key : AppStrings.get(key);
                  double amount = (map['amount'] as num).toDouble();
                  categoryTotals[displayKey] = (categoryTotals[displayKey] ?? 0) + amount;
                  totalExpense += amount;
                }
              }

              if (totalExpense == 0) return Center(child: Text(AppStrings.get('no_data')));

              List<PieChartSectionData> sections = categoryTotals.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final val = entry.value;
                final percent = (val.value / totalExpense) * 100;
                return PieChartSectionData(
                  color: Colors.primaries[index % Colors.primaries.length],
                  value: val.value,
                  title: '${percent.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList();

              return Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(height: 250, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40))),
                  const SizedBox(height: 20),
                  Text(AppStrings.get('chart_detail'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: categoryTotals.length,
                      itemBuilder: (ctx, i) {
                        String key = categoryTotals.keys.elementAt(i);
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.primaries[i % Colors.primaries.length], radius: 10),
                          title: Text(key),
                          trailing: Text('${categoryTotals[key]!.toStringAsFixed(0)} đ'),
                        );
                      },
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }
}