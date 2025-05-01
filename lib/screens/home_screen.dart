import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_level_arduino/bloc/water_level_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WaterLevelBloc>().add(StartWaterLevelStreamEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Level Monitoring'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WaterLevelBloc>().add(StartWaterLevelStreamEvent());
            },
          ),
        ],
      ),
      body: const WaterLevelList(),
    );
  }
}

class WaterLevelList extends StatelessWidget {
  const WaterLevelList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterLevelBloc, WaterLevelState>(
      builder: (context, state) {
        if (state is WaterLevelLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WaterLevelLoaded) {
          final latest = state.latestData;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (latest != null)
                      SizedBox(
                        width: 200,
                        height: 300,
                        child: AnimatedWaterTank(
                          key: ValueKey(
                            latest.percent,
                          ), // Important for animation
                          percent: latest.percent,
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (latest != null)
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.blue[50],
                        margin: const EdgeInsets.only(top: 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Detail Ketinggian Air Secara Real-time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Table(
                                  columnWidths: const {
                                    0: IntrinsicColumnWidth(),
                                    1: FlexColumnWidth(),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Text(
                                            'Level:',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Text(
                                          '${latest.levelCm} cm',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Text(
                                            'Distance:',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Text(
                                          '${latest.distanceCm} cm',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Updated at: ${_formatDate(latest.createdAt.toIso8601String())}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                if (latest.percent < 20)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.warning,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Peringatan: Level air sangat rendah!',
                                            style: TextStyle(
                                              color: Colors.red[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is WaterLevelError) {
          return Center(child: Text('Error: ${state.message}'));
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }

  static String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate)?.toLocal();
    if (date == null) return rawDate;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class AnimatedWaterTank extends StatefulWidget {
  final double percent;

  const AnimatedWaterTank({super.key, required this.percent});

  @override
  State<AnimatedWaterTank> createState() => _AnimatedWaterTankState();
}

class _AnimatedWaterTankState extends State<AnimatedWaterTank>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _levelController;
  double _waveOffset = 0.0;
  double _currentPercent = 0.0;
  double _targetPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPercent = widget.percent;
    _targetPercent = widget.percent;

    // Wave animation controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Water level animation controller
    _levelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _waveController.addListener(() {
      setState(() {
        _waveOffset = _waveController.value * 2 * pi;
      });
    });
  }

  @override
  void didUpdateWidget(AnimatedWaterTank oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _targetPercent = widget.percent;
      _levelController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _levelController,
      builder: (context, child) {
        // Smoothly interpolate between current and target percent
        _currentPercent =
            lerpDouble(
              _currentPercent,
              _targetPercent,
              _levelController.value,
            )!;

        return CustomPaint(
          painter: WaterLevelContainerPainter(
            _currentPercent,
            waveOffset: _waveOffset,
          ),
        );
      },
    );
  }
}

class WaterLevelContainerPainter extends CustomPainter {
  final double percent;
  final double waveOffset;

  WaterLevelContainerPainter(this.percent, {this.waveOffset = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final containerPaint =
        Paint()
          ..color = Colors.blue[100]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    final waterColor = _getWaterColor(percent);
    final waterPaint =
        Paint()
          ..color = waterColor
          ..style = PaintingStyle.fill;

    final shadowPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;

    final markerPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    final highlightPaint =
        Paint()
          ..color =
              percent < 20
                  ? Colors.red[100]!.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final sidePaint =
        Paint()
          ..color = Colors.blue[300]!
          ..style = PaintingStyle.fill;

    final double containerWidth = size.width;
    final double containerHeight = size.height;
    final double cornerRadius = 20.0;
    final double waterHeight = containerHeight * (1 - (percent / 100));

    // Draw container shadow
    final shadowPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3, 3, containerWidth, containerHeight),
            Radius.circular(cornerRadius),
          ),
        );
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw 3D side effect
    final sidePath =
        Path()
          ..moveTo(containerWidth - 10, 0)
          ..lineTo(containerWidth - 10, containerHeight)
          ..lineTo(containerWidth, containerHeight - 10)
          ..lineTo(containerWidth, 10)
          ..close();
    canvas.drawPath(sidePath, sidePaint);

    // Draw container outline
    final containerPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, containerWidth, containerHeight),
            Radius.circular(cornerRadius),
          ),
        );
    canvas.drawPath(containerPath, containerPaint);

    // Draw water level with animated wave effect
    if (percent > 0) {
      final waterPath = Path();
      waterPath.moveTo(0, waterHeight);

      // Enhanced wave effect with animation
      final waveHeight = percent < 20 ? 4.0 : 8.0;
      final waveLength = containerWidth / 3;
      for (double x = 0; x <= containerWidth; x += 1) {
        final y =
            waterHeight +
            waveHeight *
                sin((x / waveLength * 2 * pi) + waveOffset) *
                (1 - x / containerWidth) *
                min(1.0, percent / 30);
        waterPath.lineTo(x, y);
      }

      waterPath.lineTo(containerWidth, containerHeight);
      waterPath.lineTo(0, containerHeight);
      waterPath.close();

      canvas.drawPath(waterPath, waterPaint);

      // Add dynamic water surface highlights
      final highlightPath = Path();
      final highlightX = containerWidth * 0.3 + 10 * sin(waveOffset * 1.5);
      highlightPath.moveTo(highlightX, waterHeight + waveHeight * 0.5);
      highlightPath.quadraticBezierTo(
        containerWidth * 0.5,
        waterHeight + waveHeight * 1.5,
        containerWidth * 0.7,
        waterHeight + waveHeight * 0.5,
      );
      canvas.drawPath(highlightPath, highlightPaint);

      // Add secondary smaller waves (only if not in low level warning)
      if (percent > 30) {
        final smallWavePath = Path();
        smallWavePath.moveTo(0, waterHeight + 3);
        for (double x = 0; x <= containerWidth; x += 1) {
          final y =
              waterHeight +
              3 * sin((x / (waveLength * 1.5) * 2 * pi + waveOffset * 1.2));
          smallWavePath.lineTo(x, y);
        }
        canvas.drawPath(
          smallWavePath,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }

      // Add warning ripple effect if water level is low
      if (percent < 20) {
        final ripplePaint =
            Paint()
              ..color = Colors.red.withValues(alpha: 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;

        final rippleRadius = containerWidth * 0.3 * (1 - (waveOffset % 1));
        canvas.drawCircle(
          Offset(containerWidth / 2, containerHeight - rippleRadius),
          rippleRadius,
          ripplePaint,
        );
      }
    }

    // Draw scale markers with warning color if level is low
    for (int i = 0; i <= 100; i += 10) {
      final y = containerHeight * (1 - i / 100);
      final isLowLevel = i < 20;

      canvas.drawLine(
        Offset(containerWidth, y),
        Offset(containerWidth - 10, y),
        markerPaint
          ..color =
              isLowLevel ? Colors.red : Colors.black.withValues(alpha: 0.5),
      );

      // Draw percentage text on scale
      if (i % 20 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i%',
            style: TextStyle(
              color: isLowLevel ? Colors.red : Colors.black,
              fontSize: 10,
              fontWeight: isLowLevel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(containerWidth - 30, y - 6));
      }
    }

    // Draw percentage text in center with warning style if low
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${percent.toStringAsFixed(0)}%',
        style: TextStyle(
          color:
              percent < 20
                  ? Colors.red[800]
                  : (percent > 50 ? Colors.white : Colors.blue[800]),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows:
              percent < 20
                  ? [const Shadow(color: Colors.white, blurRadius: 2)]
                  : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (containerWidth - textPainter.width) / 2,
        (containerHeight - textPainter.height) / 2,
      ),
    );

    // Add warning icon if level is low
    if (percent < 20) {
      final icon = Icons.warning;
      final builder = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 40,
            fontFamily: icon.fontFamily,
            color: Colors.red.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      builder.layout();
      builder.paint(
        canvas,
        Offset(
          (containerWidth - builder.width) / 2,
          (containerHeight - builder.height) / 2 + 40,
        ),
      );
    }
  }

  Color _getWaterColor(double percent) {
    if (percent < 20) {
      return Colors.red.withValues(alpha: 0.8);
    } else if (percent < 50) {
      return Colors.orange.withValues(alpha: 0.7);
    } else {
      return Colors.blueAccent.withValues(alpha: 0.7);
    }
  }

  @override
  bool shouldRepaint(WaterLevelContainerPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.waveOffset != waveOffset;
}
