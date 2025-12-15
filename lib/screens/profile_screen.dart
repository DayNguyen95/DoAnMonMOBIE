import 'package:flutter/material.dart';
import '../settings_service.dart';
import '../firestore_service.dart';
// MỚI: Import intl để format số tiền
import 'package:intl/intl.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController(); // MỚI
  
  String _selectedLanguage = 'vi';
  int _selectedAvatarIndex = 0;
  bool _isSelectingAvatar = false;
  
  // MỚI: Biến lưu giờ thông báo
  TimeOfDay? _notificationTime; 

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  void _loadLocalSettings() async {
    final data = await SettingsService.loadSettings();
    setState(() {
      _selectedLanguage = data['language'];
      _selectedAvatarIndex = data['avatarIndex'];
      _nameController.text = data['name'];
      
      // Load hạn mức (nếu > 0 thì hiện, ko thì để trống)
      double budget = data['budget'];
      _budgetController.text = budget > 0 ? budget.toStringAsFixed(0) : '';

      // Load giờ thông báo
      String timeStr = data['notiTime'];
      if (timeStr.isNotEmpty) {
        final parts = timeStr.split(':');
        _notificationTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    });
  }

  // Hàm chọn giờ
  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  void _saveSettings() async {
    double budget = double.tryParse(_budgetController.text) ?? 0.0;
    String timeStr = _notificationTime != null ? '${_notificationTime!.hour}:${_notificationTime!.minute}' : '';

    await SettingsService.saveSettings(
      _selectedLanguage,
      _selectedAvatarIndex,
      _nameController.text,
      budget, // Lưu hạn mức
      timeStr, // Lưu giờ
    );
    
    // Lưu cơ bản lên Firebase (bạn có thể mở rộng lưu thêm budget lên Firebase nếu cần)
    await _firestoreService.updateUserProfile(
      _nameController.text,
      _selectedAvatarIndex,
      _selectedLanguage,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('settings_saved'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentLanguage,
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.get('profile_title'))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ... (Phần Avatar giữ nguyên như cũ) ...
                GestureDetector(
                  onTap: () => setState(() => _isSelectingAvatar = !_isSelectingAvatar),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        child: Icon(SettingsService.avatarIcons[_selectedAvatarIndex], size: 60, color: Colors.blue[800]),
                      ),
                      const SizedBox(height: 10),
                      Text(_isSelectingAvatar ? '▼' : AppStrings.get('pick_icon'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (_isSelectingAvatar)
                  Container(
                    height: 200, margin: const EdgeInsets.only(bottom: 20),
                    child: GridView.builder(
                      itemCount: SettingsService.avatarIcons.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => setState(() { _selectedAvatarIndex = index; _isSelectingAvatar = false; }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedAvatarIndex == index ? Colors.blueAccent : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Icon(SettingsService.avatarIcons[index], color: _selectedAvatarIndex == index ? Colors.white : Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: AppStrings.get('name_hint'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.edit)),
                ),
                
                // --- MỚI: NHẬP HẠN MỨC CHI TIÊU ---
                const SizedBox(height: 15),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('budget_limit'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                ),

                // --- MỚI: CHỌN GIỜ THÔNG BÁO ---
                const SizedBox(height: 15),
                ListTile(
                  title: Text(AppStrings.get('daily_reminder')),
                  subtitle: Text(_notificationTime != null 
                    ? _notificationTime!.format(context) 
                    : AppStrings.get('pick_time')),
                  trailing: const Icon(Icons.alarm),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: const BorderSide(color: Colors.grey)),
                  onTap: _pickTime,
                ),

                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(labelText: 'Language / Ngôn ngữ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.language)),
                  items: const [DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')), DropdownMenuItem(value: 'en', child: Text('English'))],
                  onChanged: (val) => setState(() => _selectedLanguage = val!),
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text(AppStrings.get('save'), style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}