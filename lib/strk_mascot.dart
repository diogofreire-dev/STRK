// ignore: unused_import
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOOD ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum MascotMood { idle, celebrating, encouraging, sleeping }

// ─────────────────────────────────────────────────────────────────────────────
// ASSET MAP
// ─────────────────────────────────────────────────────────────────────────────

String _assetFor(MascotMood mood) {
  switch (mood) {
    case MascotMood.idle:
      return '../assets/images/idle.png';
    case MascotMood.celebrating:
      return '../assets/images/celebrating.png';
    case MascotMood.encouraging:
      return '../assets/images/encouraging.png';
    case MascotMood.sleeping:
      return '../assets/images/sleeping.png';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class StrkMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;

  const StrkMascot({super.key, required this.mood, this.size = 100});

  @override
  State<StrkMascot> createState() => _StrkMascotState();
}

class _StrkMascotState extends State<StrkMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;
  late Animation<double> _sway;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.mood),
    )..repeat(reverse: true);
    _buildAnimations();
  }

  @override
  void didUpdateWidget(StrkMascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _controller.duration = _durationFor(widget.mood);
      _controller.repeat(reverse: true);
      _buildAnimations();
    }
  }

  void _buildAnimations() {
    _bounce = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _sway = Tween<double>(
      begin: -0.06,
      end: 0.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Duration _durationFor(MascotMood m) {
    switch (m) {
      case MascotMood.celebrating:
        return const Duration(milliseconds: 500);
      case MascotMood.encouraging:
        return const Duration(milliseconds: 900);
      case MascotMood.sleeping:
        return const Duration(milliseconds: 2200);
      case MascotMood.idle:
        return const Duration(milliseconds: 1600);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          double translateY = 0;
          double rotation = 0;
          double scaleVal = 1.0;

          switch (widget.mood) {
            case MascotMood.idle:
              translateY = _bounce.value * 0.4;
            case MascotMood.celebrating:
              translateY = _bounce.value;
              scaleVal = _scale.value;
            case MascotMood.encouraging:
              translateY = _bounce.value * 0.6;
              scaleVal = _scale.value * 0.97 + 0.03;
            case MascotMood.sleeping:
              rotation = _sway.value;
              translateY = _bounce.value * 0.2;
          }

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scaleVal,
                child: Image.asset(
                  _assetFor(widget.mood),
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: BUBBLE DE TEXTO
// ─────────────────────────────────────────────────────────────────────────────

class MascotBubble extends StatelessWidget {
  final MascotMood mood;
  final String? customMessage;

  const MascotBubble({super.key, required this.mood, this.customMessage});

  static String defaultMessage(MascotMood mood) {
    switch (mood) {
      case MascotMood.idle:
        return 'Pronto para começar? 🔥';
      case MascotMood.celebrating:
        return 'Incrível! Continua assim! 🎉';
      case MascotMood.encouraging:
        return 'Ainda dá tempo — vai lá! 💪';
      case MascotMood.sleeping:
        return 'Está na hora de voltar... 😴';
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = customMessage ?? defaultMessage(mood);
    final color = _colorFor(mood);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _colorFor(MascotMood mood) {
    switch (mood) {
      case MascotMood.idle:
        return const Color(0xFFFF6B00);
      case MascotMood.celebrating:
        return const Color(0xFFFFB300);
      case MascotMood.encouraging:
        return const Color(0xFFFF6B00);
      case MascotMood.sleeping:
        return const Color(0xFF5AC8FA);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER COMPOSTO: MASCOTE + BOLHA
// ─────────────────────────────────────────────────────────────────────────────

class StrkMascotCard extends StatelessWidget {
  final MascotMood mood;
  final String? message;
  final double mascotSize;

  const StrkMascotCard({
    super.key,
    required this.mood,
    this.message,
    this.mascotSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StrkMascot(mood: mood, size: mascotSize),
        const SizedBox(height: 12),
        MascotBubble(mood: mood, customMessage: message),
      ],
    );
  }
}
