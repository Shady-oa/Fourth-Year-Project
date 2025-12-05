import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';



final formLogo = Builder(
  builder: (context) {
    return Column(
      children: [
        sizedBoxHeightMedium,
        Center(
          child: SvgPicture.asset(
            'assets/svg/penny.svg',
            height: 100,
            width: 100,
            colorFilter: const ColorFilter.mode(brandGreen, BlendMode.srcIn),
          ),
        ),
    
        Text('Penny Wise', style: Theme.of(context).textTheme.displayMedium),
        sizedBoxHeightTiny,
        Text("Wise Choices For Financial Freedom", style: Theme.of(context).textTheme.titleMedium),
        sizedBoxHeightLarge,
      ],
    );
  }
);
