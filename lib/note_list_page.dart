import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'firestore_service.dart';
import 'settings_service.dart';

import 'screens/chart_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart'; 
import 'notification_service.dart'; // Import NotificationService

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'food'; 
  bool _isExpense = true; 
  final List<String> _categoryKeys = ['food', 'shopping', 'transport', 'rent', 'salary', 'bonus', 'other'];

  // --- HÀM HIỂN THỊ THÔNG BÁO CHI TIÊU ---
  void _showNotificationDialog() async {
    final settings = await SettingsService.loadSettings();
    double budgetLimit = settings['budget'];
    String notificationTime = settings['notiTime'];

    if (budgetLimit <= 0) {
      if(!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppStrings.get('notification')),
          content: Text(AppStrings.get('set_budget_hint')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    double totalExpenseMonth = 0;
    DateTime now = DateTime.now();
    
    final snapshot = await _firestoreService.transactions.get();
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      bool isExp = data['isExpense'] ?? false;
      Timestamp ts = data['timestamp'];
      DateTime date = ts.toDate();

      if (isExp && date.month == now.month && date.year == now.year) {
        totalExpenseMonth += (data['amount'] as num).toDouble();
      }
    }

    bool isOverBudget = totalExpenseMonth > budgetLimit;
    double remaining = budgetLimit - totalExpenseMonth;

    if(!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(isOverBudget ? Icons.warning : Icons.check_circle, color: isOverBudget ? Colors.red : Colors.green),
            const SizedBox(width: 10),
            Text(AppStrings.get('budget_status')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${AppStrings.get('budget_limit')}: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(budgetLimit)}"),
            const SizedBox(height: 8),
            Text("${AppStrings.get('spent')}: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalExpenseMonth)}",
              style: TextStyle(color: isOverBudget ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
            const Divider(),
            if (isOverBudget)
              Text(AppStrings.get('over_budget'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))
            else
              Text("${AppStrings.get('remaining')}: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(remaining)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 15),
            if (notificationTime.isNotEmpty)
              Text("${AppStrings.get('daily_reminder')}: $notificationTime", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _showForm() {
     _amountController.clear();
    _noteController.clear();
    _selectedCategory = 'food';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.get('add_transaction')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppStrings.get('amount')),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text("${AppStrings.get('category')}: "),
                  Switch(
                    value: _isExpense,
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green,
                    onChanged: (val) {
                      setState(() => _isExpense = val);
                      Navigator.of(context).pop(); _showForm(); 
                    },
                  ),
                  Text(_isExpense ? AppStrings.get('expense') : AppStrings.get('income')),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categoryKeys.map((k) => DropdownMenuItem(value: k, child: Text(AppStrings.get(k)))).toList(),
                onChanged: (val) => _selectedCategory = val!,
                decoration: InputDecoration(labelText: AppStrings.get('category')),
              ),
              TextField(controller: _noteController, decoration: InputDecoration(labelText: AppStrings.get('note'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppStrings.get('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (_amountController.text.isNotEmpty) {
                _firestoreService.addTransaction(double.tryParse(_amountController.text)??0, _selectedCategory, _noteController.text, _isExpense);
                Navigator.of(context).pop();
              }
            },
            child: Text(AppStrings.get('save')),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('app_title')), 
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active, color: Colors.orange),
                onPressed: _showNotificationDialog,
              ),
              const SizedBox(width: 10),
            ],
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getTransactionsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final transactions = snapshot.data!.docs;
              if (transactions.isEmpty) return Center(child: Text(AppStrings.get('no_data')));

              return ListView.builder(
                itemCount: transactions.length,
                padding: const EdgeInsets.only(bottom: 80),
                itemBuilder: (context, index) {
                  final data = transactions[index].data() as Map<String, dynamic>;
                  final bool isExpense = data['isExpense'] ?? true;
                  final double amount = (data['amount'] as num).toDouble();
                  String categoryKey = data['category'] ?? 'other';
                  String displayCategory = AppStrings.data['vi']!.containsValue(categoryKey) ? categoryKey : AppStrings.get(categoryKey);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpense ? Colors.red[100] : Colors.green[100],
                        child: Icon(isExpense ? Icons.remove : Icons.add, color: isExpense ? Colors.red : Colors.green),
                      ),
                      title: Text(displayCategory, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['note'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount)}',
                            style: TextStyle(color: isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                            onPressed: () => _firestoreService.deleteTransaction(transactions[index].id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: _showForm,
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),

          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // --- NÚT TRANG CHỦ (MỚI THÊM) ---
                IconButton(
                  icon: const Icon(Icons.home, size: 30, color: Colors.blue),
                  tooltip: AppStrings.get('app_title'), // Dùng tên app làm tooltip
                  onPressed: () {
                    // Đang ở trang chủ nên không cần chuyển hướng
                  },
                ),

                // Nút Biểu đồ
                IconButton(
                  icon: const Icon(Icons.pie_chart, size: 30, color: Colors.blue),
                  tooltip: AppStrings.get('chart_title'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChartScreen())),
                ),
                
                const SizedBox(width: 40), // Khoảng trống cho nút Add

                // Nút Lịch
                IconButton(
                  icon: const Icon(Icons.calendar_month, size: 30, color: Colors.blue),
                  tooltip: AppStrings.get('calendar_title'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen())),
                ),

                // Nút Tài khoản
                IconButton(
                  icon: const Icon(Icons.person, size: 30, color: Colors.blue),
                  tooltip: AppStrings.get('profile_title'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}