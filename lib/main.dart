import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'firebase_options.dart';
import 'note_list_page.dart';
import 'settings_service.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dòng này sửa lỗi màn hình đỏ (Nhớ Restart app)
  await initializeDateFormatting(); 
  
 

  final settings = await SettingsService.loadSettings();
  currentLanguage.value = settings['language']!;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return MaterialApp(
          title: 'Quản lý Chi tiêu',
          debugShowCheckedModeBanner: false, 
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const NoteListPage(), 
        );
      },
    );
  }
}