import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // نحتاجها للتحقق من المنصة
import 'package:shorebird_code_push/shorebird_code_push.dart';

// ننشئ الكائن فقط إذا كان النظام أندرويد أو iOS وليس ويب
final _shorebirdCodePush = kIsWeb ? null : ShorebirdCodePush();

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
    // إذا كان ويب، نخرج فوراً لأن Shorebird لا تدعم الويب
    if (kIsWeb || _shorebirdCodePush == null) {
      _showSnackBar('التحديثات الهوائية غير مدعومة على نسخة الويب');
      return;
    }

    setState(() => _isChecking = true);

    try {
      final isUpdaterAvailable = _shorebirdCodePush!.isUpdaterSupported();
      
      if (!isUpdaterAvailable) {
        _showSnackBar('التحديثات غير مدعومة في وضع التطوير (Debug)');
        return;
      }

      final isUpdateAvailable = await _shorebirdCodePush!.isNewPatchAvailableForDownload();

      if (isUpdateAvailable) {
        _showSnackBar('جاري تحميل تحديث جديد...');
        await _shorebirdCodePush!.downloadUpdateIfAvailable();
        _showDialog('اكتمل التحميل', 'يرجى إغلاق التطبيق وفتحه مرة أخرى.');
      } else {
        _showSnackBar('تطبيقك محدث لآخر نسخة.');
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء الفحص');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, textAlign: TextAlign.right)));
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(content, textAlign: TextAlign.right),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
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
            const Text('الله أكبر', style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            // الزر يظهر في كل المنصات ولكن وظيفته تختلف
            _isChecking 
              ? const CircularProgressIndicator() 
              : ElevatedButton.icon(
                  onPressed: _checkForUpdates,
                  icon: const Icon(Icons.update),
                  label: const Text('التحقق من وجود تحديث'),
                ),
          ],
        ),
      ),
    );
  }
}