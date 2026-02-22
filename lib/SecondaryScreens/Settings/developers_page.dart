import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DevelopersPage extends StatelessWidget {
  const DevelopersPage({super.key});

  Future<void> _launchYoutube() async {
    final Uri url = Uri.parse('https://www.youtube.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const CustomHeader(headerName: 'Developers'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: paddingAllMedium,
        child: Column(
          children: [
            const SizedBox(height: 20),
            _DeveloperProfileCard(
              name: 'Shadrack',
              role: 'Software Engineering Student',
              university: 'Kisii University',
              imageUrl: 'https://i.pravatar.cc/150?u=shadrack',
              onYoutubeTap: _launchYoutube,
            ),
            const SizedBox(height: 16),
            _DeveloperProfileCard(
              name: 'Alex',
              role: 'Software Engineering Student',
              university: 'Kisii University',
              imageUrl: 'https://i.pravatar.cc/150?u=alex',
              onYoutubeTap: _launchYoutube,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperProfileCard extends StatelessWidget {
  const _DeveloperProfileCard({
    required this.name,
    required this.role,
    required this.university,
    required this.imageUrl,
    required this.onYoutubeTap,
  });

  final String name;
  final String role;
  final String university;
  final String imageUrl;
  final VoidCallback onYoutubeTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: paddingAllMedium,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: radiusLarge,
        border: Border.all(color: brandGreen.withOpacity(isDark ? 0.3 : 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: brandGreen.withOpacity(0.1),
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  university,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onYoutubeTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          color: Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'YouTube',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
