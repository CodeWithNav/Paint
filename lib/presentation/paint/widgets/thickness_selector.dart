import 'package:flutter/material.dart';

typedef OnThicknessChange = void Function(double thickness);

class ThicknessSelector extends StatefulWidget {
  const ThicknessSelector({
    Key? key,
    required this.initialThickness,
    required this.onThicknessChange,
  }) : super(key: key);
  final double initialThickness;
  final OnThicknessChange onThicknessChange;
  @override
  State<ThicknessSelector> createState() => _ThicknessSelectorState();
}

class _ThicknessSelectorState extends State<ThicknessSelector> {
  double currThickness = 1;
  @override
  initState() {
    super.initState();
    currThickness = widget.initialThickness;
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
        min: 1,
        max: 50,
        value: currThickness,
        onChanged: (value) {
          if (currThickness == value) return;
          widget.onThicknessChange(value);
          setState(() {
            currThickness = value;
          });
        });
  }
}
