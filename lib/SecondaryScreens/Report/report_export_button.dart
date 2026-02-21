import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

// ─── Export Button ────────────────────────────────────────────────────────────
class ReportExportButton extends StatelessWidget {
  final bool isGeneratingPDF;
  final VoidCallback onPressed;

  const ReportExportButton({
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
            borderRadius: BorderRadius.circular(12),
          ),
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
            : const Icon(Icons.share, size: 20),
        label: Text(
          isGeneratingPDF ? 'Generating…' : 'Share PDF Report',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
