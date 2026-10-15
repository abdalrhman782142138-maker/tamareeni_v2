import 'package:flutter/material.dart';

/// ألوان التطبيق: أسود ورمادي وأبيض مع لون تمييز أحمر.
class AppColors {
  AppColors._();

  static const Color accent = Color(0xFFE53935);

  static const Color darkBg = Color(0xFF0B0B0C);
  static const Color darkSurface = Color(0xFF171718);
  static const Color darkSurfaceHigh = Color(0xFF242426);
  static const Color darkBorder = Color(0xFF2E2E31);

  static const Color lightBg = Color(0xFFF2F2F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFE6E6E8);
  static const Color lightBorder = Color(0xFFD9D9DC);

  static const Color success = Color(0xFF43A047);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color surfaceHigh(BuildContext context) {
    return isDark(context)
        ? AppColors.darkSurfaceHigh
        : AppColors.lightSurfaceHigh;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? AppColors.darkBorder : AppColors.lightBorder;
  }

  static ThemeData _build(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;

    final Color bg = dark ? AppColors.darkBg : AppColors.lightBg;
    final Color surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color onSurface = dark ? Colors.white : const Color(0xFF111111);
    final Color onSurfaceVariant =
        dark ? const Color(0xFFA0A0A6) : const Color(0xFF5C5C62);
    final Color borderColor =
        dark ? AppColors.darkBorder : AppColors.lightBorder;

    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    );

    final ColorScheme scheme = base.copyWith(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: borderColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: AppColors.accent.withOpacity(0.2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.darkSurfaceHigh : onSurface,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  /// شكل موحّد لحقول الإدخال (بدون الاعتماد على inputDecorationTheme
  /// لأن نوعه يختلف بين إصدارات Flutter).
  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    String? suffixText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      filled: true,
      fillColor: surfaceHigh(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }
}

// ============================================================
// عناصر واجهة مشتركة
// ============================================================

/// بطاقة بحواف دائرية وإطار خفيف، تقبل الضغط والضغط المطوّل.
class SoftCard extends StatelessWidget {
  const SoftCard({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bool dark = AppTheme.isDark(context);
    return Material(
      color: color ?? (dark ? AppColors.darkSurface : AppColors.lightSurface),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor ?? AppTheme.border(context)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// عنوان قسم مع زر اختياري على الطرف الآخر.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    Key? key,
    required this.title,
    this.action,
    this.onAction,
  }) : super(key: key);

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

/// مربع إحصائية صغير: قيمة كبيرة وتحتها وصف.
class StatTile extends StatelessWidget {
  const StatTile({
    Key? key,
    required this.value,
    required this.label,
    this.icon,
  }) : super(key: key);

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(height: 10),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// حالة فارغة: أيقونة وعنوان ووصف وزر اختياري.
class EmptyState extends StatelessWidget {
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
    this.buttonLabel,
    this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (buttonLabel != null && onPressed != null) ...<Widget>[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// نافذة تأكيد موحّدة. تُرجع true فقط إذا ضغط المستخدم زر التأكيد.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result == true;
}
