import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<String> currentLanguage = ValueNotifier('vi');

class SettingsService {
  static const String keyLanguage = 'language';
  static const String keyAvatarIndex = 'avatar_index';
  static const String keyName = 'user_name';
  // MỚI: Key lưu hạn mức chi tiêu
  static const String keyBudget = 'monthly_budget'; 
  // MỚI: Key lưu giờ thông báo (lưu dạng chuỗi "HH:mm")
  static const String keyNotiTime = 'notification_time';

  static final List<IconData> avatarIcons = [
    Icons.person, Icons.face, Icons.face_3, Icons.face_6, Icons.pets,
    Icons.emoji_emotions, Icons.account_circle, Icons.admin_panel_settings,
    Icons.accessibility_new, Icons.child_care, Icons.elderly, Icons.engineering,
  ];

  // SỬA: Thêm budget và notiTime vào hàm save
  static Future<void> saveSettings(String language, int avatarIndex, String name, double budget, String notiTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLanguage, language);
    await prefs.setInt(keyAvatarIndex, avatarIndex);
    await prefs.setString(keyName, name);
    await prefs.setDouble(keyBudget, budget);
    await prefs.setString(keyNotiTime, notiTime);
    currentLanguage.value = language;
  }

  // SỬA: Thêm budget và notiTime vào hàm load
  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'language': prefs.getString(keyLanguage) ?? 'vi',
      'avatarIndex': prefs.getInt(keyAvatarIndex) ?? 0,
      'name': prefs.getString(keyName) ?? '',
      'budget': prefs.getDouble(keyBudget) ?? 0.0, // Mặc định 0
      'notiTime': prefs.getString(keyNotiTime) ?? '',
    };
  }
}

class AppStrings {
  static Map<String, Map<String, String>> data = {
    'vi': {
      'app_title': 'Quản lý Chi tiêu',
      'chart_title': 'Thống kê Chi tiêu',
      'calendar_title': 'Lịch',
      'profile_title': 'Tài khoản',
      'pick_icon': 'Chạm để thay đổi biểu tượng',
      'chart_detail': 'Chi tiết theo danh mục',
      'no_data': 'Chưa có dữ liệu',
      'no_trans_date': 'Không có giao dịch ngày',
      'save': 'Lưu',
      'settings_saved': 'Đã lưu cài đặt!',
      'name_hint': 'Nhập tên của bạn',
      'add_transaction': 'Thêm giao dịch',
      'amount': 'Số tiền',
      'category': 'Danh mục',
      'note': 'Ghi chú',
      'expense': 'Chi tiền',
      'income': 'Thu tiền',
      'cancel': 'Hủy',
      'food': 'Ăn uống', 'shopping': 'Mua sắm', 'transport': 'Di chuyển',
      'rent': 'Tiền nhà', 'salary': 'Lương', 'bonus': 'Thưởng', 'other': 'Khác',
      
      // --- TỪ KHÓA MỚI ---
      'budget_limit': 'Hạn mức chi tiêu tháng (VNĐ)',
      'daily_reminder': 'Nhắc nhở hàng ngày',
      'notification': 'Thông báo',
      'budget_status': 'Tình trạng chi tiêu',
      'spent': 'Đã chi',
      'remaining': 'Còn lại',
      'over_budget': 'BẠN ĐÃ CHI TIÊU QUÁ MỨC!',
      'safe_budget': 'Chi tiêu trong tầm kiểm soát.',
      'set_budget_hint': 'Vui lòng đặt hạn mức trong Tài khoản.',
      'pick_time': 'Chọn giờ',
    },
    'en': {
      'app_title': 'Expense Manager',
      'chart_title': 'Statistics',
      'calendar_title': 'Calendar',
      'profile_title': 'Profile',
      'pick_icon': 'Tap to change avatar',
      'chart_detail': 'Details by Category',
      'no_data': 'No data available',
      'no_trans_date': 'No transactions on',
      'save': 'Save',
      'settings_saved': 'Settings Saved!',
      'name_hint': 'Enter your name',
      'add_transaction': 'Add Transaction',
      'amount': 'Amount',
      'category': 'Category',
      'note': 'Note',
      'expense': 'Expense',
      'income': 'Income',
      'cancel': 'Cancel',
      'food': 'Food', 'shopping': 'Shopping', 'transport': 'Transport',
      'rent': 'Rent', 'salary': 'Salary', 'bonus': 'Bonus', 'other': 'Other',

      // --- NEW KEYS ---
      'budget_limit': 'Monthly Budget Limit',
      'daily_reminder': 'Daily Reminder',
      'notification': 'Notification',
      'budget_status': 'Spending Status',
      'spent': 'Spent',
      'remaining': 'Remaining',
      'over_budget': 'YOU ARE OVER BUDGET!',
      'safe_budget': 'Spending is under control.',
      'set_budget_hint': 'Please set a budget in Profile.',
      'pick_time': 'Pick Time',
    }
  };

  static String get(String key) {
    return data[currentLanguage.value]?[key] ?? key;
  }
}