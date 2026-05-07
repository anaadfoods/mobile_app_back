import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// 🌿 COMPOST COMMANDER - Premium Composting Simulation
/// Master the art of composting! Balance carbon, nitrogen, moisture & temperature.
/// Beat decay, fight pests, create black gold!
class CompostCommanderGameScreen extends StatefulWidget {
  const CompostCommanderGameScreen({super.key});
  @override
  State<CompostCommanderGameScreen> createState() => _CompostCommanderState();
}

class _CompostCommanderState extends State<CompostCommanderGameScreen>
    with TickerProviderStateMixin {
  // Game State
  GamePhase _phase = GamePhase.menu;
  GameMode _mode = GameMode.campaign;
  int _level = 1;
  int _score = 0;
  int _highScore = 0;
  int _coins = 0;
  int _xp = 0;
  int _playerLevel = 1;

  // Compost Stats (0-100)
  double _carbon = 50; // Brown materials
  double _nitrogen = 50; // Green materials
  double _moisture = 50; // Water content
  double _temperature = 35; // Internal heat (20-70°C ideal)
  double _oxygen = 70; // Aeration level
  double _maturity = 0; // Progress to finished compost

  // Game mechanics
  int _daysElapsed = 0;
  int _turnsRemaining = 30;
  bool _isPaused = false;
  List<_CompostLayer> _layers = [];
  List<_Critter> _critters = [];
  List<_Problem> _activeProblems = [];
  List<_Particle> _particles = [];
  List<_FloatingIcon> _floatingIcons = [];

  // Inventory
  final Map<String, int> _inventory = {
    'leaves': 10,
    'grass': 8,
    'food_scraps': 6,
    'cardboard': 5,
    'manure': 3,
    'straw': 4,
    'wood_chips': 5,
    'coffee': 4,
    'eggshells': 6,
    'sawdust': 3,
  };

  // Upgrades
  final Map<String, int> _upgrades = {
    'bin_size': 1,
    'thermometer': 0,
    'moisture_meter': 0,
    'tumbler': 0,
    'worm_farm': 0,
    'shredder': 0,
  };

  // Achievements
  final Map<String, bool> _achievements = {};

  // Animation Controllers
  late AnimationController _pulseCtrl,
      _glowCtrl,
      _rotateCtrl,
      _waveCtrl,
      _heatCtrl;
  late Animation<double> _pulseAnim,
      _glowAnim,
      _rotateAnim,
      _waveAnim,
      _heatAnim;
  Timer? _gameTimer;
  final _rand = math.Random();

  // Materials data
  static const _materials = [
    _Material(
      'leaves',
      '🍂',
      'Dried Leaves',
      'carbon',
      30,
      5,
      AppColors.parchment,
      'High carbon, perfect for balance',
    ),
    _Material(
      'grass',
      '🌿',
      'Grass Clippings',
      'nitrogen',
      5,
      25,
      AppColors.parchment,
      'Fresh nitrogen boost',
    ),
    _Material(
      'food_scraps',
      '🥬',
      'Food Scraps',
      'nitrogen',
      10,
      20,
      AppColors.parchment,
      'Kitchen waste, nitrogen-rich',
    ),
    _Material(
      'cardboard',
      '📦',
      'Cardboard',
      'carbon',
      40,
      2,
      AppColors.parchment,
      'Shredded cardboard, high carbon',
    ),
    _Material(
      'manure',
      '💩',
      'Aged Manure',
      'nitrogen',
      15,
      30,
      AppColors.parchment,
      'Powerful nitrogen activator',
    ),
    _Material(
      'straw',
      '🌾',
      'Straw',
      'carbon',
      35,
      8,
      AppColors.parchment,
      'Excellent structure & carbon',
    ),
    _Material(
      'wood_chips',
      '🪵',
      'Wood Chips',
      'carbon',
      50,
      3,
      AppColors.parchment,
      'Slow decomposer, great bulk',
    ),
    _Material(
      'coffee',
      '☕',
      'Coffee Grounds',
      'nitrogen',
      20,
      15,
      AppColors.parchment,
      'Worms love it! Mild nitrogen',
    ),
    _Material(
      'eggshells',
      '🥚',
      'Eggshells',
      'mineral',
      5,
      5,
      AppColors.parchment,
      'Calcium boost, pH balance',
    ),
    _Material(
      'sawdust',
      '🪚',
      'Sawdust',
      'carbon',
      45,
      2,
      AppColors.parchment,
      'Fine carbon, absorbs moisture',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadProgress();
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _rotateAnim = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateCtrl);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 1).animate(_waveCtrl);

    _heatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _heatAnim = Tween<double>(begin: 0.8, end: 1.0).animate(_heatCtrl);
  }

  void _loadProgress() {
    // In production, load from SharedPreferences
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _rotateCtrl.dispose();
    _waveCtrl.dispose();
    _heatCtrl.dispose();
    super.dispose();
  }

  void _haptic(String type) {
    switch (type) {
      case 'light':
        HapticFeedback.lightImpact();
        break;
      case 'medium':
        HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        HapticFeedback.heavyImpact();
        break;
      case 'select':
        HapticFeedback.selectionClick();
        break;
      case 'success':
        HapticFeedback.mediumImpact();
        Future.delayed(
          const Duration(milliseconds: 100),
          () => HapticFeedback.lightImpact(),
        );
        break;
      case 'error':
        HapticFeedback.heavyImpact();
        Future.delayed(
          const Duration(milliseconds: 80),
          () => HapticFeedback.heavyImpact(),
        );
        break;
    }
  }

  // ==================== GAME LOGIC ====================
  void _startGame(GameMode mode, int level) {
    _haptic('medium');
    setState(() {
      _phase = GamePhase.playing;
      _mode = mode;
      _level = level;
      _score = 0;
      _daysElapsed = 0;
      _turnsRemaining = 30 + (_level * 5);
      _maturity = 0;
      _carbon = 50;
      _nitrogen = 50;
      _moisture = 50;
      _temperature = 25;
      _oxygen = 70;
      _layers = [];
      _critters = [];
      _activeProblems = [];
      _particles = [];
      _isPaused = false;
    });

    _startGameLoop();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (_phase != GamePhase.playing || _isPaused) return;

      setState(() {
        // Update particles
        _particles =
            _particles.where((p) {
              p.life -= 0.02;
              p.x += p.vx;
              p.y += p.vy;
              p.vy += 0.08;
              p.rotation += p.rotationSpeed;
              return p.life > 0;
            }).toList();

        // Update floating icons
        _floatingIcons =
            _floatingIcons.where((f) {
              f.life -= 0.015;
              f.y -= 1.2;
              f.scale = (f.life * 1.2).clamp(0.5, 1.2);
              return f.life > 0;
            }).toList();

        // Animate critters
        for (var c in _critters) {
          c.x += (c.targetX - c.x) * 0.05;
          c.y += (c.targetY - c.y) * 0.05;
          if (_rand.nextDouble() < 0.02) {
            c.targetX = _rand.nextDouble() * 300;
            c.targetY = _rand.nextDouble() * 200;
          }
        }
      });
    });
  }

  void _addMaterial(String materialId) {
    if (_turnsRemaining <= 0) return;
    if ((_inventory[materialId] ?? 0) <= 0) {
      _haptic('error');
      return;
    }

    _haptic('medium');
    final mat = _materials.firstWhere((m) => m.id == materialId);

    setState(() {
      _inventory[materialId] = (_inventory[materialId] ?? 1) - 1;
      _turnsRemaining--;

      // Add layer visually
      _layers.add(
        _CompostLayer(
          materialId: materialId,
          emoji: mat.emoji,
          color: mat.color,
          addedDay: _daysElapsed,
        ),
      );

      // Update stats based on material type
      if (mat.type == 'carbon') {
        _carbon = (_carbon + mat.carbonValue * 0.5).clamp(0, 100);
        _nitrogen = (_nitrogen - mat.carbonValue * 0.1).clamp(0, 100);
      } else if (mat.type == 'nitrogen') {
        _nitrogen = (_nitrogen + mat.nitrogenValue * 0.5).clamp(0, 100);
        _carbon = (_carbon - mat.nitrogenValue * 0.1).clamp(0, 100);
        _temperature = (_temperature + 2).clamp(15, 80);
      }

      // Spawn particles
      _spawnAddParticles(mat);
      _addFloatingIcon(mat.emoji, 150, 200);

      // Score for balanced addition
      final balance = 100 - (_carbon - _nitrogen).abs();
      _score += (balance * 0.5).toInt() + 10;
    });

    _processDay();
  }

  void _turnCompost() {
    if (_turnsRemaining <= 0) return;
    _haptic('heavy');

    setState(() {
      _turnsRemaining--;
      _oxygen = (_oxygen + 25).clamp(0, 100);
      _temperature = (_temperature - 5).clamp(15, 80);

      // Mix layers animation
      _layers.shuffle();

      // Spawn turn particles
      for (int i = 0; i < 20; i++) {
        _particles.add(
          _Particle(
            x: 150 + _rand.nextDouble() * 100,
            y: 250,
            vx: (_rand.nextDouble() - 0.5) * 8,
            vy: -_rand.nextDouble() * 6 - 2,
            color: AppColors.rawEarth.withValues(alpha: 0.7),
            size: 4 + _rand.nextDouble() * 6,
            life: 1.0,
            rotation: 0,
            rotationSpeed: (_rand.nextDouble() - 0.5) * 0.3,
          ),
        );
      }

      _addFloatingIcon('🔄', 200, 250);
      _score += 15;

      // Check for critter spawns
      if (_oxygen > 60 && _critters.length < 5 && _rand.nextDouble() < 0.3) {
        _spawnCritter();
      }
    });

    _processDay();
  }

  void _addWater() {
    if (_turnsRemaining <= 0) return;
    _haptic('light');

    setState(() {
      _turnsRemaining--;
      _moisture = (_moisture + 20).clamp(0, 100);
      _temperature = (_temperature - 2).clamp(15, 80);

      // Water particles
      for (int i = 0; i < 15; i++) {
        _particles.add(
          _Particle(
            x: 100 + _rand.nextDouble() * 200,
            y: 50,
            vx: (_rand.nextDouble() - 0.5) * 2,
            vy: _rand.nextDouble() * 4 + 2,
            color: AppColors.deepSoilGreen.withValues(alpha: 0.6),
            size: 3 + _rand.nextDouble() * 4,
            life: 1.0,
            rotation: 0,
            rotationSpeed: 0,
          ),
        );
      }

      _addFloatingIcon('💧', 200, 100);
      _score += 10;
    });

    _processDay();
  }

  void _processDay() {
    setState(() {
      _daysElapsed++;

      // Natural decay
      _oxygen = (_oxygen - 3).clamp(0, 100);
      _moisture = (_moisture - 2).clamp(0, 100);

      // Temperature dynamics
      if (_nitrogen > 60 && _oxygen > 40) {
        _temperature = (_temperature + 3).clamp(15, 80);
      } else {
        _temperature = (_temperature - 1).clamp(15, 80);
      }

      // Calculate decomposition rate
      double decompRate = _calculateDecompRate();
      _maturity = (_maturity + decompRate).clamp(0, 100);

      // Spawn problems randomly
      if (_rand.nextDouble() < 0.1 * _level) {
        _spawnProblem();
      }

      // Update score based on conditions
      if (_isOptimalConditions()) {
        _score += 20;
        if (_rand.nextDouble() < 0.1) _spawnCritter();
      }
    });

    _checkWinLose();
  }

  double _calculateDecompRate() {
    // Optimal C:N ratio is ~30:1, we simplify to 60:40 carbon:nitrogen
    final cnBalance = 1 - ((_carbon / (_nitrogen + 1)) - 1.5).abs() / 2;
    final moistureBonus = _moisture > 40 && _moisture < 70 ? 1.2 : 0.7;
    final tempBonus = _temperature > 40 && _temperature < 65 ? 1.5 : 0.5;
    final oxygenBonus = _oxygen > 50 ? 1.3 : 0.6;

    return (cnBalance * moistureBonus * tempBonus * oxygenBonus * 2).clamp(
      0.1,
      5.0,
    );
  }

  bool _isOptimalConditions() {
    return _carbon > 40 &&
        _carbon < 70 &&
        _nitrogen > 30 &&
        _nitrogen < 60 &&
        _moisture > 40 &&
        _moisture < 65 &&
        _temperature > 40 &&
        _temperature < 60 &&
        _oxygen > 50;
  }

  void _spawnCritter() {
    final types = ['🐛', '🪱', '🐜', '🦗', '🐌'];
    _critters.add(
      _Critter(
        emoji: types[_rand.nextInt(types.length)],
        x: _rand.nextDouble() * 300,
        y: _rand.nextDouble() * 150 + 200,
        targetX: _rand.nextDouble() * 300,
        targetY: _rand.nextDouble() * 150 + 200,
      ),
    );
  }

  void _spawnProblem() {
    final problems = [
      _Problem(
        'smell',
        '🦨',
        'Bad Odor',
        'Too much nitrogen! Add carbon.',
        -10,
      ),
      _Problem('dry', '🏜️', 'Too Dry', 'Compost needs water!', -5),
      _Problem('wet', '🌊', 'Waterlogged', 'Too wet! Add dry materials.', -8),
      _Problem('cold', '🥶', 'Too Cold', 'Add nitrogen to heat it up!', -5),
      _Problem(
        'pests',
        '🪰',
        'Pest Alert',
        'Cover food scraps with browns!',
        -15,
      ),
    ];

    final problem = problems[_rand.nextInt(problems.length)];
    if (!_activeProblems.any((p) => p.id == problem.id)) {
      _activeProblems.add(problem);
      _haptic('error');
    }
  }

  void _solveProblem(_Problem problem) {
    _haptic('success');
    setState(() {
      _activeProblems.remove(problem);
      _score += 25;
      _addFloatingIcon('✅', 200, 300);
    });
  }

  void _spawnAddParticles(_Material mat) {
    for (int i = 0; i < 12; i++) {
      _particles.add(
        _Particle(
          x: 200,
          y: 150,
          vx: (_rand.nextDouble() - 0.5) * 10,
          vy: _rand.nextDouble() * 4 + 1,
          color: mat.color.withValues(alpha: 0.8),
          size: 5 + _rand.nextDouble() * 8,
          life: 1.0,
          rotation: _rand.nextDouble() * math.pi * 2,
          rotationSpeed: (_rand.nextDouble() - 0.5) * 0.2,
        ),
      );
    }
  }

  void _addFloatingIcon(String emoji, double x, double y) {
    _floatingIcons.add(
      _FloatingIcon(emoji: emoji, x: x, y: y, life: 1.0, scale: 1.0),
    );
  }

  void _checkWinLose() {
    if (_maturity >= 100) {
      _gameTimer?.cancel();
      _haptic('success');

      // Calculate stars
      int stars = 1;
      if (_score > 500) stars = 2;
      if (_score > 800 && _critters.length >= 3) stars = 3;

      // Rewards
      _coins += _score ~/ 10;
      _xp += _score ~/ 5;
      if (_xp > _playerLevel * 100) {
        _playerLevel++;
        _xp = 0;
      }
      if (_score > _highScore) _highScore = _score;

      setState(() => _phase = GamePhase.victory);
    } else if (_turnsRemaining <= 0 && _maturity < 100) {
      _gameTimer?.cancel();
      _haptic('error');
      setState(() => _phase = GamePhase.defeat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.parchment : AppColors.parchment,
      body: Stack(
        children: [
          // Premium animated background
          _buildPremiumBackground(isDark, size),

          // Main content
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: switch (_phase) {
                GamePhase.menu => _buildMenu(isDark),
                GamePhase.playing => _buildGameScreen(isDark, size),
                GamePhase.victory => _buildVictory(isDark),
                GamePhase.defeat => _buildDefeat(isDark),
                GamePhase.shop => _buildShop(isDark),
                GamePhase.levels => _buildLevelSelect(isDark),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground(bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _rotateAnim,
      builder:
          (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(
                  math.cos(_rotateAnim.value) * 0.3,
                  math.sin(_rotateAnim.value) * 0.3 - 0.3,
                ),
                radius: 1.8,
                colors:
                    isDark
                        ? [
                          AppColors.parchment,
                          AppColors.parchment,
                          AppColors.parchment,
                        ]
                        : [
                          AppColors.parchment,
                          AppColors.parchment,
                          AppColors.parchment,
                        ],
              ),
            ),
            child: CustomPaint(
              size: size,
              painter: _OrganicBackgroundPainter(
                progress: _waveAnim.value,
                isDark: isDark,
                maturity: _maturity,
              ),
            ),
          ),
    );
  }

  // ==================== MENU ====================
  Widget _buildMenu(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Epic logo
          AnimatedBuilder(
            animation: _pulseAnim,
            builder:
                (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow layers
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder:
                            (_, __) => Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.parchment.withValues(
                                      alpha: 0.4 * _glowAnim.value,
                                    ),
                                    blurRadius: 50,
                                    spreadRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: AppColors.parchment.withValues(
                                      alpha: 0.3 * _glowAnim.value,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                      ),
                      // Rotating ring
                      AnimatedBuilder(
                        animation: _rotateAnim,
                        builder:
                            (_, __) => Transform.rotate(
                              angle: _rotateAnim.value,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.deepSoilGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      left: 55,
                                      child: Text(
                                        '🍂',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 55,
                                      child: Text(
                                        '🌿',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 55,
                                      child: Text(
                                        '💧',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 55,
                                      child: Text(
                                        '🔥',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                      // Main icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            colors: [AppColors.parchment, AppColors.parchment],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.parchment,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.charcoal.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌱', style: TextStyle(fontSize: 50)),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 20),

          // Title
          ShaderMask(
            shaderCallback:
                (bounds) => const LinearGradient(
                  colors: [
                    AppColors.parchment,
                    AppColors.parchment,
                    AppColors.parchment,
                  ],
                ).createShader(bounds),
            child: const Text(
              'COMPOST',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: AppColors.parchment,
                letterSpacing: 8,
                height: 1,
              ),
            ),
          ),
          ShaderMask(
            shaderCallback:
                (bounds) => const LinearGradient(
                  colors: [
                    AppColors.parchment,
                    AppColors.parchment,
                    AppColors.parchment,
                  ],
                ).createShader(bounds),
            child: const Text(
              'COMMANDER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.parchment,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepSoilGreen.withValues(alpha: 0.2),
                  AppColors.rawEarth.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'Master the Art of Decomposition',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.deepSoilGreen,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Player stats card
          _buildGlassCard([
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBubble(
                  '🎖️',
                  'Level',
                  '$_playerLevel',
                  AppColors.harvestAmber,
                ),
                _buildStatBubble(
                  '🪙',
                  'Coins',
                  '$_coins',
                  AppColors.harvestAmber,
                ),
                _buildStatBubble('⭐', 'XP', '$_xp', AppColors.harvestAmber),
                _buildStatBubble(
                  '🏆',
                  'Best',
                  '$_highScore',
                  AppColors.deepSoilGreen,
                ),
              ],
            ),
          ], isDark),
          const SizedBox(height: 16),

          // What is composting card
          _buildGlassCard([
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepSoilGreen.withValues(alpha: 0.4),
                        AppColors.deepSoilGreen.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🌍', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is Composting?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark
                                  ? AppColors.parchment
                                  : AppColors.charcoal87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Transform organic waste into nutrient-rich "black gold" for your garden!',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark
                                  ? AppColors.parchment60
                                  : AppColors.charcoal45,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ], isDark),
          const SizedBox(height: 16),

          // Balance indicators preview
          _buildGlassCard([
            const Text(
              '⚖️ THE COMPOSTING BALANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceIndicator(
                    '🍂',
                    'Carbon',
                    'Browns',
                    AppColors.rawEarth,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBalanceIndicator(
                    '🌿',
                    'Nitrogen',
                    'Greens',
                    AppColors.deepSoilGreen,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceIndicator(
                    '💧',
                    'Moisture',
                    'Water',
                    AppColors.deepSoilGreen,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBalanceIndicator(
                    '🔥',
                    'Heat',
                    'Temp',
                    AppColors.harvestAmber,
                    isDark,
                  ),
                ),
              ],
            ),
          ], isDark),
          const SizedBox(height: 24),

          // Play buttons
          _buildPremiumButton(
            '▶  START CAMPAIGN',
            AppColors.parchment,
            () => _startGame(GameMode.campaign, _level),
            large: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPremiumButton(
                  '📊 Levels',
                  AppColors.parchment,
                  () => setState(() => _phase = GamePhase.levels),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPremiumButton(
                  '🛒 Shop',
                  AppColors.parchment,
                  () => setState(() => _phase = GamePhase.shop),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick play modes
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  '⚡',
                  'Quick Play',
                  '5 min',
                  AppColors.harvestAmber,
                  isDark,
                  () => _startGame(GameMode.quick, 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModeCard(
                  '♾️',
                  'Endless',
                  'Zen mode',
                  AppColors.deepSoilGreen,
                  isDark,
                  () => _startGame(GameMode.endless, 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: isDark ? AppColors.parchment : AppColors.charcoal26,
            ),
            label: Text(
              'Back to Games',
              style: TextStyle(
                color: isDark ? AppColors.parchment : AppColors.charcoal26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10),
            ],
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceIndicator(
    String emoji,
    String name,
    String desc,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? AppColors.parchment : AppColors.charcoal38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    String emoji,
    String title,
    String subtitle,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        _haptic('select');
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.4),
                    color.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.parchment : AppColors.charcoal38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== GAME SCREEN ====================
  Widget _buildGameScreen(bool isDark, Size size) {
    // Calculate available height for bin (screen - HUD - stats - materials - buttons - padding)
    final availableHeight =
        size.height - 280; // Approximate fixed elements height
    final binHeight = availableHeight.clamp(180.0, 280.0);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Top HUD
          _buildCompactGameHUD(isDark),

          // Compost bin area
          SizedBox(
            height: binHeight + 40,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final binWidth = size.width * 0.85;

                return Stack(
                  children: [
                    // Bin visualization (premium / 3D-ish)
                    Center(
                      child: AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) {
                          final heatGlow =
                              (_temperature - 45).clamp(0, 25) / 25; // 0..1
                          final maturityGlow = (_maturity / 100).clamp(0, 1);
                          final glowStrength =
                              (0.25 * maturityGlow + 0.35 * heatGlow) *
                              _glowAnim.value;

                          return Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Outer glow
                              Container(
                                width: binWidth + 14,
                                height: binHeight + 18,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.deepSoilGreen.withValues(
                                        alpha: 0.18 * glowStrength,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: AppColors.harvestAmber.withValues(
                                        alpha: 0.20 * glowStrength,
                                      ),
                                      blurRadius: 45,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),

                              // Bin body
                              Container(
                                width: binWidth,
                                height: binHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.parchment.withValues(
                                        alpha: isDark ? 0.65 : 0.55,
                                      ),
                                      AppColors.parchment.withValues(
                                        alpha: isDark ? 0.85 : 0.75,
                                      ),
                                      AppColors.parchment,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.rawEarth.withValues(
                                      alpha: 0.55,
                                    ),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.charcoal.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 26,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(19),
                                  child: Stack(
                                    children: [
                                      // Subtle texture overlay
                                      Positioned.fill(
                                        child: Opacity(
                                          opacity: isDark ? 0.08 : 0.05,
                                          child: CustomPaint(
                                            painter: _BinTexturePainter(
                                              progress: _waveAnim.value,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Layers
                                      ..._layers.asMap().entries.map((e) {
                                        final i = e.key;
                                        final layer = e.value;
                                        final yOffset =
                                            (binHeight - 30) -
                                            (i * 15).clamp(
                                              0,
                                              (binHeight - 60).toInt(),
                                            );
                                        return Positioned(
                                          left: 10 + _rand.nextDouble() * 20,
                                          top: yOffset.toDouble(),
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            opacity: 0.9,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: layer.color.withValues(
                                                  alpha: 0.7,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.charcoal
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                layer.emoji,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),

                                      // Critters
                                      ..._critters.map(
                                        (c) => Positioned(
                                          left: c.x.clamp(6, binWidth - 20),
                                          top: c.y.clamp(20, binHeight - 30),
                                          child: Text(
                                            c.emoji,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Heat shimmer effect
                                      if (_temperature > 50)
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _heatAnim,
                                            builder:
                                                (_, __) => Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin:
                                                          Alignment
                                                              .bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        AppColors.harvestAmber
                                                            .withValues(
                                                              alpha:
                                                                  0.10 *
                                                                  _heatAnim
                                                                      .value,
                                                            ),
                                                        AppColors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),

                                      // Maturity overlay bar
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        right: 10,
                                        child: Container(
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: AppColors.charcoal26,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: AppColors.parchment10,
                                            ),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: _maturity / 100,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    AppColors.deepSoilGreen,
                                                    AppColors.deepSoilGreen,
                                                    AppColors.harvestAmber,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors
                                                        .deepSoilGreen
                                                        .withValues(
                                                          alpha: 0.55,
                                                        ),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Rim / top lip
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: binWidth,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.parchment.withValues(
                                          alpha: isDark ? 0.75 : 0.65,
                                        ),
                                        AppColors.parchment.withValues(
                                          alpha: isDark ? 0.9 : 0.8,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: AppColors.rawEarth.withValues(
                                        alpha: 0.65,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.charcoal.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Text(
                                        _temperature > 55
                                            ? '🔥 HOT'
                                            : (_maturity > 70
                                                ? '✨ RICH'
                                                : '🌿 ACTIVE'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                          color: AppColors.parchment.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Particles
                    ..._particles.map(
                      (p) => Positioned(
                        left: p.x,
                        top: p.y,
                        child: Transform.rotate(
                          angle: p.rotation,
                          child: Opacity(
                            opacity: p.life.clamp(0, 1),
                            child: Container(
                              width: p.size,
                              height: p.size,
                              decoration: BoxDecoration(
                                color: p.color,
                                borderRadius: BorderRadius.circular(p.size / 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.color.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating icons
                    ..._floatingIcons.map(
                      (f) => Positioned(
                        left: f.x - 15,
                        top: f.y,
                        child: Opacity(
                          opacity: f.life.clamp(0, 1),
                          child: Transform.scale(
                            scale: f.scale,
                            child: Text(
                              f.emoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Problems overlay
                    if (_activeProblems.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 20,
                        right: 20,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _activeProblems
                                  .map(
                                    (p) => GestureDetector(
                                      onTap:
                                          () => _showProblemDialog(p, isDark),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.rawEarth.withValues(
                                                alpha: 0.85,
                                              ),
                                              AppColors.rawEarth.withValues(
                                                alpha: 0.55,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.parchment,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.rawEarth
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              p.emoji,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              p.name,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.parchment,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Stats display - compact
          _buildCompactStatsBar(isDark),

          // Materials inventory - compact
          _buildCompactMaterialsBar(isDark),

          // Action buttons - compact
          _buildCompactActionButtons(isDark),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCompactGameHUD(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.parchment : AppColors.parchment).withValues(
              alpha: 0.95,
            ),
            AppColors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _haptic('select');
              setState(() => _phase = GamePhase.menu);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.rawEarth.withValues(alpha: 0.3),
                    AppColors.rawEarth.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.rawEarth.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.rawEarth,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level $_level',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Day $_daysElapsed',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.parchment54 : AppColors.charcoal38,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildHudChip(
            '🎲',
            '$_turnsRemaining',
            _turnsRemaining <= 5 ? AppColors.rawEarth : AppColors.deepSoilGreen,
          ),
          const SizedBox(width: 8),
          _buildHudChip('⭐', '$_score', AppColors.harvestAmber),
          const SizedBox(width: 8),
          _buildHudChip('🌱', '${_maturity.toInt()}%', AppColors.deepSoilGreen),
        ],
      ),
    );
  }

  Widget _buildHudChip(String emoji, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.08,
            ),
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.03,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactGauge('🍂', _carbon, AppColors.rawEarth),
          _buildCompactGauge('🌿', _nitrogen, AppColors.deepSoilGreen),
          _buildCompactGauge('💧', _moisture, AppColors.deepSoilGreen),
          _buildCompactGauge('🔥', _temperature, AppColors.harvestAmber),
          _buildCompactGauge('💨', _oxygen, AppColors.deepSoilGreen),
        ],
      ),
    );
  }

  Widget _buildCompactGauge(String emoji, double value, Color color) {
    final isOptimal = value > 40 && value < 70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 3),
        Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow:
                    isOptimal
                        ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ]
                        : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toInt()}',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isOptimal ? color : color.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMaterialsBar(bool isDark) {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _materials.length,
        itemBuilder: (_, i) {
          final mat = _materials[i];
          final count = _inventory[mat.id] ?? 0;
          final isAvailable = count > 0;

          return GestureDetector(
            onTap: isAvailable ? () => _addMaterial(mat.id) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              width: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isAvailable
                          ? [
                            mat.color.withValues(alpha: 0.35),
                            mat.color.withValues(alpha: 0.15),
                          ]
                          : [
                            AppColors.rawEarth54.withValues(alpha: 0.2),
                            AppColors.rawEarth54.withValues(alpha: 0.1),
                          ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isAvailable
                          ? mat.color.withValues(alpha: 0.5)
                          : AppColors.rawEarth54.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow:
                    isAvailable
                        ? [
                          BoxShadow(
                            color: mat.color.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mat.emoji,
                    style: TextStyle(
                      fontSize: 18,
                      color: isAvailable ? null : AppColors.rawEarth54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isAvailable
                              ? mat.color.withValues(alpha: 0.3)
                              : AppColors.rawEarth54.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isAvailable ? mat.color : AppColors.rawEarth54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactAction(
              '🔄',
              'Turn',
              AppColors.harvestAmber,
              _turnCompost,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactAction(
              '💧',
              'Water',
              AppColors.deepSoilGreen,
              _addWater,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactAction(
              '📖',
              'Guide',
              AppColors.harvestAmber,
              () => _showGuide(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction(
    String emoji,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.parchment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHUD(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.charcoal : AppColors.parchment).withValues(
              alpha: 0.9,
            ),
            AppColors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Pause button
          GestureDetector(
            onTap: () {
              _haptic('select');
              setState(() => _phase = GamePhase.menu);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.charcoal26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pause_rounded,
                color: AppColors.parchment,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Day & Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $_level',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Day $_daysElapsed • ${_turnsRemaining} turns left',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.parchment60 : AppColors.charcoal45,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.harvestAmber.withValues(alpha: 0.3),
                  AppColors.harvestAmber.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.harvestAmber.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Maturity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepSoilGreen.withValues(alpha: 0.3),
                  AppColors.deepSoilGreen.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.deepSoilGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${_maturity.toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepSoilGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.1,
            ),
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.05,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatGauge(
              '🍂',
              'C',
              _carbon,
              AppColors.rawEarth,
              'Carbon',
            ),
          ),
          Expanded(
            child: _buildStatGauge(
              '🌿',
              'N',
              _nitrogen,
              AppColors.deepSoilGreen,
              'Nitrogen',
            ),
          ),
          Expanded(
            child: _buildStatGauge(
              '💧',
              'H₂O',
              _moisture,
              AppColors.deepSoilGreen,
              'Moisture',
            ),
          ),
          Expanded(
            child: _buildStatGauge(
              '🔥',
              '°C',
              _temperature,
              AppColors.harvestAmber,
              'Temp',
            ),
          ),
          Expanded(
            child: _buildStatGauge(
              '💨',
              'O₂',
              _oxygen,
              AppColors.deepSoilGreen,
              'Oxygen',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGauge(
    String emoji,
    String label,
    double value,
    Color color,
    String tooltip,
  ) {
    final isOptimal = value > 40 && value < 70;
    return Tooltip(
      message: '$tooltip: ${value.toInt()}%',
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                width: 40 * (value / 100).clamp(0, 1),
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow:
                      isOptimal
                          ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ]
                          : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toInt()}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isOptimal ? color : color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsBar(bool isDark) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _materials.length,
        itemBuilder: (_, i) {
          final mat = _materials[i];
          final count = _inventory[mat.id] ?? 0;
          final isAvailable = count > 0;

          return GestureDetector(
            onTap: isAvailable ? () => _addMaterial(mat.id) : null,
            onLongPress: () => _showMaterialInfo(mat, isDark),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isAvailable
                          ? [
                            mat.color.withValues(alpha: 0.3),
                            mat.color.withValues(alpha: 0.1),
                          ]
                          : [
                            AppColors.rawEarth54.withValues(alpha: 0.2),
                            AppColors.rawEarth54.withValues(alpha: 0.1),
                          ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isAvailable
                          ? mat.color.withValues(alpha: 0.5)
                          : AppColors.rawEarth54.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow:
                    isAvailable
                        ? [
                          BoxShadow(
                            color: mat.color.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mat.emoji,
                    style: TextStyle(
                      fontSize: 22,
                      color: isAvailable ? null : AppColors.rawEarth54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isAvailable
                              ? mat.color.withValues(alpha: 0.3)
                              : AppColors.rawEarth54.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isAvailable ? mat.color : AppColors.rawEarth54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              '🔄',
              'Turn Pile',
              AppColors.harvestAmber,
              _turnCompost,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              '💧',
              'Add Water',
              AppColors.deepSoilGreen,
              _addWater,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              '📖',
              'Guide',
              AppColors.harvestAmber,
              () => _showGuide(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String emoji,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.parchment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaterialInfo(_Material mat, bool isDark) {
    _haptic('light');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.parchment : AppColors.parchment,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.rawEarth54.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            mat.color.withValues(alpha: 0.4),
                            mat.color.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mat.color.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        mat.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mat.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  mat.type == 'carbon'
                                      ? AppColors.rawEarth.withValues(
                                        alpha: 0.2,
                                      )
                                      : AppColors.deepSoilGreen.withValues(
                                        alpha: 0.2,
                                      ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              mat.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color:
                                    mat.type == 'carbon'
                                        ? AppColors.rawEarth
                                        : AppColors.deepSoilGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  mat.description,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.parchment70 : AppColors.charcoal54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statChip(
                      '🍂',
                      'Carbon',
                      '+${mat.carbonValue}',
                      AppColors.rawEarth,
                    ),
                    _statChip(
                      '🌿',
                      'Nitrogen',
                      '+${mat.nitrogenValue}',
                      AppColors.deepSoilGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _statChip(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProblemDialog(_Problem problem, bool isDark) {
    _haptic('light');
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: isDark ? AppColors.parchment : AppColors.parchment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Text(problem.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Text(
                  problem.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Text(
              problem.solution,
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _solveProblem(problem);
                },
                child: const Text(
                  'Fix It! ✅',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
    );
  }

  void _showGuide(bool isDark) {
    _haptic('light');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (_) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.parchment : AppColors.parchment,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.rawEarth54.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '📖 COMPOSTING GUIDE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _guideSection(
                        '⚖️ The Golden Ratio',
                        'Aim for 30:1 Carbon to Nitrogen ratio. In game, keep Carbon ~60 and Nitrogen ~40.',
                      ),
                      _guideSection(
                        '🔥 Temperature',
                        'Hot compost (50-65°C) decomposes faster. Add nitrogen materials to heat up!',
                      ),
                      _guideSection(
                        '💧 Moisture',
                        'Keep it like a wrung-out sponge (40-60%). Too wet = anaerobic, too dry = slow.',
                      ),
                      _guideSection(
                        '💨 Oxygen',
                        'Turn the pile regularly to add oxygen. Aerobic bacteria work faster!',
                      ),
                      _guideSection(
                        '🐛 Critters',
                        'Worms, beetles & microbes are friends! They appear in healthy compost.',
                      ),
                      _guideSection(
                        '⏱️ Time',
                        'Real compost takes 2-6 months. Master the balance to speed up maturity!',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _guideSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepSoilGreen.withValues(alpha: 0.1),
            AppColors.deepSoilGreen.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.rawEarth70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VICTORY ====================
  Widget _buildVictory(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder:
                  (_, __) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.deepSoilGreen.withValues(alpha: 0.3),
                            AppColors.transparent,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 80)),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    colors: [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
                  ).createShader(bounds),
              child: const Text(
                'COMPOST COMPLETE!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.parchment,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You created beautiful black gold! 🌱',
              style: TextStyle(fontSize: 14, color: AppColors.deepSoilGreen),
            ),
            const SizedBox(height: 24),

            _buildGlassCard([
              _buildStatRow(
                '⭐',
                'Score',
                '$_score',
                AppColors.harvestAmber,
                isDark,
              ),
              _buildStatRow(
                '📅',
                'Days',
                '$_daysElapsed',
                AppColors.deepSoilGreen,
                isDark,
              ),
              _buildStatRow(
                '🐛',
                'Critters',
                '${_critters.length}',
                AppColors.deepSoilGreen,
                isDark,
              ),
              _buildStatRow(
                '🪙',
                'Coins Earned',
                '+${_score ~/ 10}',
                AppColors.harvestAmber,
                isDark,
              ),
            ], isDark),
            const SizedBox(height: 16),

            // Educational tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.rawEarth.withValues(alpha: 0.2),
                    AppColors.rawEarth.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.rawEarth.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text('🌍', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text(
                        'Real World Impact',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getVictoryFact(),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.parchment70 : AppColors.charcoal54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildPremiumButton(
              '➡️ Next Level',
              AppColors.deepSoilGreen,
              () => _startGame(_mode, _level + 1),
              large: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPremiumButton(
                    '🔄 Replay',
                    AppColors.harvestAmber,
                    () => _startGame(_mode, _level),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPremiumButton(
                    '🏠 Menu',
                    AppColors.deepSoilGreen,
                    () => setState(() => _phase = GamePhase.menu),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getVictoryFact() {
    final facts = [
      'Composting reduces methane emissions from landfills by diverting organic waste. Every kg composted saves ~0.5 kg of CO₂ equivalent!',
      'Finished compost can hold 20x its weight in water, reducing irrigation needs by up to 50% in gardens.',
      'Compost adds billions of beneficial microbes to soil. A teaspoon contains more microorganisms than people on Earth!',
      'Home composting can divert 30% of household waste from landfills. That\'s hundreds of kilos per year!',
      'Compost suppresses plant diseases naturally. It\'s called "black gold" for good reason - farmers treasure it.',
    ];
    return facts[_rand.nextInt(facts.length)];
  }

  // ==================== DEFEAT ====================
  Widget _buildDefeat(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('💀', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 16),
            const Text(
              'COMPOST FAILED',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reached ${_maturity.toInt()}% maturity',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.parchment60 : AppColors.charcoal45,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.harvestAmber.withValues(alpha: 0.2),
                    AppColors.harvestAmber.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.harvestAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text('💡', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text(
                        'Tips for Next Time',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getDefeatTip(),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.parchment70 : AppColors.charcoal54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildPremiumButton(
              '🔄 Try Again',
              AppColors.deepSoilGreen,
              () => _startGame(_mode, _level),
              large: true,
            ),
            const SizedBox(height: 12),
            _buildPremiumButton(
              '🏠 Menu',
              AppColors.deepSoilGreen,
              () => setState(() => _phase = GamePhase.menu),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefeatTip() {
    if (_carbon > 70)
      return 'Too much carbon (browns)! Add more nitrogen-rich greens like grass clippings or food scraps.';
    if (_nitrogen > 70)
      return 'Too much nitrogen (greens)! Balance with browns like dried leaves or cardboard.';
    if (_moisture < 30)
      return 'Compost was too dry! Remember to add water regularly.';
    if (_moisture > 75)
      return 'Compost was waterlogged! Add dry browns to absorb excess moisture.';
    if (_oxygen < 40)
      return 'Not enough oxygen! Turn the pile more often to aerate it.';
    return 'Balance is key! Aim for ~60% carbon, ~40% nitrogen, moderate moisture, and turn regularly.';
  }

  // ==================== SHOP ====================
  Widget _buildShop(bool isDark) {
    return Column(
      children: [
        _buildHeader('🛒 UPGRADE SHOP', isDark),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildShopItem(
                '🗑️',
                'Bigger Bin',
                'Hold more layers',
                100,
                'bin_size',
                isDark,
              ),
              _buildShopItem(
                '🌡️',
                'Thermometer',
                'See exact temperature',
                50,
                'thermometer',
                isDark,
              ),
              _buildShopItem(
                '💧',
                'Moisture Meter',
                'Precise moisture reading',
                50,
                'moisture_meter',
                isDark,
              ),
              _buildShopItem(
                '🔄',
                'Tumbler',
                'Easier turning, +10 O₂',
                200,
                'tumbler',
                isDark,
              ),
              _buildShopItem(
                '🪱',
                'Worm Farm',
                'Faster decomposition',
                300,
                'worm_farm',
                isDark,
              ),
              _buildShopItem(
                '⚙️',
                'Shredder',
                'Materials decompose faster',
                250,
                'shredder',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShopItem(
    String emoji,
    String name,
    String desc,
    int cost,
    String id,
    bool isDark,
  ) {
    final owned = (_upgrades[id] ?? 0) > 0;
    final canBuy = _coins >= cost && !owned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              owned
                  ? [
                    AppColors.deepSoilGreen.withValues(alpha: 0.2),
                    AppColors.deepSoilGreen.withValues(alpha: 0.05),
                  ]
                  : [
                    AppColors.rawEarth54.withValues(alpha: 0.1),
                    AppColors.rawEarth54.withValues(alpha: 0.03),
                  ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (owned ? AppColors.deepSoilGreen : AppColors.rawEarth54)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.rawEarth.withValues(alpha: 0.3),
                  AppColors.rawEarth.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.parchment54 : AppColors.charcoal45,
                  ),
                ),
              ],
            ),
          ),
          if (owned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '✓ OWNED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepSoilGreen,
                ),
              ),
            )
          else
            GestureDetector(
              onTap:
                  canBuy
                      ? () {
                        _haptic('success');
                        setState(() {
                          _coins -= cost;
                          _upgrades[id] = 1;
                        });
                      }
                      : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient:
                      canBuy
                          ? LinearGradient(
                            colors: [
                              AppColors.harvestAmber,
                              AppColors.harvestAmber,
                            ],
                          )
                          : null,
                  color:
                      canBuy
                          ? null
                          : AppColors.rawEarth54.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$cost',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color:
                            canBuy ? AppColors.parchment : AppColors.rawEarth54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== LEVEL SELECT ====================
  Widget _buildLevelSelect(bool isDark) {
    return Column(
      children: [
        _buildHeader('📊 SELECT LEVEL', isDark),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: 20,
            itemBuilder: (_, i) {
              final lvl = i + 1;
              final unlocked = lvl <= _level;

              return GestureDetector(
                onTap:
                    unlocked ? () => _startGame(GameMode.campaign, lvl) : null,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        unlocked
                            ? LinearGradient(
                              colors: [
                                AppColors.deepSoilGreen.withValues(alpha: 0.3),
                                AppColors.deepSoilGreen.withValues(alpha: 0.1),
                              ],
                            )
                            : null,
                    color:
                        unlocked
                            ? null
                            : AppColors.rawEarth54.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (unlocked
                              ? AppColors.deepSoilGreen
                              : AppColors.rawEarth54)
                          .withValues(alpha: 0.4),
                    ),
                    boxShadow:
                        unlocked
                            ? [
                              BoxShadow(
                                color: AppColors.deepSoilGreen.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                            : null,
                  ),
                  child: Center(
                    child:
                        unlocked
                            ? Text(
                              '$lvl',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.deepSoilGreen,
                              ),
                            )
                            : const Text('🔒', style: TextStyle(fontSize: 22)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _haptic('select');
              setState(() => _phase = GamePhase.menu);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.rawEarth54.withValues(alpha: 0.2),
                    AppColors.rawEarth54.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.harvestAmber.withValues(alpha: 0.3),
                  AppColors.harvestAmber.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.harvestAmber.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================
  Widget _buildGlassCard(List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.1,
            ),
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.03,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildStatRow(
    String emoji,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton(
    String label,
    Color color,
    VoidCallback onTap, {
    bool large = false,
  }) {
    return GestureDetector(
      onTap: () {
        _haptic('medium');
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 36 : 20,
          vertical: large ? 18 : 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.7),
              color.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(large ? 22 : 16),
          border: Border.all(color: AppColors.parchment.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: large ? 20 : 12,
              offset: Offset(0, large ? 8 : 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: FontWeight.w900,
              color: AppColors.parchment,
              letterSpacing: large ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DATA CLASSES ====================
enum GamePhase { menu, playing, victory, defeat, shop, levels }

enum GameMode { campaign, quick, endless }

class _Material {
  final String id, emoji, name, type, description;
  final int carbonValue, nitrogenValue;
  final Color color;
  const _Material(
    this.id,
    this.emoji,
    this.name,
    this.type,
    this.carbonValue,
    this.nitrogenValue,
    this.color,
    this.description,
  );
}

class _CompostLayer {
  final String materialId, emoji;
  final Color color;
  final int addedDay;
  _CompostLayer({
    required this.materialId,
    required this.emoji,
    required this.color,
    required this.addedDay,
  });
}

class _Critter {
  final String emoji;
  double x, y, targetX, targetY;
  _Critter({
    required this.emoji,
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
  });
}

class _Problem {
  final String id, emoji, name, solution;
  final int penalty;
  const _Problem(this.id, this.emoji, this.name, this.solution, this.penalty);
}

class _Particle {
  double x, y, vx, vy, life, size, rotation, rotationSpeed;
  final Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
    this.size = 6,
    this.rotation = 0,
    this.rotationSpeed = 0,
  });
}

class _FloatingIcon {
  final String emoji;
  double x, y, life, scale;
  _FloatingIcon({
    required this.emoji,
    required this.x,
    required this.y,
    required this.life,
    required this.scale,
  });
}

// ==================== CUSTOM PAINTER ====================
class _OrganicBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final double maturity;

  _OrganicBackgroundPainter({
    required this.progress,
    required this.isDark,
    required this.maturity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);

    // Organic shapes
    for (int i = 0; i < 15; i++) {
      final x = (rand.nextDouble() + progress * 0.1) % 1.0 * size.width;
      final y = rand.nextDouble() * size.height;
      final radius = rand.nextDouble() * 30 + 10;

      paint.color = (i % 2 == 0 ? AppColors.deepSoilGreen : AppColors.rawEarth)
          .withValues(alpha: rand.nextDouble() * 0.05 + 0.02);

      final path = Path();
      path.moveTo(x, y);
      for (int j = 0; j < 6; j++) {
        final angle = (j / 6) * math.pi * 2 + progress * math.pi * 2;
        final r = radius * (0.8 + rand.nextDouble() * 0.4);
        path.lineTo(x + math.cos(angle) * r, y + math.sin(angle) * r);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Maturity glow at bottom
    if (maturity > 0) {
      paint
        ..shader = RadialGradient(
          center: const Alignment(0, 1),
          radius: 0.8,
          colors: [
            AppColors.deepSoilGreen.withValues(alpha: maturity / 300),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicBackgroundPainter old) =>
      old.progress != progress || old.maturity != maturity;
}

class _BinTexturePainter extends CustomPainter {
  final double progress;
  _BinTexturePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    final rand = math.Random(1337);

    // Diagonal micro-lines to simulate a premium "bin texture"
    for (int i = 0; i < 26; i++) {
      final y = (i / 26) * size.height;
      final wobble = math.sin(progress * math.pi * 2 + i) * 6;
      paint.color = AppColors.parchment.withValues(
        alpha: 0.08 + rand.nextDouble() * 0.05,
      );
      canvas.drawLine(
        Offset(-20, y + wobble),
        Offset(size.width + 20, y - 16 + wobble),
        paint,
      );
    }

    // Soft vignette
    final vignette =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.2),
            radius: 1.2,
            colors: [
              AppColors.transparent,
              AppColors.charcoal.withValues(alpha: 0.25),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }

  @override
  bool shouldRepaint(covariant _BinTexturePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
