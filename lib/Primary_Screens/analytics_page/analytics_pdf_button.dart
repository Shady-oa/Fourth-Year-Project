import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

class AnalyticsPdfButton extends StatelessWidget {
  final bool isGeneratingPDF;
  final VoidCallback onPressed;

  const AnalyticsPdfButton({
    super.key,
    required this.isGeneratingPDF,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isGeneratingPDF ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        icon: isGeneratingPDF
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.share, size: 22),
        label: Text(
          isGeneratingPDF ? 'Generating Analytics PDF…' : 'Share Analytics PDF',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
