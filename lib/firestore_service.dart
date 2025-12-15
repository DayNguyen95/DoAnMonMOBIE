import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Đổi tên collection từ 'notes' sang 'transactions' (giao dịch)
  final CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');
  final CollectionReference settings = FirebaseFirestore.instance.collection('settings');
  // 1. Thêm giao dịch (CREATE)
  Future<void> addTransaction(double amount, String category, String note, bool isExpense, {DateTime? customDate}) {
    return transactions.add({
      'amount': amount,
      'category': category,
      'note': note,
      'isExpense': isExpense,
      // SỬA: Nếu có customDate thì dùng, không thì lấy giờ hiện tại
      'timestamp': Timestamp.fromDate(customDate ?? DateTime.now()), 
    });
  }

  // 2. Đọc dữ liệu (READ)
  Stream<QuerySnapshot> getTransactionsStream() {
    // Sắp xếp cái mới nhất lên đầu
    return transactions.orderBy('timestamp', descending: true).snapshots();
  }

  // 3. Xóa giao dịch (DELETE)
  Future<void> deleteTransaction(String docId) {
    return transactions.doc(docId).delete();
  }

   // --- 4. Cập nhật thông tin Profile (ĐÃ SỬA) ---
  // Thay đổi: tham số thứ 2 là (int avatarIndex) thay vì (String avatarUrl)
  Future<void> updateUserProfile(String name, int avatarIndex, String language) {
    return settings.doc('profile').set({
      'name': name,
      'avatarIndex': avatarIndex, // Lưu số thứ tự của Icon
      'language': language,
    });
  }

  // --- 5. Lấy thông tin Profile ---
  Stream<DocumentSnapshot> getUserProfileStream() {
    return settings.doc('profile').snapshots();
  }
}