import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: primaryText.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: kTextTheme.titleLarge,
                        ),
                        Text(
                          "John",
                          style: kTextTheme.bodyLarge
                              ?.copyWith(color: primaryText.withOpacity(0.7)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const ShapeDecoration(
                        color: primaryText,
                        shape: OvalBorder(),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          size: 22.0,
                          color: primaryBg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, color: primaryText),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: primaryText),
                    onPressed: () {},
                  ),
                  filled: true,
                  fillColor: primaryText.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                ),
                style: const TextStyle(color: primaryText),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 151,
                decoration: BoxDecoration(
                  color: primaryText.withOpacity(0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Ksh 32,423",
                      style: kTextTheme.displaySmall,
                    ),
                    Text(
                      "your balance",
                      style: kTextTheme.bodyLarge
                          ?.copyWith(color: primaryText.withOpacity(0.7)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
