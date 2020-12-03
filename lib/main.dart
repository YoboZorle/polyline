import 'package:flutter/material.dart';
import 'package:lee_map_view/map_view.dart';

import 'map_screen.dart';

void main() {
  MapView.setApiKey("AIzaSyAPV3djPp_HceZIbgK4M4jRadHA-d08ECg");
  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: new ThemeData(
      primaryColor: const Color(0xFF02BB9F),
      primaryColorDark: const Color(0xFF167F67),
      accentColor: const Color(0xFF167F67),
    ),
    home: new MapScreen(),
  ));
}