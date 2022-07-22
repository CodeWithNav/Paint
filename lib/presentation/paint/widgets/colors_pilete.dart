import 'package:flutter/material.dart';
import 'package:graph/util/const.dart';

typedef ColorChange = void Function(Color color);

class ColorPalette extends StatefulWidget {
  const ColorPalette({Key? key, required this.color, required this.onChange})
      : super(key: key);
  final Color color;
  final ColorChange onChange;
  @override
  State<ColorPalette> createState() => _ColorPaletteState();
}

class _ColorPaletteState extends State<ColorPalette> {
  late Color selectedColor;

  @override
  initState() {
    super.initState();
    selectedColor = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: paintColor
          .map(
            (color) => ColorDot(
              color: color,
              selected: color == selectedColor,
              onTab: (color) {
                if (color == selectedColor) return;
                widget.onChange(color);
                setState(() => selectedColor = color);
              },
            ),
          )
          .toList(),
    );
  }
}

class ColorDot extends StatelessWidget {
  const ColorDot(
      {Key? key,
      required this.color,
      this.selected = false,
      required this.onTab})
      : super(key: key);
  final Color color;
  final bool selected;
  final ColorChange onTab;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTab(color),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
          border: selected
              ? Border.all(width: 2, color: Colors.lightBlueAccent)
              : null,
        ),
        height: 30,
        width: 30,
      ),
    );
  }
}
