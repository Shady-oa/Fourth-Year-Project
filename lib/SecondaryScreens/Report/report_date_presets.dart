import 'package:final_project/Constants/colors.dart';
import 'package:final_project/SecondaryScreens/Report/date_preset.dart';
import 'package:flutter/material.dart';


// ─── Date Presets Row ─────────────────────────────────────────────────────────
class ReportDatePresets extends StatelessWidget {
  final DatePreset selectedPreset;
  final ValueChanged<DatePreset> onPresetChanged;

  const ReportDatePresets({
    super.key,
    required this.selectedPreset,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DatePreset.values.map((preset) {
          final isSelected = selectedPreset == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onPresetChanged(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  preset.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
