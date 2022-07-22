import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graph/presentation/paint/widgets/colors_pilete.dart';
import 'package:graph/presentation/paint/widgets/thickness_selector.dart';
import 'package:graph/util/const.dart';
import 'package:graph/util/paint_line.dart';

class PaintView extends StatefulWidget {
  const PaintView({Key? key}) : super(key: key);

  @override
  State<PaintView> createState() => _PaintViewState();
}

class _PaintViewState extends State<PaintView> {
  final GlobalKey _globalKey = GlobalKey();
  List<PaintLine> lines = [];
  Color color = paintColor[0];
  double thickness = 5;
  bool eraseOn = false;
  Offset currPos = const Offset(0, 0);
  List<List<PaintLine>> previous = [];
  List<PaintLine> copyList(List<PaintLine> list) {
    return list
        .map((e) => PaintLine()
          ..thickness = e.thickness
          ..offsets = e.offsets
          ..color = e.color)
        .toList();
  }

  void erase(DragUpdateDetails details) {
    for (int i = 0; i < lines.length; i++) {
      PaintLine line = lines[i];
      for (var j = 0; j < line.offsets.length; j++) {
        var point = line.offsets[j];
        double xUP = details.localPosition.dx + line.thickness;
        double xDown = details.localPosition.dx - line.thickness;
        double yUp = details.localPosition.dy + line.thickness;
        double yDown = details.localPosition.dy - line.thickness;
        if (point.dx <= xUP &&
            point.dx >= xDown &&
            point.dy <= yUp &&
            point.dy >= yDown) {
          previous.add(copyList(lines));
          var first = line.offsets.sublist(0, j);
          List<Offset> second = [];
          if (line.offsets.length >= j) second = line.offsets.sublist(j + 1);
          if (first.isEmpty && second.isEmpty) {
            lines.remove(line);
          } else if (first.isEmpty) {
            line.offsets = second;
          } else if (second.isEmpty) {
            line.offsets = first;
          } else {
            line.offsets = first;
            PaintLine paintLine = PaintLine()
              ..thickness = line.thickness
              ..color = line.color
              ..offsets = second;
            lines.insert(i, paintLine);
          }
          setState(() {});
        }
      }
    }
  }

  void clear() {
    previous.clear();
    previous.add(copyList(lines));
    lines.clear();
    setState(() {});
  }

  void undo() {
    if (previous.isNotEmpty) {
      lines = previous.removeLast();
      setState(() {});
    } else {
      lines.clear();
    }
  }

  Future<Uint8List> _capturePng() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();
      var base64 = base64Encode(pngBytes);
      final anchor = AnchorElement(
          href: "data:application/octet-stream;charset=utf-16le;base64,$base64")
        ..setAttribute("download", "paint_${DateTime.now().toUtc()}.png")
        ..click();
      return pngBytes;
    } catch (e) {
      return Uint8List(0);
    }
  }

  getImage() {
    _capturePng();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
              flex: 1,
              child: Container(
                color: Colors.amber,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () {
                          setState(() {
                            eraseOn = !eraseOn;
                          });
                        },
                        icon: Icon(
                          Icons.phonelink_erase,
                          color: eraseOn ? Colors.lightBlueAccent : null,
                        )),
                    IconButton(
                        onPressed: () {
                          undo();
                        },
                        icon: const Icon(Icons.undo)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text("Clear"),
                      onPressed: () {
                        clear();
                      },
                    ),
                    IconButton(
                        onPressed: () {
                          getImage();
                        },
                        icon: const Icon(Icons.download)),
                  ],
                ),
              )),
          Expanded(
              flex: 8,
              child: Stack(children: [
                GestureDetector(
                    onPanStart: (details) {
                      if (lines.isNotEmpty) previous.add(copyList(lines));

                      if (!eraseOn) {
                        lines.add(PaintLine()
                          ..color = color
                          ..thickness = thickness);
                      }
                    },
                    onPanUpdate: (DragUpdateDetails details) {
                      if (eraseOn) {
                        setState(() {
                          currPos = details.localPosition;
                        });

                        erase(details);
                      } else {
                        int index = lines.length - 1;
                        if (index >= 0 && index < lines.length) {
                          lines[index].offsets.add(details.localPosition);
                          setState(() {});
                        }
                      }
                    },
                    child: RepaintBoundary(
                      key: _globalKey,
                      child: Container(
                        color: Colors.white,
                        child: CustomPaint(
                          painter: PaintWindow(lines: lines),
                          child: Container(),
                        ),
                      ),
                    )),
                if (eraseOn)
                  Positioned(
                    top: currPos.dy - (thickness),
                    left: currPos.dx - (thickness),
                    child: Container(
                      height: 2 * thickness,
                      width: 2 * thickness,
                      color: Colors.grey,
                    ),
                  )
              ])),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blueGrey.shade200,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ColorPalette(
                    color: color,
                    onChange: (newColor) {
                      color = newColor;
                    },
                  ),
                  ThicknessSelector(
                      initialThickness: thickness,
                      onThicknessChange: (newThickness) =>
                          thickness = newThickness),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaintWindow extends CustomPainter {
  final List<PaintLine> lines;
  const PaintWindow({required this.lines});
  @override
  void paint(Canvas canvas, Size size) {
    for (PaintLine paintLine in lines) {
      if (paintLine.offsets.isNotEmpty) {
        Paint paint = Paint()
          ..color = paintLine.color
          ..strokeWidth = paintLine.thickness
          ..style = PaintingStyle.stroke;
        Path path = Path();
        Offset first = paintLine.offsets[0];
        path.moveTo(first.dx, first.dy);
        for (Offset offset in paintLine.offsets) {
          path.lineTo(offset.dx, offset.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
