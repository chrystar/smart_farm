import 'package:flutter/material.dart';

Widget authButton({
  String text = "Continue",
  VoidCallback? onPressed,
  Color color = Colors.green,
  Color textColor = Colors.white,
  double borderRadius = 8.0,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
  bool isLoading = false,
  Widget? icon, // Optional icon parameter
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              // You can adjust the disabled color if needed
              return color.withOpacity(0.5);
            }
            return color;
          },
        ),
        foregroundColor: MaterialStateProperty.all<Color>(textColor),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(padding),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        textStyle: MaterialStateProperty.all<TextStyle>(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    ),
  );
}
