import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    final spec = switch (priority) {
      0 => ('P0', const Color(0xffffeaea), const Color(0xffd93838)),
      1 => ('P1', const Color(0xfffff3e0), const Color(0xffdd5b00)),
      3 => ('P3', const Color(0xfff5f5f5), const Color(0xff888888)),
      _ => ('P2', const Color(0xfff0f7ff), const Color(0xff0075de)),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.$2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          spec.$1,
          style: TextStyle(
            color: spec.$3,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
