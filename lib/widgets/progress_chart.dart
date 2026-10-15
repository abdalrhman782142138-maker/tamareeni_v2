import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// رسم بياني خطي بسيط لتطور تمرين، مرسوم يدوياً بدون أي مكتبة خارجية.
/// الزمن يمتد من اليسار (الأقدم) إلى اليمين (الأحدث).
///
/// [values] القيم بالترتيب الزمني، و[labels] تسميات اختيارية بنفس الطول
/// (يُعرض أولها وآخرها تحت الرسم).
class ProgressChart extends StatelessWidget {
  const ProgressChart({
    Key? key,
    required this.values,
    this.labels = const <String>[],
    this.height = 180,
  }) : super(key: key);

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(
          values: values,
          labels: labels,
          lineColor: AppColors.accent,
          gridColor: AppTheme.border(context),
          textColor: scheme.onSurfaceVariant,
          dotInnerColor: scheme.surface,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
    required this.dotInnerColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;
  final Color dotInnerColor;

  static const double _leftPad = 36;
  static const double _rightPad = 10;
  static const double _topPad = 10;
  static const double _bottomPad = 24;
  static const double _inset = 10;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  TextPainter _text(String text) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 11, color: textColor),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final double left = _leftPad;
    final double right = size.width - _rightPad;
    final double top = _topPad + _inset;
    final double bottom = size.height - _bottomPad - _inset;
    if (right <= left || bottom <= top) return;

    double lo = values.first;
    double hi = values.first;
    for (final double v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final bool flat = (hi - lo).abs() < 0.0001;
    final int n = values.length;

    double yFor(double v) {
      if (flat) return (top + bottom) / 2;
      return bottom - (v - lo) / (hi - lo) * (bottom - top);
    }

    double xFor(int i) {
      if (n == 1) return (left + right) / 2;
      return left + i * (right - left) / (n - 1);
    }

    // --- خطوط الشبكة وتسميات المحور الرأسي ---
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final List<double> levels =
        flat ? <double>[hi] : <double>[hi, (hi + lo) / 2, lo];
    for (final double level in levels) {
      final double y = yFor(level);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final List<double> labelLevels = flat ? <double>[hi] : <double>[hi, lo];
    for (final double level in labelLevels) {
      final TextPainter tp = _text(_fmt(level));
      tp.paint(
        canvas,
        Offset(left - 6 - tp.width, yFor(level) - tp.height / 2),
      );
    }

    // --- نقاط الخط ---
    final List<Offset> points = <Offset>[];
    for (int i = 0; i < n; i++) {
      points.add(Offset(xFor(i), yFor(values[i])));
    }

    // --- التعبئة تحت الخط ---
    if (n >= 2) {
      final Path fill = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < n; i++) {
        fill.lineTo(points[i].dx, points[i].dy);
      }
      fill.lineTo(points.last.dx, bottom);
      fill.lineTo(points.first.dx, bottom);
      fill.close();

      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            lineColor.withOpacity(0.28),
            lineColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(left, top, right, bottom));
      canvas.drawPath(fill, fillPaint);

      // --- الخط نفسه ---
      final Path line = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < n; i++) {
        line.lineTo(points[i].dx, points[i].dy);
      }
      final Paint linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(line, linePaint);
    }

    // --- الدوائر على النقاط ---
    final Paint dotPaint = Paint()..color = lineColor;
    final Paint innerPaint = Paint()..color = dotInnerColor;
    for (int i = 0; i < n; i++) {
      final bool isLast = i == n - 1;
      canvas.drawCircle(points[i], isLast ? 6.5 : 4.5, dotPaint);
      canvas.drawCircle(points[i], isLast ? 3 : 2, innerPaint);
    }

    // --- تسميات المحور الأفقي: الأول والأخير ---
    if (labels.length == n && n >= 1) {
      final double labelY = size.height - _bottomPad + 6;

      final TextPainter first = _text(labels.first);
      final double firstX = math.max(0.0, xFor(0) - first.width / 2);
      first.paint(canvas, Offset(firstX, labelY));

      if (n >= 2) {
        final TextPainter last = _text(labels.last);
        final double lastX = math.min(
          size.width - last.width,
          xFor(n - 1) - last.width / 2,
        );
        last.paint(canvas, Offset(lastX, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    if (oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.dotInnerColor != dotInnerColor) {
      return true;
    }
    if (oldDelegate.values.length != values.length ||
        oldDelegate.labels.length != labels.length) {
      return true;
    }
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    for (int i = 0; i < labels.length; i++) {
      if (oldDelegate.labels[i] != labels[i]) return true;
    }
    return false;
  }
}
