import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import '../settings_service.dart';
import '../notification_service.dart'; // Import NotificationService

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  
  // Controller cho giao dịch
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Controller cho thông báo
  final TextEditingController _notiContentController = TextEditingController();
  TimeOfDay? _selectedTime;

  String _selectedCategory = 'food';
  bool _isExpense = true;
  final List<String> _categoryKeys = ['food', 'shopping', 'transport', 'rent', 'salary', 'bonus', 'other'];

  bool isSameDate(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  // --- 1. HỘP THOẠI TẠO THÔNG BÁO (NÚT TRÊN GÓC PHẢI) ---
  void _showNotificationDialog() {
    _notiContentController.clear();
    _selectedTime = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Tạo nhắc nhở ${DateFormat('dd/MM').format(_selectedDay!)}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _notiContentController,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung nhắc nhở',
                    hintText: 'VD: Đi siêu thị, Trả nợ...',
                    prefixIcon: Icon(Icons.notifications_active),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _selectedTime == null 
                    ? 'Chọn giờ nhắc' 
                    : 'Giờ nhắc: ${_selectedTime!.format(context)}'
                  ),
                  trailing: const Icon(Icons.access_time, color: Colors.blue),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        _selectedTime = picked;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text(AppStrings.get('cancel'))
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_notiContentController.text.isNotEmpty && _selectedTime != null) {
                    // Tạo thời gian hẹn: Ngày đang chọn + Giờ đã chọn
                    DateTime scheduledDate = DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );

                    // Nếu thời gian đã qua, cộng thêm một chút để đảm bảo không lỗi logic (hoặc giữ nguyên để nó hiện ngay)
                    if (scheduledDate.isBefore(DateTime.now())) {
                       scheduledDate = DateTime.now().add(const Duration(seconds: 5));
                    }

                    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

                    await NotificationService.scheduleNotification(
                      id: notificationId,
                      title: 'Lịch nhắc nhở',
                      body: _notiContentController.text,
                      scheduledDate: scheduledDate,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã đặt lịch nhắc nhở!')),
                      );
                    }
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập nội dung và chọn giờ!')),
                      );
                  }
                },
                child: const Text('Đặt lịch'),
              )
            ],
          );
        }
      )
    );
  }

  // --- 2. HỘP THOẠI THÊM GIAO DỊCH (NÚT DẤU +) ---
  // (Đã xóa phần thông báo ở đây để code gọn hơn)
  void _showAddDialog() {
    _amountController.clear(); 
    _noteController.clear();
    _selectedCategory = 'food'; 

    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: Text('${AppStrings.get('add_transaction')} ${DateFormat('dd/MM').format(_selectedDay!)}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _amountController, 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(labelText: AppStrings.get('amount'))
            ),
            const SizedBox(height: 10),
            Row(children: [
              Text("${AppStrings.get('category')}: "),
              Switch(
                value: _isExpense, 
                activeColor: Colors.red, 
                inactiveThumbColor: Colors.green, 
                onChanged: (v) { 
                  setState(() => _isExpense = v); 
                  Navigator.pop(context); 
                  _showAddDialog(); 
                }
              ),
              Text(_isExpense ? AppStrings.get('expense') : AppStrings.get('income')),
            ]),
            DropdownButtonFormField<String>(
              value: _selectedCategory, 
              items: _categoryKeys.map((k) => DropdownMenuItem(value: k, child: Text(AppStrings.get(k)))).toList(), 
              onChanged: (v) => _selectedCategory = v!, 
              decoration: InputDecoration(labelText: AppStrings.get('category'))
            ),
            TextField(
              controller: _noteController, 
              decoration: InputDecoration(labelText: AppStrings.get('note'))
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get('cancel'))),
          ElevatedButton(
            onPressed: () {
              if(_amountController.text.isNotEmpty) {
                _firestoreService.addTransaction(
                  double.tryParse(_amountController.text) ?? 0, 
                  _selectedCategory, 
                  _noteController.text, 
                  _isExpense, 
                  customDate: _selectedDay
                );
                Navigator.pop(context);
              }
            }, 
            child: Text(AppStrings.get('save'))
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentLanguage, 
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('calendar_title')),
            // --- NÚT THÔNG BÁO Ở GÓC PHẢI ---
            actions: [
              IconButton(
                icon: const Icon(Icons.add_alert, color: Colors.blue),
                tooltip: 'Thêm nhắc nhở',
                onPressed: _showNotificationDialog,
              ),
              const SizedBox(width: 10),
            ],
          ),
          
          // --- NÚT DẤU + (CHỈ ĐỂ THÊM GIAO DỊCH) ---
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddDialog, 
            backgroundColor: Colors.blue, 
            child: const Icon(Icons.add, color: Colors.white)
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getTransactionsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text(AppStrings.get('no_data')));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final docs = snapshot.data!.docs;
              final selectedTrans = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return isSameDate((data['timestamp'] as Timestamp).toDate(), _selectedDay!);
              }).toList();
              
              return Column(children: [
                TableCalendar(
                  locale: currentLanguage.value, 
                  firstDay: DateTime.utc(2020,1,1), 
                  lastDay: DateTime.utc(2030,12,31), 
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDate(_selectedDay!, day),
                  onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
                  eventLoader: (day) => docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return isSameDate((data['timestamp'] as Timestamp).toDate(), day);
                  }).toList(),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: selectedTrans.isEmpty 
                  ? Center(child: Text("${AppStrings.get('no_trans_date')} ${DateFormat('dd/MM').format(_selectedDay!)}"))
                  : ListView.builder(
                      itemCount: selectedTrans.length, 
                      itemBuilder: (ctx, i) {
                        final data = selectedTrans[i].data() as Map<String, dynamic>;
                        String key = data['category'] ?? 'other';
                        String display = AppStrings.data['vi']!.containsValue(key) ? key : AppStrings.get(key);
                        
                        return ListTile(
                          leading: Icon(
                            data['isExpense'] ? Icons.remove_circle : Icons.add_circle, 
                            color: data['isExpense'] ? Colors.red : Colors.green
                          ),
                          title: Text(display, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['note']??''),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(data['amount'])}', 
                              style: TextStyle(color: data['isExpense'] ? Colors.red : Colors.green)
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.grey), 
                              onPressed: () => _firestoreService.deleteTransaction(selectedTrans[i].id)
                            )
                          ]),
                        );
                      }
                    )
                )
              ]);
            },
          ),
        );
      }
    );
  }
}