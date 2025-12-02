import 'package:flutter/material.dart';


const double spacerTiny = 4.0;
const double spacerSmall = 8.0;
const double spacerMedium = 16.0;
const double spacerLarge = 24.0;
const double spacerXLarge = 32.0;

const EdgeInsets paddingAllTiny = EdgeInsets.all(spacerTiny);
const EdgeInsets paddingAllSmall = EdgeInsets.all(spacerSmall);
const EdgeInsets paddingAllMedium = EdgeInsets.all(spacerMedium);
const EdgeInsets paddingAllLarge = EdgeInsets.all(spacerLarge);

//- - - - - - - - - - - - - - - - - - - - BORDER RADIUS - - - - - - - - - - - - - - - - - - - -

const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8.0));
const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12.0));
const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(24.0));
const BorderRadius topOnly = BorderRadius.only(
  topLeft: Radius.circular(40.0),
  topRight: Radius.circular(40.0),
  bottomLeft: Radius.circular(0.0),
  bottomRight: Radius.circular(0.0),
);

// - - -  - - - - - -   SIZEBOXES  - - - - - - - - - - - - - - - - - - - - - - -  - - - - - -  - -

const SizedBox sizedBoxHeightTiny = SizedBox(height: spacerTiny);
const SizedBox sizedBoxHeightSmall = SizedBox(height: spacerSmall);
const SizedBox sizedBoxHeightMedium = SizedBox(height: spacerMedium);
const SizedBox sizedBoxHeightLarge = SizedBox(height: spacerLarge);
const SizedBox sizedBoxHeightXLarge = SizedBox(height: spacerXLarge);
const SizedBox sizedBoxWidthTiny = SizedBox(width: spacerTiny);
const SizedBox sizedBoxWidthSmall = SizedBox(width: spacerSmall);
const SizedBox sizedBoxWidthMedium = SizedBox(width: spacerMedium);
const SizedBox sizedBoxWidthLarge = SizedBox(width: spacerLarge);
const SizedBox sizedBoxWidthXLarge = SizedBox(width: spacerXLarge);
