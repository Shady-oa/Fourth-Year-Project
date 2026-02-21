import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:flutter/material.dart';

class SavingOptionsSheet extends StatelessWidget {
  final Saving saving;
  final VoidCallback onRemoveFunds;
  final VoidCallback onEditGoal;
  final VoidCallback onDeleteGoal;

  const SavingOptionsSheet({
    super.key,
    required this.saving,
    required this.onRemoveFunds,
    required this.onEditGoal,
    required this.onDeleteGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.savings, color: brandGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    saving.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          _bsTile(
            context,
            Icons.remove_circle_outline,
            Colors.orange,
            'Remove Fund',
            'Withdraw money from this goal',
            onRemoveFunds,
          ),
          _bsTile(
            context,
            Icons.edit_outlined,
            Colors.blue,
            'Edit Goal',
            'Modify name, target or deadline',
            onEditGoal,
          ),
          _bsTile(
            context,
            Icons.delete_outline,
            errorColor,
            'Delete Goal',
            'Permanently remove this goal',
            onDeleteGoal,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _bsTile(
    BuildContext ctx,
    IconData icon,
    Color color,
    String label,
    String sub,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        sub,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }
}
