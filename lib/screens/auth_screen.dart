import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureRegPassword = true;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> _savedEmails = [];

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
    _loadSavedEmails();
  }

  Future<void> _loadSavedEmails() async {
    final emails = await AuthService().getSavedEmails();
    if (mounted) {
      setState(() => _savedEmails = emails);
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await authProvider.login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
    } else {
      success = await authProvider.register(
        name: _regNameController.text.trim(),
        email: _regEmailController.text.trim(),
        password: _regPasswordController.text,
      );
      if (success && mounted) {
        setState(() => _isLogin = true);
        _loginEmailController.text = _regEmailController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التسجيل بنجاح! سجّل دخولك الآن'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFe8eeff), Color(0xFFf0f4ff)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1a56db).withOpacity(0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFe2e8f8)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 44),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الشعار
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1a56db), Color(0xFF1e429f)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1a56db).withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('💬', style: TextStyle(fontSize: 32)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // العنوان
                        Text(
                          'الرفيق',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: const Color(0xFF1e429f),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin ? 'سجّل دخولك للمتابعة' : 'أنشئ حسابك الجديد',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF64748b),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // رسالة خطأ
                        if (authProvider.error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfef2f2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFfecaca)),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.error!,
                                    style: const TextStyle(
                                      color: Color(0xFFef4444),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  color: const Color(0xFFef4444),
                                  onPressed: () => authProvider.clearError(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        if (authProvider.error != null) const SizedBox(height: 12),

                        // حقول الإدخال
                        if (_isLogin) ...[
                          _buildEmailField(
                            controller: _loginEmailController,
                            savedEmails: _savedEmails,
                            onEmailSelected: (email) {
                              _loginEmailController.text = email;
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildPasswordField(
                            controller: _loginPasswordController,
                            obscure: _obscurePassword,
                            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            label: 'كلمة المرور',
                          ),
                        ] else ...[
                          _buildTextField(
                            controller: _regNameController,
                            label: 'الاسم الكامل',
                            icon: Icons.person_outline,
                            prefix: '👤',
                            validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال الاسم' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _regEmailController,
                            label: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            prefix: '✉️',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'يرجى إدخال البريد';
                              if (!v.contains('@')) return 'بريد غير صالح';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildPasswordField(
                            controller: _regPasswordController,
                            obscure: _obscureRegPassword,
                            onToggle: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                            label: 'كلمة المرور',
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                              if (v.length < 6) return '6 أحرف على الأقل';
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // زر الإرسال
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: const Color(0xFF1a56db),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              disabledBackgroundColor: const Color(0xFF1a56db).withOpacity(0.7),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // رابط التبديل
                        TextButton(
                          onPressed: _switchMode,
                          child: Text.rich(
                            TextSpan(
                              text: _isLogin
                                  ? 'ليس لديك حساب؟ '
                                  : 'لديك حساب؟ ',
                              style: const TextStyle(
                                color: Color(0xFF64748b),
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin ? 'سجّل الآن' : 'سجّل الدخول',
                                  style: const TextStyle(
                                    color: Color(0xFF1a56db),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String prefix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748b))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Align(
              alignment: Alignment.centerRight,
              widthFactor: 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(prefix, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField({
    required TextEditingController controller,
    required List<String> savedEmails,
    required Function(String) onEmailSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('البريد الإلكتروني', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748b))),
        const SizedBox(height: 6),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return savedEmails;
            return savedEmails
                .where((e) => e.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: onEmailSelected,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            this._loginEmailController.text = controller.text;
            return TextFormField(
              controller: this._loginEmailController,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال البريد';
                if (!v.contains('@')) return 'بريد غير صالح';
                return null;
              },
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'example@mail.com',
                prefixIcon: const Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 0,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('✉️', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String label,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748b))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Align(
              alignment: Alignment.centerRight,
              widthFactor: 0,
              child: IconButton(
                icon: Text(obscure ? '👁️' : '👁️‍🗨️', style: const TextStyle(fontSize: 18)),
                onPressed: onToggle,
                padding: const EdgeInsets.only(left: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
