import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

// إنشاء كائن Shorebird للتعامل مع التحديثات
final _shorebirdCodePush = ShorebirdCodePush();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isChecking = false;

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // 1. التحقق من دعم التحديثات الهوائية في هذه النسخة
      final isUpdaterAvailable = _shorebirdCodePush.isUpdaterSupported();
      
      if (!isUpdaterAvailable) {
        _showSnackBar('التحديثات الهوائية غير مدعومة في هذه النسخة (Debug mode)');
        return;
      }

      // 2. التحقق من وجود تحديث جديد متاح للتحميل
      final isUpdateAvailable = await _shorebirdCodePush.isNewPatchAvailableForDownload();

      if (isUpdateAvailable) {
        _showSnackBar('جاري تحميل تحديث جديد...');
        
        // 3. تحميل التحديث
        await _shorebirdCodePush.downloadUpdateIfAvailable();
        
        _showDialog('اكتمل التحميل', 'تم تحميل التحديث بنجاح. يرجى إغلاق التطبيق وفتحه مرة أخرى لتطبيق التغييرات.');
      } else {
        _showSnackBar('تطبيقك محدث لآخر نسخة.');
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء التحقق من التحديثات');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Arial'))),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(content, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'الله أكبر',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            _isChecking 
              ? const CircularProgressIndicator() 
              : ElevatedButton.icon(
                  onPressed: _checkForUpdates,
                  icon: const Icon(Icons.update),
                  label: const Text('التحقق من وجود تحديث'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}