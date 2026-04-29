import 'package:flutter/material.dart';

/// أيقونة الأفاتار مع مؤشر الاتصال
class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final bool isOnline;
  final bool showOnlineDot;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 42,
    this.isOnline = false,
    this.showOnlineDot = true,
  });

  static const List<Color> _colors = [
    Color(0xFF2F81F7),
    Color(0xFF3FB950),
    Color(0xFFF78166),
    Color(0xFFD2A8FF),
    Color(0xFFFFA657),
    Color(0xFF79C0FF),
  ];

  Color get _bgColor => _colors[name.codeUnitAt(0) % _colors.length];
  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // الدائرة
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _bgColor,
                  _bgColor.withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _bgColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // نقطة الاتصال
          if (showOnlineDot && isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: const Color(0xFF3FB950),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3FB950).withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
