import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

// --- SingleSaving Class (Original) ---
class SingleSaving extends StatefulWidget {
  const SingleSaving({super.key});

  @override
  State<SingleSaving> createState() => _SingleSavingState();

  // Changed the return type from Widget to static Widget to make it clear,
  // and kept the implementation as is, ensuring it uses the context correctly.
  static Widget depositList() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      // The Builder is necessary here because this is a static method
      // that needs a context to access the Theme.
      child: Builder(
        builder: (context) {
          // Determine the color for the text/icon on the surface (background)
          final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
          // Determine the main background color
          final surfaceColor = Theme.of(context).colorScheme.surface;

          return Row(
            children: [
              Container(
                height: 53,
                width: 57,
                decoration: const BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                // Icon color should be visible on brandGreen
                child: Icon(Icons.flight, size: 15, color: onSurfaceColor),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Travel Deposit",
                    // Text color should be onSurface, not surface, as the main background is onSurface (in the main content)
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: onSurfaceColor),
                  ),
                  Row(
                    children: [
                      Text(
                        "19:00",
                        // Using brandGreen for consistency with your primary color
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: brandGreen),
                      ),
                      Text(
                        " - ",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: brandGreen),
                      ),
                      Text(
                        "April 12",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: brandGreen),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                "\$217.00",
                // Text color should be onSurface
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: onSurfaceColor),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- _SingleSavingState Class (Fixed) ---
class _SingleSavingState extends State<SingleSaving> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                bottom: 50,
                right: 20,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Travel",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: Icon(
                      Icons.notifications_none_outlined,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  // This is the background of your main content area
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 45,
                    left: 50,
                    right: 50,
                    bottom: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Section
                      SizedBox(
                        height: 160,
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Goal",
                                  // Text color should be surface (the background color of the scaffold)
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "\$1,900.00",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Amount Saved",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                                Text(
                                  "\$654.00",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: brandGreen,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.flight,
                                      // Icon color should be onSurface for high contrast on brandGreen
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      size: 80,
                                    ),
                                    Text(
                                      "Travel",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Progress Bar Section
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.2),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: brandGreen,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "\$1,900.00",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          "30% Of The Goal Saved",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                              ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Transactions",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      // Scrollable List of Deposits
                      Expanded(
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return SingleSaving.depositList();
                          },
                        ),
                      ),

                      // Fixed Add More Button
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: GestureDetector(
                            onTap: () {
                              // Call the fixd addDialog method
                              addDialog(context);
                            },
                            child: Container(
                              height: 36,
                              width: 169,
                              decoration: const BoxDecoration(
                                color: brandGreen,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Add Savings",
                                  // Text color should be onSurface for contrast on brandGreen
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: The context used for Theme.of() inside the dialog's builder
  // must be the context provided by the builder itself.
  void addDialog(BuildContext screenContext) {
    showDialog(
      context:
          screenContext, // Use the main screen context to position the dialog
      builder: (BuildContext dialogContext) {
        // Use the dialogContext for theme/widget access inside the dialog
        return Dialog(
          // Use the dialogContext to access the Theme
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "New Category",
                  style: Theme.of(dialogContext).textTheme.headlineSmall
                      ?.copyWith(
                        color: Theme.of(dialogContext).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Write...",
                    filled: true,
                    // Use dialogContext for theme access
                    fillColor: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: Theme.of(
                            dialogContext,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    // Save action
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Save",
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: Theme.of(dialogContext).colorScheme.onSurface,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: Theme.of(dialogContext).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
