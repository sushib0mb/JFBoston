import 'package:flutter/material.dart';

class StageHeader extends StatelessWidget {
  final double fontSize;
  final double timeColumnWidth;

  const StageHeader({
    super.key,
    required this.fontSize,
    required this.timeColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10, left: 13),
      child: Row(
        children: [
          // Spacer matching the time column width
          SizedBox(width: timeColumnWidth),
          // Stage 1
          Expanded(child: _stageLabel('Boston Common', fontSize - 1.5)),
          _divider(),
          // Stage 2
          Expanded(child: _stageLabel('Downtown', fontSize)),
          _divider(),
          // Stage 3
          Expanded(child: _stageLabel('Stage 3', fontSize)),
        ],
      ),
    );
  }
}

Widget _divider() => Container(
  width: 3,
  height: 30,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  ),
);

Widget _stageLabel(String txt, double fs) => Container(
  height: 50,
  decoration: BoxDecoration(
    color: const Color(0xFF8D8D97),
    borderRadius: BorderRadius.circular(36),
  ),
  alignment: Alignment.center,
  child: Text(
    txt,
    style: TextStyle(
      fontSize: fs,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    textAlign: TextAlign.center,
  ),
);
