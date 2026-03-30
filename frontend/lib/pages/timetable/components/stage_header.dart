import 'package:flutter/material.dart';

class StageHeader extends StatelessWidget {
  final double fontSize;
  const StageHeader({super.key, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.64,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0xFF8D8D97),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stageLabel('Boston Common', fontSize - 1.5),
            Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            _stageLabel('Downtown', fontSize),
          ],
        ),
      ),
    );
  }
}

Widget _stageLabel(String txt, double fs) => Expanded(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
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
  ),
);
