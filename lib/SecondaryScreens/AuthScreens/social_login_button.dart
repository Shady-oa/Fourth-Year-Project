import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';

// ─── Social Login Button ───────────────────────────────────────────────────────
/// A bordered, full-width button used for Google and Facebook sign-in.
/// Displays an [assetImage] on the left and a [label] beside it.
/// All tap handling is delegated to [onTap].
class SocialLoginButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;
  final double imageWidth;
  final double imageHeight;
  final Widget imageSpacer;

  const SocialLoginButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.onTap,
    this.imageWidth = 32,
    this.imageHeight = 32,
    this.imageSpacer = sizedBoxWidthSmall,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: radiusMedium,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage(assetPath),
              width: imageWidth,
              height: imageHeight,
            ),
            imageSpacer,
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
