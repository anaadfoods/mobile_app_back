import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// 🦠 MICROBE MANIA - Premium Endless Runner
/// Play as beneficial soil microbe, survive chemical farms, grow your colony!
class MicrobeManiaGameScreen extends StatefulWidget {
  const MicrobeManiaGameScreen({super.key});
  @override
  State<MicrobeManiaGameScreen> createState() => _MicrobeManiaState();
}

class _MicrobeManiaState extends State<MicrobeManiaGameScreen>
    with TickerProviderStateMixin {
  // Game state
  GameState _state = GameState.menu;
  int _score = 0, _highScore = 0, _distance = 0;
  int _coins = 0, _totalCoins = 150;
  int _currentLane = 1; // 0, 1, 2 (top, middle, bottom)
  double _playerX = 0.15;
  double _energy = 100;
  int _lives = 3;
  double _speed = 1.0;
  double _multiplier = 1.0;
  int _combo = 0;

  // Unlockables & Progression
  int _selectedMicrobe = 0;
  final List<bool> _unlockedMicrobes = [true, false, false, false, false];
  final List<int> _microbePrices = [0, 200, 500, 1000, 2000];
  int _level = 1;
  int _xp = 0;
  int _xpToNext = 100;

  // Swipe tracking
  double _swipeStartY = 0;
  bool _swipeHandled = false;

  // Achievements
  final Map<String, bool> _achievements = {
    'first_run': false,
    'reach_500m': false,
    'reach_1000m': false,
    'collect_100': false,
    'combo_10': false,
    'combo_25': false,
    'survive_chemical': false,
    'unlock_microbe': false,
    'max_level': false,
  };

  // Game objects
  List<_Collectible> _collectibles = [];
  List<_Obstacle> _obstacles = [];
  List<_PowerUp> _powerUps = [];
  List<_Particle> _particles = [];
  List<_TrailParticle> _trail = [];

  // Power-up states
  bool _hasShield = false;
  bool _hasMagnet = false;
  bool _hasSpeedBoost = false;
  double _shieldTime = 0, _magnetTime = 0, _speedTime = 0;

  // Timers & Animation
  Timer? _gameTimer;
  final _rand = math.Random();
  late AnimationController _bgCtrl,
      _pulseCtrl,
      _glowCtrl,
      _shakeCtrl,
      _laneCtrl;
  late Animation<double> _bgAnim, _pulseAnim, _glowAnim, _shakeAnim, _laneAnim;
  double _bgOffset = 0;
  double _visualLane = 1.0;

  // Microbe data
  static const _microbes = [
    _MicrobeData(
      'Rhizobium',
      '🔵',
      AppColors.parchment,
      'Nitrogen Fixer',
      'Fixes atmospheric nitrogen for plants',
      1.0,
      1.0,
    ),
    _MicrobeData(
      'Azotobacter',
      '🟢',
      AppColors.parchment,
      'Free Spirit',
      'Lives freely in soil, survives longer',
      1.2,
      0.9,
    ),
    _MicrobeData(
      'Mycorrhiza',
      '🟡',
      AppColors.parchment,
      'Root Rider',
      'Can travel through root tunnels',
      0.9,
      1.3,
    ),
    _MicrobeData(
      'Trichoderma',
      '🟣',
      AppColors.parchment,
      'Warrior',
      'Destroys harmful microbes',
      1.0,
      1.2,
    ),
    _MicrobeData(
      'PSB',
      '🔴',
      AppColors.parchment,
      'Rock Breaker',
      'Solubilizes phosphorus from rocks',
      1.1,
      1.1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _shakeAnim = Tween<double>(
      begin: -12,
      end: 12,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _laneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _laneAnim = Tween<double>(
      begin: 1,
      end: 1,
    ).animate(CurvedAnimation(parent: _laneCtrl, curve: Curves.easeOutCubic));
    _laneCtrl.addListener(() => setState(() => _visualLane = _laneAnim.value));
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _shakeCtrl.dispose();
    _laneCtrl.dispose();
    super.dispose();
  }

  void _playSound(String type) {
    // Haptic + system sounds
    switch (type) {
      case 'collect':
        HapticFeedback.lightImpact();
        break;
      case 'powerup':
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        break;
      case 'damage':
        HapticFeedback.heavyImpact();
        break;
      case 'move':
        HapticFeedback.selectionClick();
        break;
      case 'button':
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        break;
      case 'win':
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.click);
        Future.delayed(
          const Duration(milliseconds: 100),
          () => HapticFeedback.mediumImpact(),
        );
        Future.delayed(
          const Duration(milliseconds: 200),
          () => HapticFeedback.lightImpact(),
        );
        break;
      case 'gameover':
        HapticFeedback.heavyImpact();
        Future.delayed(
          const Duration(milliseconds: 150),
          () => HapticFeedback.heavyImpact(),
        );
        break;
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
  }

  void _animateLaneChange(int newLane) {
    _laneAnim = Tween<double>(
      begin: _visualLane,
      end: newLane.toDouble(),
    ).animate(CurvedAnimation(parent: _laneCtrl, curve: Curves.easeOutBack));
    _laneCtrl.forward(from: 0);
  }

  void _changeLane(int delta) {
    final newLane = (_currentLane + delta).clamp(0, 2);
    if (newLane != _currentLane) {
      _playSound('move');
      setState(() => _currentLane = newLane);
      _animateLaneChange(newLane);
    }
  }

  void _startGame() {
    _playSound('button');
    setState(() {
      _state = GameState.playing;
      _score = 0;
      _distance = 0;
      _combo = 0;
      _energy = 100;
      _lives = 3;
      _speed = 1.0;
      _multiplier = 1.0;
      _currentLane = 1;
      _visualLane = 1.0;
      _playerX = 0.15;
      _collectibles = [];
      _obstacles = [];
      _powerUps = [];
      _particles = [];
      _trail = [];
      _hasShield = false;
      _hasMagnet = false;
      _hasSpeedBoost = false;
    });
    _achievements['first_run'] = true;
    _runGameLoop();
  }

  void _runGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 33), (t) {
      if (_state != GameState.playing) return;

      final microbe = _microbes[_selectedMicrobe];
      final effectiveSpeed =
          _speed * microbe.speedMod * (_hasSpeedBoost ? 1.5 : 1.0);

      setState(() {
        _distance += (effectiveSpeed * 2).round();
        _score = _distance ~/ 10;

        _bgOffset += effectiveSpeed * 0.003;
        if (_bgOffset > 1) _bgOffset -= 1;

        if (_distance % 500 == 0 && _speed < 3.0) _speed += 0.05;

        _energy -= 0.025 / microbe.energyMod;
        if (_energy <= 0) {
          _takeDamage();
          _energy = 30;
        }

        // Add trail particles
        if (t.tick % 2 == 0) {
          _trail.add(
            _TrailParticle(
              x: _playerX,
              y: 0.28 + _visualLane * 0.22,
              life: 1.0,
              color: microbe.color,
            ),
          );
        }
        _trail =
            _trail.where((p) {
              p.life -= 0.08;
              p.x -= 0.008;
              return p.life > 0;
            }).toList();

        if (_rand.nextDouble() < 0.045 + _speed * 0.012) _spawnCollectible();
        if (_rand.nextDouble() < 0.018 + _speed * 0.008) _spawnObstacle();
        if (_rand.nextDouble() < 0.005) _spawnPowerUp();

        _updateObjects(effectiveSpeed);
        _updatePowerUps();
        _updateParticles();
        _checkCollisions();
        _checkAchievements();
      });
    });
  }

  void _spawnCollectible() {
    final types = [
      _CollectType.organic,
      _CollectType.organic,
      _CollectType.organic,
      _CollectType.water,
      _CollectType.rootSugar,
      if (_rand.nextDouble() < 0.1) _CollectType.deadInsect,
    ];
    _collectibles.add(
      _Collectible(
        x: 1.1 + _rand.nextDouble() * 0.2,
        lane: _rand.nextInt(3),
        type: types[_rand.nextInt(types.length)],
      ),
    );
  }

  void _spawnObstacle() {
    final types = [
      _ObstacleType.pesticide,
      _ObstacleType.fertilizer,
      _ObstacleType.dryPatch,
      _ObstacleType.heat,
      if (_distance > 500) _ObstacleType.badBacteria,
      if (_distance > 1000) _ObstacleType.compactedSoil,
    ];
    _obstacles.add(
      _Obstacle(
        x: 1.1 + _rand.nextDouble() * 0.15,
        lane: _rand.nextInt(3),
        type: types[_rand.nextInt(types.length)],
      ),
    );
  }

  void _spawnPowerUp() {
    final types = [
      _PowerType.shield,
      _PowerType.magnet,
      _PowerType.speed,
      _PowerType.energy,
      _PowerType.multiplier,
    ];
    _powerUps.add(
      _PowerUp(
        x: 1.1,
        lane: _rand.nextInt(3),
        type: types[_rand.nextInt(types.length)],
      ),
    );
  }

  void _updateObjects(double speed) {
    final moveSpeed = 0.014 * speed;
    _collectibles =
        _collectibles.where((c) {
          c.x -= moveSpeed;
          return c.x > -0.1;
        }).toList();
    _obstacles =
        _obstacles.where((o) {
          o.x -= moveSpeed * 0.9;
          return o.x > -0.1;
        }).toList();
    _powerUps =
        _powerUps.where((p) {
          p.x -= moveSpeed;
          return p.x > -0.1;
        }).toList();
  }

  void _updatePowerUps() {
    if (_hasShield) {
      _shieldTime -= 0.033;
      if (_shieldTime <= 0) _hasShield = false;
    }
    if (_hasMagnet) {
      _magnetTime -= 0.033;
      if (_magnetTime <= 0) _hasMagnet = false;
    }
    if (_hasSpeedBoost) {
      _speedTime -= 0.033;
      if (_speedTime <= 0) _hasSpeedBoost = false;
    }

    if (_hasMagnet) {
      for (var c in _collectibles) {
        if ((c.x - _playerX).abs() < 0.35 && c.lane == _currentLane) {
          c.x -= 0.025;
        }
      }
    }
  }

  void _updateParticles() {
    _particles =
        _particles.where((p) {
          p.life -= 0.06;
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.0015;
          return p.life > 0;
        }).toList();
  }

  void _checkCollisions() {
    final playerLeft = _playerX - 0.045;
    final playerRight = _playerX + 0.045;

    _collectibles.removeWhere((c) {
      if (c.lane == _currentLane &&
          c.x > playerLeft &&
          c.x < playerRight + 0.06) {
        _collectItem(c);
        return true;
      }
      return false;
    });

    for (var o in _obstacles) {
      if (o.lane == _currentLane &&
          o.x > playerLeft &&
          o.x < playerRight + 0.04 &&
          !o.hit) {
        o.hit = true;
        if (!_hasShield) {
          _takeDamage();
          if (o.type == _ObstacleType.pesticide)
            _achievements['survive_chemical'] = true;
        } else {
          _playSound('collect');
          _spawnParticles(
            o.x,
            0.28 + _currentLane * 0.22,
            AppColors.deepSoilGreen,
            10,
          );
        }
      }
    }

    _powerUps.removeWhere((p) {
      if (p.lane == _currentLane &&
          p.x > playerLeft &&
          p.x < playerRight + 0.06) {
        _activatePowerUp(p);
        return true;
      }
      return false;
    });
  }

  void _collectItem(_Collectible c) {
    _playSound('collect');
    _combo++;

    int points = 0;
    double energyGain = 0;

    switch (c.type) {
      case _CollectType.organic:
        points = 10;
        energyGain = 5;
        break;
      case _CollectType.water:
        points = 5;
        energyGain = 8;
        break;
      case _CollectType.rootSugar:
        points = 15;
        energyGain = 12;
        break;
      case _CollectType.deadInsect:
        points = 50;
        energyGain = 25;
        _coins++;
        break;
    }

    _score += (points * _multiplier).round();
    _energy = (_energy + energyGain).clamp(0, 100);
    _xp += points ~/ 5;

    _spawnParticles(c.x, 0.28 + c.lane * 0.22, _getCollectColor(c.type), 6);

    if (_combo >= 10) _achievements['combo_10'] = true;
    if (_combo >= 25) _achievements['combo_25'] = true;
  }

  Color _getCollectColor(_CollectType type) => switch (type) {
    _CollectType.organic => AppColors.rawEarth,
    _CollectType.water => AppColors.deepSoilGreen,
    _CollectType.rootSugar => AppColors.harvestAmber,
    _CollectType.deadInsect => AppColors.harvestAmber,
  };

  void _takeDamage() {
    _playSound('damage');
    _shake();
    _combo = 0;
    _lives--;
    _spawnParticles(
      _playerX,
      0.28 + _currentLane * 0.22,
      AppColors.rawEarth,
      15,
    );

    if (_lives <= 0) _gameOver();
  }

  void _activatePowerUp(_PowerUp p) {
    _playSound('powerup');
    _spawnParticles(p.x, 0.28 + p.lane * 0.22, _getPowerColor(p.type), 12);

    switch (p.type) {
      case _PowerType.shield:
        _hasShield = true;
        _shieldTime = 8;
        break;
      case _PowerType.magnet:
        _hasMagnet = true;
        _magnetTime = 10;
        break;
      case _PowerType.speed:
        _hasSpeedBoost = true;
        _speedTime = 6;
        break;
      case _PowerType.energy:
        _energy = 100;
        break;
      case _PowerType.multiplier:
        _multiplier = 2.0;
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _state == GameState.playing)
            setState(() => _multiplier = 1.0);
        });
        break;
    }
  }

  Color _getPowerColor(_PowerType type) => switch (type) {
    _PowerType.shield => AppColors.deepSoilGreen,
    _PowerType.magnet => AppColors.harvestAmber,
    _PowerType.speed => AppColors.harvestAmber,
    _PowerType.energy => AppColors.deepSoilGreen,
    _PowerType.multiplier => AppColors.harvestAmber,
  };

  void _spawnParticles(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          x: x,
          y: y,
          color: color,
          vx: (_rand.nextDouble() - 0.5) * 0.025,
          vy: (_rand.nextDouble() - 0.5) * 0.025,
          life: 1.0,
          size: 4 + _rand.nextDouble() * 4,
        ),
      );
    }
  }

  void _checkAchievements() {
    if (_distance >= 500) _achievements['reach_500m'] = true;
    if (_distance >= 1000) _achievements['reach_1000m'] = true;
    if (_score >= 100) _achievements['collect_100'] = true;

    if (_xp >= _xpToNext) {
      _xp -= _xpToNext;
      _level++;
      _xpToNext = (_xpToNext * 1.5).round();
      _playSound('win');
      if (_level >= 10) _achievements['max_level'] = true;
    }
  }

  void _gameOver() {
    _gameTimer?.cancel();
    _playSound('gameover');

    if (_score > _highScore) _highScore = _score;
    _totalCoins += _coins;

    setState(() => _state = GameState.gameOver);
  }

  void _unlockMicrobe(int index) {
    if (_totalCoins >= _microbePrices[index] && !_unlockedMicrobes[index]) {
      _playSound('win');
      setState(() {
        _totalCoins -= _microbePrices[index];
        _unlockedMicrobes[index] = true;
        _achievements['unlock_microbe'] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.parchment : AppColors.parchment,
      body: AnimatedBuilder(
        animation: _shakeAnim,
        builder:
            (_, child) => Transform.translate(
              offset: Offset(
                _state == GameState.playing ? _shakeAnim.value : 0,
                0,
              ),
              child: child,
            ),
        child: Stack(
          children: [
            _buildPremiumBackground(isDark, size),
            SafeArea(
              child: switch (_state) {
                GameState.menu => _buildMenu(isDark, size),
                GameState.playing => _buildGame(isDark, size),
                GameState.paused => _buildPaused(isDark),
                GameState.gameOver => _buildGameOver(isDark),
                GameState.shop => _buildShop(isDark),
                GameState.achievements => _buildAchievements(isDark),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBackground(bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder:
          (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.5),
                radius: 1.8,
                colors:
                    isDark
                        ? [
                          Color.lerp(
                            AppColors.parchment,
                            AppColors.parchment,
                            _glowAnim.value,
                          )!,
                          AppColors.parchment,
                          AppColors.parchment,
                        ]
                        : [
                          Color.lerp(
                            AppColors.parchment,
                            AppColors.parchment,
                            _glowAnim.value,
                          )!,
                          AppColors.parchment,
                          AppColors.parchment,
                        ],
              ),
            ),
            child: CustomPaint(
              size: size,
              painter: _PremiumSoilPainter(
                offset: _bgOffset,
                isDark: isDark,
                glowValue: _glowAnim.value,
              ),
            ),
          ),
    );
  }

  // ==================== MENU ====================
  Widget _buildMenu(bool isDark, Size size) {
    final microbe = _microbes[_selectedMicrobe];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Premium title
          ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [
                    microbe.color,
                    microbe.color.withValues(alpha: 0.5),
                    microbe.color,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
            child: const Text(
              '🦠 MICROBE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.parchment,
                letterSpacing: 4,
                height: 1.1,
              ),
            ),
          ),
          ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [
                    AppColors.parchment.withValues(alpha: 0.9),
                    AppColors.parchment.withValues(alpha: 0.6),
                  ],
                ).createShader(bounds),
            child: const Text(
              'MANIA',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.parchment,
                letterSpacing: 8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  microbe.color.withValues(alpha: 0.2),
                  microbe.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: microbe.color.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Survive • Collect • Evolve',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: microbe.color,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Microbe showcase
          AnimatedBuilder(
            animation: _pulseAnim,
            builder:
                (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: _buildMicrobeShowcase(microbe, isDark),
                ),
          ),
          const SizedBox(height: 24),

          // Stats
          _buildPremiumCard([
            _buildStatRow(
              '🏆',
              'High Score',
              '$_highScore',
              AppColors.harvestAmber,
              isDark,
            ),
            _buildStatRow(
              '🪙',
              'Coins',
              '$_totalCoins',
              AppColors.harvestAmber,
              isDark,
            ),
            _buildStatRow(
              '⭐',
              'Level',
              '$_level',
              AppColors.deepSoilGreen,
              isDark,
            ),
            _buildStatRow(
              '📊',
              'XP',
              '$_xp / $_xpToNext',
              AppColors.deepSoilGreen,
              isDark,
            ),
          ], isDark),
          const SizedBox(height: 20),

          // Microbe selector
          _buildPremiumCard([
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        microbe.color.withValues(alpha: 0.3),
                        microbe.color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    size: 18,
                    color: AppColors.parchment70,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SELECT MICROBE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _microbes.length,
                itemBuilder: (_, i) => _buildMicrobeSelector(i, isDark),
              ),
            ),
          ], isDark),
          const SizedBox(height: 28),

          // Play button
          _buildPremiumButton(
            '▶  START GAME',
            microbe.color,
            _startGame,
            large: true,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildPremiumButton(
                  '🏪 Shop',
                  AppColors.parchment,
                  () => setState(() => _state = GameState.shop),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumButton(
                  '🏆 Badges',
                  AppColors.parchment,
                  () => setState(() => _state = GameState.achievements),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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

  Widget _buildMicrobeShowcase(_MicrobeData m, bool isDark) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder:
          (_, __) => Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  m.color.withValues(alpha: 0.35 * _glowAnim.value),
                  m.color.withValues(alpha: 0.08),
                  AppColors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: m.color.withValues(alpha: 0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: m.color.withValues(alpha: 0.5 * _glowAnim.value),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: m.color.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(m.emoji, style: const TextStyle(fontSize: 65)),
                const SizedBox(height: 10),
                Text(
                  m.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.parchment : AppColors.charcoal87,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    m.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: m.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMicrobeSelector(int index, bool isDark) {
    final m = _microbes[index];
    final unlocked = _unlockedMicrobes[index];
    final selected = _selectedMicrobe == index;

    return GestureDetector(
      onTap: () {
        if (unlocked) {
          _playSound('move');
          setState(() => _selectedMicrobe = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 65,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          gradient:
              unlocked
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      m.color.withValues(alpha: selected ? 0.5 : 0.2),
                      m.color.withValues(alpha: selected ? 0.25 : 0.05),
                    ],
                  )
                  : null,
          color: unlocked ? null : AppColors.rawEarth54.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected
                    ? m.color
                    : (unlocked
                        ? m.color.withValues(alpha: 0.3)
                        : AppColors.rawEarth54.withValues(alpha: 0.2)),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: m.color.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unlocked ? m.emoji : '🔒',
              style: TextStyle(fontSize: unlocked ? 30 : 22),
            ),
            if (!unlocked)
              Text(
                '${_microbePrices[index]}🪙',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(List<Widget> children, bool isDark) {
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
        _playSound('button');
        onTap();
      },
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder:
            (_, child) => Transform.scale(
              scale: large ? 0.98 + (_pulseAnim.value - 0.92) * 0.15 : 1.0,
              child: child,
            ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 36 : 20,
            vertical: large ? 20 : 16,
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
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(large ? 24 : 18),
            border: Border.all(
              color: AppColors.parchment.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: large ? 25 : 15,
                offset: Offset(0, large ? 10 : 6),
              ),
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: large ? 20 : 15,
                fontWeight: FontWeight.w900,
                color: AppColors.parchment,
                letterSpacing: large ? 2 : 1,
                shadows: [
                  Shadow(
                    color: AppColors.charcoal26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== GAME ====================
  Widget _buildGame(bool isDark, Size size) {
    final microbe = _microbes[_selectedMicrobe];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) {
        _swipeStartY = d.localPosition.dy;
        _swipeHandled = false;
      },
      onVerticalDragUpdate: (d) {
        if (_swipeHandled) return;
        final delta = d.localPosition.dy - _swipeStartY;
        if (delta.abs() > 25) {
          _changeLane(delta > 0 ? 1 : -1);
          _swipeHandled = true;
        }
      },
      child: Stack(
        children: [
          // Trail particles
          ..._trail.map(
            (t) => Positioned(
              left: size.width * t.x - 4,
              top: size.height * t.y - 4,
              child: Opacity(
                opacity: (t.life * 0.6).clamp(0, 1),
                child: Container(
                  width: 8 * t.life,
                  height: 8 * t.life,
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Lanes
          ..._buildPremiumLanes(isDark, size),

          // Collectibles
          ..._collectibles.map((c) => _buildCollectible(c, size)),

          // Obstacles
          ..._obstacles.map((o) => _buildObstacle(o, size)),

          // Power-ups
          ..._powerUps.map((p) => _buildPowerUpWidget(p, size)),

          // Particles
          ..._particles.map((p) => _buildParticle(p, size)),

          // Player
          _buildPlayer(microbe, size),

          // HUD
          _buildPremiumHUD(isDark, microbe),

          // Power-up indicators
          if (_hasShield || _hasMagnet || _hasSpeedBoost || _multiplier > 1)
            _buildPowerUpIndicators(isDark),

          // Swipe hint
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.charcoal38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_vertical_rounded,
                      size: 18,
                      color: AppColors.parchment60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Swipe anywhere to move',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.parchment60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pause button
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                _playSound('button');
                _gameTimer?.cancel();
                setState(() => _state = GameState.paused);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.charcoal54, AppColors.charcoal38],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.parchment),
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: AppColors.parchment,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPremiumLanes(bool isDark, Size size) {
    final microbe = _microbes[_selectedMicrobe];
    return List.generate(3, (i) {
      final y = 0.25 + i * 0.22;
      final isActive = i == _currentLane;
      return Positioned(
        left: 0,
        right: 0,
        top: size.height * y - 35,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isActive
                      ? [
                        microbe.color.withValues(alpha: 0.25),
                        microbe.color.withValues(alpha: 0.08),
                        microbe.color.withValues(alpha: 0.15),
                      ]
                      : [
                        AppColors.parchment.withValues(alpha: 0.03),
                        AppColors.transparent,
                        AppColors.parchment.withValues(alpha: 0.02),
                      ],
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color:
                  isActive
                      ? microbe.color.withValues(alpha: 0.5)
                      : AppColors.parchment.withValues(alpha: 0.08),
              width: isActive ? 2 : 1,
            ),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: microbe.color.withValues(alpha: 0.2),
                        blurRadius: 15,
                      ),
                    ]
                    : null,
          ),
        ),
      );
    });
  }

  Widget _buildPlayer(_MicrobeData microbe, Size size) {
    final y = 0.25 + _visualLane * 0.22;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      left: size.width * _playerX - 30,
      top: size.height * y - 30,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder:
            (_, __) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    microbe.color,
                    microbe.color.withValues(alpha: 0.6),
                    microbe.color.withValues(alpha: 0.3),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      _hasShield
                          ? AppColors.deepSoilGreen
                          : AppColors.parchment.withValues(alpha: 0.5),
                  width: _hasShield ? 4 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_hasShield
                            ? AppColors.deepSoilGreen
                            : microbe.color)
                        .withValues(alpha: 0.6 * _glowAnim.value),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: microbe.color.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                  if (_hasShield)
                    BoxShadow(
                      color: AppColors.deepSoilGreen.withValues(alpha: 0.4),
                      blurRadius: 35,
                      spreadRadius: 12,
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  microbe.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildCollectible(_Collectible c, Size size) {
    final y = 0.25 + c.lane * 0.22;
    final data = _getCollectibleData(c.type);
    return Positioned(
      left: size.width * c.x - 20,
      top: size.height * y - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              data.$2.withValues(alpha: 0.4),
              data.$2.withValues(alpha: 0.1),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: data.$2.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(color: data.$2.withValues(alpha: 0.4), blurRadius: 10),
          ],
        ),
        child: Center(
          child: Text(data.$1, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  (String, Color) _getCollectibleData(_CollectType type) => switch (type) {
    _CollectType.organic => ('🟤', AppColors.rawEarth),
    _CollectType.water => ('💧', AppColors.deepSoilGreen),
    _CollectType.rootSugar => ('🍯', AppColors.harvestAmber),
    _CollectType.deadInsect => ('🐛', AppColors.harvestAmber),
  };

  Widget _buildObstacle(_Obstacle o, Size size) {
    final y = 0.25 + o.lane * 0.22;
    final data = _getObstacleData(o.type);
    return Positioned(
      left: size.width * o.x - 25,
      top: size.height * y - 25,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              data.$2.withValues(alpha: 0.5),
              data.$2.withValues(alpha: 0.2),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: data.$2, width: 2.5),
          boxShadow: [
            BoxShadow(color: data.$2.withValues(alpha: 0.6), blurRadius: 15),
          ],
        ),
        child: Center(
          child: Text(data.$1, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }

  (String, Color) _getObstacleData(_ObstacleType type) => switch (type) {
    _ObstacleType.pesticide => ('☠️', AppColors.rawEarth),
    _ObstacleType.fertilizer => ('🧪', AppColors.harvestAmber),
    _ObstacleType.dryPatch => ('🏜️', AppColors.harvestAmber),
    _ObstacleType.heat => ('🔥', AppColors.rawEarth),
    _ObstacleType.badBacteria => ('👾', AppColors.harvestAmber),
    _ObstacleType.compactedSoil => ('🪨', AppColors.rawEarth54),
  };

  Widget _buildPowerUpWidget(_PowerUp p, Size size) {
    final y = 0.25 + p.lane * 0.22;
    final data = _getPowerUpData(p.type);
    return Positioned(
      left: size.width * p.x - 24,
      top: size.height * y - 24,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder:
            (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      data.$2.withValues(alpha: 0.7),
                      data.$2.withValues(alpha: 0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.parchment.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.$2.withValues(alpha: 0.7),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: AppColors.parchment.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(data.$1, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
      ),
    );
  }

  (String, Color) _getPowerUpData(_PowerType type) => switch (type) {
    _PowerType.shield => ('🛡️', AppColors.deepSoilGreen),
    _PowerType.magnet => ('🧲', AppColors.harvestAmber),
    _PowerType.speed => ('⚡', AppColors.harvestAmber),
    _PowerType.energy => ('💚', AppColors.deepSoilGreen),
    _PowerType.multiplier => ('✨', AppColors.harvestAmber),
  };

  Widget _buildParticle(_Particle p, Size size) {
    return Positioned(
      left: size.width * p.x - p.size / 2,
      top: size.height * p.y - p.size / 2,
      child: Opacity(
        opacity: p.life.clamp(0, 1),
        child: Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            color: p.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: p.color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHUD(bool isDark, _MicrobeData microbe) {
    return Positioned(
      top: 10,
      left: 10,
      right: 70,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.charcoal.withValues(alpha: 0.7),
              AppColors.charcoal.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.parchment.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: AppColors.charcoal38, blurRadius: 15)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _hudStat('🏃', '${_distance}m', AppColors.parchment),
                _hudStat('⭐', '$_score', AppColors.harvestAmber),
                _hudStat(
                  '🔥',
                  '${_combo}x',
                  _combo > 5 ? AppColors.harvestAmber : AppColors.parchment70,
                ),
                _hudStat(
                  '❤️',
                  '$_lives',
                  _lives <= 1 ? AppColors.rawEarth : AppColors.parchment,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '⚡',
                  style: TextStyle(
                    fontSize: 14,
                    shadows: [
                      Shadow(color: AppColors.deepSoilGreen, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.parchment24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Stack(
                        children: [
                          Container(color: AppColors.parchment10),
                          FractionallySizedBox(
                            widthFactor: (_energy / 100).clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      _energy > 30
                                          ? [
                                            AppColors.deepSoilGreen,
                                            AppColors.deepSoilGreen,
                                          ]
                                          : [
                                            AppColors.rawEarth,
                                            AppColors.harvestAmber,
                                          ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_energy.round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color:
                        _energy > 30
                            ? AppColors.deepSoilGreen
                            : AppColors.rawEarth,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudStat(String emoji, String value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPowerUpIndicators(bool isDark) {
    return Positioned(
      bottom: 55,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_hasShield)
            _powerIndicator('🛡️', _shieldTime, 8, AppColors.deepSoilGreen),
          if (_hasMagnet)
            _powerIndicator('🧲', _magnetTime, 10, AppColors.harvestAmber),
          if (_hasSpeedBoost)
            _powerIndicator('⚡', _speedTime, 6, AppColors.harvestAmber),
          if (_multiplier > 1)
            _powerIndicator('✨', 8, 8, AppColors.harvestAmber, label: '2x'),
        ],
      ),
    );
  }

  Widget _powerIndicator(
    String emoji,
    double time,
    double max,
    Color color, {
    String? label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          if (label != null)
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            )
          else
            SizedBox(
              width: 35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (time / max).clamp(0, 1),
                  backgroundColor: AppColors.parchment24,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== PAUSED ====================
  Widget _buildPaused(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        child: _buildPremiumCard([
          const Center(child: Text('⏸️', style: TextStyle(fontSize: 50))),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.parchment : AppColors.charcoal87,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatRow(
            '🏃',
            'Distance',
            '${_distance}m',
            AppColors.deepSoilGreen,
            isDark,
          ),
          _buildStatRow(
            '⭐',
            'Score',
            '$_score',
            AppColors.harvestAmber,
            isDark,
          ),
          _buildStatRow(
            '🔥',
            'Combo',
            '${_combo}x',
            AppColors.harvestAmber,
            isDark,
          ),
          const SizedBox(height: 24),
          _buildPremiumButton('▶  Resume', AppColors.deepSoilGreen, () {
            setState(() => _state = GameState.playing);
            _runGameLoop();
          }),
          const SizedBox(height: 10),
          _buildPremiumButton('🏠  Menu', AppColors.deepSoilGreen, () {
            _gameTimer?.cancel();
            setState(() => _state = GameState.menu);
          }),
        ], isDark),
      ),
    );
  }

  // ==================== GAME OVER ====================
  Widget _buildGameOver(bool isDark) {
    final microbe = _microbes[_selectedMicrobe];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('💀', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    colors: [AppColors.rawEarth, AppColors.harvestAmber],
                  ).createShader(bounds),
              child: const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.parchment,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildPremiumCard([
              _buildStatRow(
                '🏃',
                'Distance',
                '${_distance}m',
                AppColors.deepSoilGreen,
                isDark,
              ),
              _buildStatRow(
                '⭐',
                'Score',
                '$_score',
                AppColors.harvestAmber,
                isDark,
              ),
              _buildStatRow(
                '🪙',
                'Coins',
                '+$_coins',
                AppColors.harvestAmber,
                isDark,
              ),
              _buildStatRow(
                '🔥',
                'Max Combo',
                '${_combo}x',
                AppColors.harvestAmber,
                isDark,
              ),
              _buildStatRow(
                '🏆',
                'High Score',
                '$_highScore',
                AppColors.harvestAmber,
                isDark,
              ),
            ], isDark),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    microbe.color.withValues(alpha: 0.2),
                    microbe.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: microbe.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(microbe.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      const Text(
                        '🧠 Soil Science',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getEducationalTip(),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.parchment70 : AppColors.charcoal54,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildPremiumButton(
              '🔄  Play Again',
              AppColors.deepSoilGreen,
              _startGame,
              large: true,
            ),
            const SizedBox(height: 12),
            _buildPremiumButton(
              '🏠  Menu',
              AppColors.deepSoilGreen,
              () => setState(() => _state = GameState.menu),
            ),
          ],
        ),
      ),
    );
  }

  String _getEducationalTip() {
    final tips = [
      'Rhizobium bacteria fix 40-300 kg of nitrogen per hectare annually - completely FREE!',
      '1 teaspoon of healthy soil contains 1 billion bacteria and 1 million fungi!',
      'Chemical fertilizers kill 40% of beneficial soil microbes on contact.',
      'Mycorrhizal fungi can extend plant root systems by 100-1000 times!',
      'Earthworms process 10 tons of soil per acre per year.',
      'Healthy soil can store 20x its weight in water, preventing floods & droughts.',
      'Soil microbes communicate through chemical signals, forming complex networks.',
      'A single gram of soil can contain 10,000 different bacterial species!',
    ];
    return tips[_rand.nextInt(tips.length)];
  }

  // ==================== SHOP (FIXED OVERFLOW) ====================
  Widget _buildShop(bool isDark) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _playSound('button');
                  setState(() => _state = GameState.menu);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.parchment : AppColors.charcoal)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color:
                        isDark ? AppColors.parchment70 : AppColors.charcoal54,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '🏪 MICROBE SHOP',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
                child: Text(
                  '🪙 $_totalCoins',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.harvestAmber,
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _microbes.length,
            itemBuilder: (_, i) => _buildShopItem(i, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildShopItem(int index, bool isDark) {
    final m = _microbes[index];
    final unlocked = _unlockedMicrobes[index];
    final canAfford = _totalCoins >= _microbePrices[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            m.color.withValues(alpha: unlocked ? 0.2 : 0.1),
            m.color.withValues(alpha: unlocked ? 0.05 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: m.color.withValues(alpha: unlocked ? 0.4 : 0.2),
          width: unlocked ? 2 : 1,
        ),
        boxShadow:
            unlocked
                ? [
                  BoxShadow(
                    color: m.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  m.color.withValues(alpha: 0.4),
                  m.color.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: m.color.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(m.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.parchment : AppColors.charcoal87,
                  ),
                ),
                Text(
                  m.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: m.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.desc,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.parchment54 : AppColors.charcoal45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _microStat('⚡', '${(m.speedMod * 100).round()}%', m.color),
                    const SizedBox(width: 8),
                    _microStat(
                      '💪',
                      '${(m.energyMod * 100).round()}%',
                      m.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.deepSoilGreen.withValues(alpha: 0.3),
                    AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                '✓ Owned',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepSoilGreen,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: canAfford ? () => _unlockMicrobe(index) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient:
                      canAfford
                          ? LinearGradient(
                            colors: [
                              AppColors.harvestAmber.withValues(alpha: 0.4),
                              AppColors.harvestAmber.withValues(alpha: 0.2),
                            ],
                          )
                          : null,
                  color:
                      canAfford
                          ? null
                          : AppColors.rawEarth54.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (canAfford
                            ? AppColors.harvestAmber
                            : AppColors.rawEarth54)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '🪙 ${_microbePrices[index]}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color:
                        canAfford
                            ? AppColors.harvestAmber
                            : AppColors.rawEarth54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _microStat(String emoji, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACHIEVEMENTS ====================
  Widget _buildAchievements(bool isDark) {
    final achievementData = [
      ('first_run', '🎮', 'First Steps', 'Complete your first run'),
      ('reach_500m', '🏃', 'Marathon', 'Travel 500 meters'),
      ('reach_1000m', '🚀', 'Explorer', 'Travel 1000 meters'),
      ('collect_100', '⭐', 'Collector', 'Score 100+ points'),
      ('combo_10', '🔥', 'Combo Starter', 'Reach 10x combo'),
      ('combo_25', '💥', 'Combo Master', 'Reach 25x combo'),
      ('survive_chemical', '☠️', 'Survivor', 'Get hit by pesticide'),
      ('unlock_microbe', '🔓', 'Biologist', 'Unlock a new microbe'),
      ('max_level', '👑', 'Legend', 'Reach level 10'),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _playSound('button');
                  setState(() => _state = GameState.menu);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.parchment : AppColors.charcoal)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color:
                        isDark ? AppColors.parchment70 : AppColors.charcoal54,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '🏆 ACHIEVEMENTS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
                child: Text(
                  '${_achievements.values.where((v) => v).length}/${_achievements.length}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.harvestAmber,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievementData.length,
            itemBuilder: (_, i) {
              final a = achievementData[i];
              return _buildAchievementItem(a.$1, a.$2, a.$3, a.$4, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(
    String id,
    String emoji,
    String title,
    String desc,
    bool isDark,
  ) {
    final unlocked = _achievements[id] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              unlocked
                  ? [
                    AppColors.harvestAmber.withValues(alpha: 0.2),
                    AppColors.harvestAmber.withValues(alpha: 0.05),
                  ]
                  : [
                    AppColors.rawEarth54.withValues(alpha: 0.1),
                    AppColors.rawEarth54.withValues(alpha: 0.03),
                  ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (unlocked ? AppColors.harvestAmber : AppColors.rawEarth54)
              .withValues(alpha: unlocked ? 0.4 : 0.2),
        ),
        boxShadow:
            unlocked
                ? [
                  BoxShadow(
                    color: AppColors.harvestAmber.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient:
                  unlocked
                      ? LinearGradient(
                        colors: [
                          AppColors.harvestAmber.withValues(alpha: 0.4),
                          AppColors.harvestAmber.withValues(alpha: 0.2),
                        ],
                      )
                      : null,
              color:
                  unlocked
                      ? null
                      : AppColors.rawEarth54.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: (unlocked
                        ? AppColors.harvestAmber
                        : AppColors.rawEarth54)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                unlocked ? emoji : '🔒',
                style: TextStyle(fontSize: unlocked ? 26 : 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color:
                        unlocked
                            ? (isDark
                                ? AppColors.parchment
                                : AppColors.charcoal87)
                            : AppColors.rawEarth54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        unlocked
                            ? (isDark
                                ? AppColors.parchment60
                                : AppColors.charcoal45)
                            : AppColors.rawEarth54.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.harvestAmber, AppColors.harvestAmber],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.parchment,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== DATA CLASSES ====================
enum GameState { menu, playing, paused, gameOver, shop, achievements }

enum _CollectType { organic, water, rootSugar, deadInsect }

enum _ObstacleType {
  pesticide,
  fertilizer,
  dryPatch,
  heat,
  badBacteria,
  compactedSoil,
}

enum _PowerType { shield, magnet, speed, energy, multiplier }

class _MicrobeData {
  final String name, emoji, title, desc;
  final Color color;
  final double speedMod, energyMod;
  const _MicrobeData(
    this.name,
    this.emoji,
    this.color,
    this.title,
    this.desc,
    this.speedMod,
    this.energyMod,
  );
}

class _Collectible {
  double x;
  final int lane;
  final _CollectType type;
  _Collectible({required this.x, required this.lane, required this.type});
}

class _Obstacle {
  double x;
  final int lane;
  final _ObstacleType type;
  bool hit = false;
  _Obstacle({required this.x, required this.lane, required this.type});
}

class _PowerUp {
  double x;
  final int lane;
  final _PowerType type;
  _PowerUp({required this.x, required this.lane, required this.type});
}

class _Particle {
  double x, y, vx, vy, life, size;
  final Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.size = 6,
  });
}

class _TrailParticle {
  double x, y, life;
  final Color color;
  _TrailParticle({
    required this.x,
    required this.y,
    required this.life,
    required this.color,
  });
}

// ==================== PREMIUM SOIL PAINTER ====================
class _PremiumSoilPainter extends CustomPainter {
  final double offset;
  final bool isDark;
  final double glowValue;
  _PremiumSoilPainter({
    required this.offset,
    required this.isDark,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);

    // Moving soil particles with glow
    for (int i = 0; i < 60; i++) {
      final baseX = rand.nextDouble();
      final y = rand.nextDouble();
      final x = (baseX + offset * (0.5 + rand.nextDouble() * 0.5)) % 1.0;
      final particleSize = rand.nextDouble() * 5 + 2;

      paint.color = (isDark ? AppColors.parchment : AppColors.rawEarth)
          .withValues(alpha: rand.nextDouble() * 0.12 + 0.03);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particleSize,
        paint,
      );
    }

    // Organic matter blobs
    for (int i = 0; i < 15; i++) {
      final baseX = rand.nextDouble();
      final y = rand.nextDouble();
      final x = (baseX + offset * 0.3) % 1.0;

      paint.color = AppColors.rawEarth.withValues(
        alpha: rand.nextDouble() * 0.08 + 0.02,
      );
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        rand.nextDouble() * 20 + 10,
        paint,
      );
    }

    // Root-like lines
    paint
      ..color =
          (isDark
              ? AppColors.parchment.withValues(alpha: 0.06)
              : AppColors.rawEarth.withValues(alpha: 0.08))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 10; i++) {
      final path = Path();
      final startX = ((rand.nextDouble() + offset * 0.4) % 1.0) * size.width;
      path.moveTo(startX, size.height * 0.2);

      double x = startX, y = size.height * 0.2;
      for (int j = 0; j < 6; j++) {
        x += (rand.nextDouble() - 0.5) * 70;
        y += rand.nextDouble() * 60 + 25;
        path.quadraticBezierTo(
          x + (rand.nextDouble() - 0.5) * 30,
          y - 20,
          x.clamp(0, size.width),
          y.clamp(0, size.height),
        );
      }
      canvas.drawPath(path, paint);
    }

    // Glowing orbs
    for (int i = 0; i < 5; i++) {
      final x = ((rand.nextDouble() + offset) % 1.0) * size.width;
      final y = rand.nextDouble() * size.height;

      final gradient = RadialGradient(
        colors: [
          AppColors.deepSoilGreen.withValues(alpha: 0.15 * glowValue),
          AppColors.deepSoilGreen.withValues(alpha: 0.05 * glowValue),
          AppColors.transparent,
        ],
      );

      paint
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: 40),
        );
      canvas.drawCircle(Offset(x, y), 40, paint);
      paint.shader = null;
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumSoilPainter old) =>
      old.offset != offset || old.glowValue != glowValue;
}
