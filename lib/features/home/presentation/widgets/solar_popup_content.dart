import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'realistic_popup_painter.dart';

class SolarPopupContent extends StatefulWidget {
  const SolarPopupContent({super.key});

  @override
  State<SolarPopupContent> createState() => _SolarPopupContentState();
}

class _SolarPopupContentState extends State<SolarPopupContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final Stopwatch _sw;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size;
    final w = sw.width * 0.92;
    final h = sw.height * 0.90;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1628), Color(0xFF030810)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFFFCA28).withValues(alpha: 0.22),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFCA28).withValues(alpha: 0.10),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _ticker,
                  builder: (context, _) {
                    final t = _sw.elapsed.inMilliseconds / 1000.0;
                    return CustomPaint(
                      painter: RealisticPopupPainter(t: t),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: h * 0.42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF030810).withValues(alpha: 0.75),
                          const Color(0xFF020608).withValues(alpha: 0.97),
                        ],
                        stops: const [0.0, 0.40, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: const Color(0xFFFFCA28).withValues(alpha: 0.25),
                                thickness: 0.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                '\u2726',
                                style: TextStyle(
                                  color: const Color(0xFFFFCA28).withValues(alpha: 0.60),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: const Color(0xFFFFCA28).withValues(alpha: 0.25),
                                thickness: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'FOOD MOVES WITH THE COSMOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFCA28),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Every seed sprouts with the Sun. Every harvest '
                          'follows the Moon. For thousands of years, the '
                          'Panchang \u2014 the ancient almanac of cosmic cycles \u2014 '
                          'guided when to sow, when to reap, and when to eat.\n\n'
                          'Anaad Foods honours this wisdom. We source and '
                          'deliver food in alignment with nature\u2019s rhythms, '
                          'so every grain, every vegetable, every drop of '
                          'goodness reaches you at its peak \u2014 the way the '
                          'universe intended.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w300,
                            height: 1.65,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFCA28).withValues(alpha: 0.50),
                              width: 1,
                            ),
                            color: const Color(0xFFFFCA28).withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: const Color(0xFFFFCA28).withValues(alpha: 0.80),
                                size: 13,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'COSMIC FOOD CALENDAR  \u00b7  COMING SOON',
                                style: TextStyle(
                                  color: const Color(0xFFFFCA28).withValues(alpha: 0.80),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
