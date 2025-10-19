import 'package:flutter/material.dart';

/// Widgets com tema militar consistente para o jogo
class MilitaryThemeWidgets {
  // Cores do tema militar
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);

  /// Container com background militar texturizado
  static Widget militaryBackground({
    required Widget child,
    double opacity = 0.3,
  }) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: opacity),
        ),
        child: child,
      ),
    );
  }

  /// Card militar com bordas e sombras estilizadas
  static Widget militaryCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double elevation = 8,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor ?? Colors.white,
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: padding ?? const EdgeInsets.all(24),
        child: child,
      ),
    );
  }

  /// Botão militar estilizado
  static Widget militaryButton({
    required String text,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    IconData? icon,
    bool isLoading = false,
    double? width,
    double height = 48,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? primaryGreen,
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: primaryGreen.withValues(alpha: 0.5),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Header militar com logo
  static Widget militaryHeader({
    String? title,
    String? subtitle,
    bool showLogo = true,
    bool showTextLogo = true,
  }) {
    return Column(
      children: [
        if (showLogo) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (showTextLogo) ...[
          Image.asset(
            'assets/images/combatentes.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
        ],

        if (title != null) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (subtitle != null) ...[
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Dialog militar estilizado
  static Future<T?> showMilitaryDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? titleIcon,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            if (titleIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(titleIcon, color: primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: content,
        actions: actions,
        backgroundColor: Colors.white,
      ),
    );
  }

  /// TextField militar estilizado
  static Widget militaryTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        labelStyle: const TextStyle(color: primaryGreen),
        focusColor: primaryGreen,
      ),
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  /// Status indicator militar
  static Widget militaryStatusIndicator({
    required String status,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? primaryGreen).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? primaryGreen).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? primaryGreen),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color ?? primaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Loading indicator militar
  static Widget militaryLoadingIndicator({String? message, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
