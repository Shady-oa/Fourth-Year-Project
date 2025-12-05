import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/back_button.dart';
import 'package:flutter/material.dart';

class Income extends StatefulWidget {
  const Income({super.key});

  @override
  State<Income> createState() => _IncomeState();
}

class _IncomeState extends State<Income> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: CustomBackButton(),
        title: CustomHeader(headerName: "Income"),
      ),
      body: SafeArea(
        child: Column(children: [Row(children: [
                
              ],
            )]),
      ),
    );
  }
}
