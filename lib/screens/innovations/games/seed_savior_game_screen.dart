import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🌾 SEED SAVIOR - Premium Match-3 Puzzle
/// Save native seeds from extinction! Match 3+ to collect, avoid GMO invaders!
class SeedSaviorGameScreen extends StatefulWidget {
  const SeedSaviorGameScreen({super.key});
  @override
  State<SeedSaviorGameScreen> createState() => _SeedSaviorState();
}

class _SeedSaviorState extends State<SeedSaviorGameScreen> with TickerProviderStateMixin {
  // Game constants
  static const int gridSize = 7;
  static const int maxMoves = 25;
  
  // Game state
  GameState _state = GameState.menu;
  int _level = 1;
  int _score = 0;
  int _highScore = 0;
  int _movesLeft = maxMoves;
  int _targetScore = 500;
  int _combo = 0;
  int _maxCombo = 0;
  int _totalSeedsSaved = 0;
  int _stars = 0;
  
  // Grid
  late List<List<_Tile?>> _grid;
  _Tile? _selectedTile;
  bool _isAnimating = false;
  bool _isSwapping = false;
  
  // Particles & Effects
  List<_Particle> _particles = [];
  List<_FloatingText> _floatingTexts = [];
  List<_ShockWave> _shockWaves = [];
  
  // Seed collection (long-term)
  final Map<String, int> _seedCollection = {
    'wheat': 0, 'rice': 0, 'corn': 0, 'millet': 0, 'lentil': 0, 'mustard': 0,
  };
  
  // Achievements
  final Map<String, bool> _achievements = {
    'first_match': false, 'combo_5': false, 'combo_10': false, 'combo_15': false,
    'level_5': false, 'level_10': false, 'level_15': false, 'level_20': false,
    'collect_100': false, 'collect_500': false, 'collect_1000': false,
    'perfect_level': false, 'no_gmo': false, 'score_5000': false, 'score_10000': false,
  };
  
  // Level data - 20 levels with increasing challenge
  static const _levelConfigs = [
    _LevelConfig(1, 400, 28, 0.0, 'First Harvest', 10),
    _LevelConfig(2, 600, 27, 0.02, 'Seed Starter', 15),
    _LevelConfig(3, 800, 26, 0.04, 'Growing Strong', 20),
    _LevelConfig(4, 1000, 25, 0.06, 'Biodiversity Boost', 25),
    _LevelConfig(5, 1200, 24, 0.08, 'Heritage Seeds', 30),
    _LevelConfig(6, 1500, 23, 0.10, 'GMO Defense', 35),
    _LevelConfig(7, 1800, 22, 0.12, 'Organic Champion', 40),
    _LevelConfig(8, 2100, 21, 0.14, 'Village Farmer', 45),
    _LevelConfig(9, 2400, 20, 0.16, 'Seed Guardian', 50),
    _LevelConfig(10, 2700, 20, 0.18, 'Biodiversity Hero', 55),
    _LevelConfig(11, 3000, 19, 0.20, 'Ancient Wisdom', 60),
    _LevelConfig(12, 3400, 18, 0.22, 'Crop Diversity', 65),
    _LevelConfig(13, 3800, 18, 0.24, 'Seed Vault', 70),
    _LevelConfig(14, 4200, 17, 0.26, 'Genetic Treasure', 75),
    _LevelConfig(15, 4700, 17, 0.28, 'Nature\'s Gift', 80),
    _LevelConfig(16, 5200, 16, 0.30, 'GMO Resistance', 85),
    _LevelConfig(17, 5800, 16, 0.32, 'Desi Legacy', 90),
    _LevelConfig(18, 6400, 15, 0.34, 'Seed Warrior', 95),
    _LevelConfig(19, 7000, 15, 0.36, 'Svalbard Quest', 100),
    _LevelConfig(20, 8000, 14, 0.38, 'Master Preserver', 120),
  ];
  
  // Seed types
  static const _seeds = [
    _SeedType('wheat', '🌾', Color(0xFFD4A574), 'Desi Wheat', 'Ancient variety with high nutrition'),
    _SeedType('rice', '🍚', Color(0xFFF5F5DC), 'Red Rice', 'Rich in antioxidants'),
    _SeedType('corn', '🌽', Color(0xFFFFD700), 'Desi Corn', 'Original maize variety'),
    _SeedType('millet', '🫘', Color(0xFFDEB887), 'Finger Millet', 'Calcium-rich superfood'),
    _SeedType('lentil', '🥜', Color(0xFF8B4513), 'Black Gram', 'Protein powerhouse'),
    _SeedType('mustard', '🌻', Color(0xFFFFD700), 'Desi Mustard', 'Traditional oil seed'),
  ];
  
  // Invasive types
  static const _invasives = [
    _InvasiveType('gmo', '🧬', Color(0xFFFF4444), 'GMO Seed', 'Spreads to adjacent tiles'),
    _InvasiveType('chemical', '🧪', Color(0xFFFF8800), 'Chemical', 'Poisons 2x2 area'),
    _InvasiveType('plastic', '🛢️', Color(0xFF888888), 'Plastic', 'Blocks matches'),
  ];
  
  // Animation controllers
  late AnimationController _pulseCtrl, _glowCtrl, _shakeCtrl, _bgCtrl;
  late Animation<double> _pulseAnim, _glowAnim, _shakeAnim, _bgAnim;
  final _rand = math.Random();
  Timer? _gameTimer;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  void _initAnimations() {
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _floatAnim = Tween<double>(begin: 0, end: 1).animate(_glowCtrl);
    
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _shakeAnim = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _shakeCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }
  
  void _playSound(String type) {
    switch (type) {
      case 'match': HapticFeedback.lightImpact(); break;
      case 'combo': HapticFeedback.mediumImpact(); SystemSound.play(SystemSoundType.click); break;
      case 'special': HapticFeedback.heavyImpact(); SystemSound.play(SystemSoundType.click); break;
      case 'select': HapticFeedback.selectionClick(); break;
      case 'invalid': HapticFeedback.heavyImpact(); break;
      case 'win': 
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.mediumImpact());
        Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.lightImpact());
        SystemSound.play(SystemSoundType.click);
        break;
      case 'lose': HapticFeedback.heavyImpact(); break;
    }
  }
  
  void _shake() => _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
  
  // ==================== GAME LOGIC ====================
  void _startLevel(int level) {
    _playSound('select');
    final config = _levelConfigs[(level - 1).clamp(0, _levelConfigs.length - 1)];
    
    setState(() {
      _state = GameState.playing;
      _level = level;
      _score = 0;
      _movesLeft = config.moves;
      _targetScore = config.targetScore;
      _combo = 0;
      _particles = [];
      _floatingTexts = [];
      _shockWaves = [];
      _selectedTile = null;
      _isAnimating = false;
    });
    
    _initGrid(config.invasiveChance);
    _startGameLoop();
  }
  
  void _initGrid(double invasiveChance) {
    _grid = List.generate(gridSize, (y) => List.generate(gridSize, (x) {
      if (_rand.nextDouble() < invasiveChance && _level > 2) {
        return _Tile(x: x, y: y, type: TileType.invasive, seedIndex: _rand.nextInt(2));
      }
      return _Tile(x: x, y: y, type: TileType.seed, seedIndex: _rand.nextInt(_seeds.length));
    }));
    
    // Remove initial matches
    while (_findMatches().isNotEmpty) {
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          if (_grid[y][x]?.type == TileType.seed) {
            _grid[y][x] = _Tile(x: x, y: y, type: TileType.seed, seedIndex: _rand.nextInt(_seeds.length));
          }
        }
      }
    }
  }
  
  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (_state != GameState.playing) return;
      
      setState(() {
        // Update particles
        _particles = _particles.where((p) {
          p.life -= 0.04;
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.15;
          return p.life > 0;
        }).toList();
        
        // Update floating texts
        _floatingTexts = _floatingTexts.where((f) {
          f.life -= 0.03;
          f.y -= 1.5;
          return f.life > 0;
        }).toList();
        
        // Update shockwaves
        _shockWaves = _shockWaves.where((s) {
          s.radius += 8;
          s.opacity -= 0.04;
          return s.opacity > 0;
        }).toList();
      });
    });
  }
  
  void _selectTile(int x, int y) {
    if (_isAnimating || _grid[y][x] == null) return;
    
    final tile = _grid[y][x]!;
    if (tile.type == TileType.invasive) {
      _playSound('invalid');
      _shake();
      return;
    }
    
    if (_selectedTile == null) {
      _playSound('select');
      setState(() => _selectedTile = tile);
    } else {
      // Check if adjacent
      final dx = (tile.x - _selectedTile!.x).abs();
      final dy = (tile.y - _selectedTile!.y).abs();
      
      if ((dx == 1 && dy == 0) || (dx == 0 && dy == 1)) {
        _trySwap(_selectedTile!, tile);
      } else {
        _playSound('select');
        setState(() => _selectedTile = tile);
      }
    }
  }
  
  Future<void> _trySwap(_Tile a, _Tile b) async {
    if (_isSwapping) return;
    _isSwapping = true;
    setState(() {
      _selectedTile = null;
      _isAnimating = true;
    });
    
    // Swap
    _swap(a, b);
    await Future.delayed(const Duration(milliseconds: 200));
    
    final matches = _findMatches();
    if (matches.isEmpty) {
      // Swap back
      _playSound('invalid');
      _swap(a, b);
      await Future.delayed(const Duration(milliseconds: 200));
    } else {
      _movesLeft--;
      _combo = 0;
      await _processMatches();
    }
    
    _isSwapping = false;
    setState(() => _isAnimating = false);
    
    _checkWinLose();
  }
  
  void _swap(_Tile a, _Tile b) {
    final tempX = a.x, tempY = a.y;
    a.x = b.x; a.y = b.y;
    b.x = tempX; b.y = tempY;
    _grid[a.y][a.x] = a;
    _grid[b.y][b.x] = b;
  }
  
  List<List<_Tile>> _findMatches() {
    List<List<_Tile>> allMatches = [];
    
    // Horizontal
    for (int y = 0; y < gridSize; y++) {
      int count = 1;
      for (int x = 1; x < gridSize; x++) {
        if (_grid[y][x] != null && _grid[y][x - 1] != null &&
            _grid[y][x]!.type == TileType.seed && _grid[y][x - 1]!.type == TileType.seed &&
            _grid[y][x]!.seedIndex == _grid[y][x - 1]!.seedIndex) {
          count++;
        } else {
          if (count >= 3) {
            allMatches.add([for (int i = x - count; i < x; i++) _grid[y][i]!]);
          }
          count = 1;
        }
      }
      if (count >= 3) {
        allMatches.add([for (int i = gridSize - count; i < gridSize; i++) _grid[y][i]!]);
      }
    }
    
    // Vertical
    for (int x = 0; x < gridSize; x++) {
      int count = 1;
      for (int y = 1; y < gridSize; y++) {
        if (_grid[y][x] != null && _grid[y - 1][x] != null &&
            _grid[y][x]!.type == TileType.seed && _grid[y - 1][x]!.type == TileType.seed &&
            _grid[y][x]!.seedIndex == _grid[y - 1][x]!.seedIndex) {
          count++;
        } else {
          if (count >= 3) {
            allMatches.add([for (int i = y - count; i < y; i++) _grid[i][x]!]);
          }
          count = 1;
        }
      }
      if (count >= 3) {
        allMatches.add([for (int i = gridSize - count; i < gridSize; i++) _grid[i][x]!]);
      }
    }
    
    return allMatches;
  }
  
  Future<void> _processMatches() async {
    var matches = _findMatches();
    
    while (matches.isNotEmpty) {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      
      if (_combo >= 5) _achievements['combo_5'] = true;
      if (_combo >= 10) _achievements['combo_10'] = true;
      if (_combo >= 15) _achievements['combo_15'] = true;
      
      // Calculate points
      int matchPoints = 0;
      Set<_Tile> tilesToRemove = {};
      
      for (var match in matches) {
        tilesToRemove.addAll(match);
        
        final basePoints = match.length * 10;
        final comboBonus = _combo * 5;
        final lengthBonus = match.length > 3 ? (match.length - 3) * 20 : 0;
        matchPoints += basePoints + comboBonus + lengthBonus;
        
        // Special effects for big matches
        if (match.length >= 5) {
          _playSound('special');
          _createShockWave(match[match.length ~/ 2]);
          // Clear row/column
          for (int i = 0; i < gridSize; i++) {
            if (_grid[match[0].y][i]?.type == TileType.seed) tilesToRemove.add(_grid[match[0].y][i]!);
          }
        } else if (match.length == 4) {
          _playSound('combo');
          _createShockWave(match[2]);
        } else {
          _playSound('match');
        }
        
        // Add to collection
        if (match.isNotEmpty && match[0].type == TileType.seed) {
          final seedName = _seeds[match[0].seedIndex].id;
          _seedCollection[seedName] = (_seedCollection[seedName] ?? 0) + match.length;
          _totalSeedsSaved += match.length;
        }
      }
      
      _score += matchPoints;
      _achievements['first_match'] = true;
      
      // Create particles and remove tiles
      for (var tile in tilesToRemove) {
        _spawnMatchParticles(tile);
        _addFloatingText('+${10 + _combo * 5}', tile.x, tile.y, _seeds[tile.seedIndex].color);
        _grid[tile.y][tile.x] = null;
      }
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Drop tiles
      await _dropTiles();
      
      // Fill empty
      await _fillEmpty();
      
      // Spread invasives (on higher levels)
      if (_level > 3 && _rand.nextDouble() < 0.1) {
        _spreadInvasives();
      }
      
      matches = _findMatches();
      setState(() {});
    }
  }
  
  Future<void> _dropTiles() async {
    bool dropped = true;
    while (dropped) {
      dropped = false;
      for (int x = 0; x < gridSize; x++) {
        for (int y = gridSize - 1; y > 0; y--) {
          if (_grid[y][x] == null && _grid[y - 1][x] != null) {
            _grid[y][x] = _grid[y - 1][x];
            _grid[y][x]!.y = y;
            _grid[y - 1][x] = null;
            dropped = true;
          }
        }
      }
      if (dropped) {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }
  
  Future<void> _fillEmpty() async {
    final config = _levelConfigs[(_level - 1).clamp(0, _levelConfigs.length - 1)];
    
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        if (_grid[y][x] == null) {
          if (_rand.nextDouble() < config.invasiveChance * 0.3 && _level > 2) {
            _grid[y][x] = _Tile(x: x, y: y, type: TileType.invasive, seedIndex: _rand.nextInt(2));
          } else {
            _grid[y][x] = _Tile(x: x, y: y, type: TileType.seed, seedIndex: _rand.nextInt(_seeds.length));
          }
        }
      }
    }
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  void _spreadInvasives() {
    List<_Tile> newInvasives = [];
    
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (_grid[y][x]?.type == TileType.invasive) {
          // Spread to random adjacent
          final dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
          dirs.shuffle();
          for (var d in dirs) {
            final nx = x + d[0], ny = y + d[1];
            if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
              if (_grid[ny][nx]?.type == TileType.seed && _rand.nextDouble() < 0.3) {
                newInvasives.add(_Tile(x: nx, y: ny, type: TileType.invasive, seedIndex: 0));
                break;
              }
            }
          }
        }
      }
    }
    
    for (var inv in newInvasives) {
      _grid[inv.y][inv.x] = inv;
      _spawnInvasiveParticles(inv);
    }
  }
  
  void _checkWinLose() {
    if (_score >= _targetScore) {
      _gameTimer?.cancel();
      _playSound('win');
      
      // Calculate stars
      final efficiency = _score / _targetScore;
      _stars = efficiency >= 1.5 ? 3 : efficiency >= 1.2 ? 2 : 1;
      
      if (_score > _highScore) _highScore = _score;
      if (_movesLeft == maxMoves) _achievements['perfect_level'] = true;
      if (_level >= 5) _achievements['level_5'] = true;
      if (_level >= 10) _achievements['level_10'] = true;
      if (_level >= 15) _achievements['level_15'] = true;
      if (_level >= 20) _achievements['level_20'] = true;
      if (_totalSeedsSaved >= 100) _achievements['collect_100'] = true;
      if (_totalSeedsSaved >= 500) _achievements['collect_500'] = true;
      if (_totalSeedsSaved >= 1000) _achievements['collect_1000'] = true;
      if (_score >= 5000) _achievements['score_5000'] = true;
      if (_score >= 10000) _achievements['score_10000'] = true;
      
      setState(() => _state = GameState.levelComplete);
    } else if (_movesLeft <= 0) {
      _gameTimer?.cancel();
      _playSound('lose');
      setState(() => _state = GameState.gameOver);
    }
  }
  
  void _spawnMatchParticles(_Tile tile) {
    final color = _seeds[tile.seedIndex].color;
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: tile.x * 50.0 + 25,
        y: tile.y * 50.0 + 25,
        vx: (_rand.nextDouble() - 0.5) * 12,
        vy: (_rand.nextDouble() - 0.5) * 12 - 5,
        color: color,
        life: 1.0,
        size: 4 + _rand.nextDouble() * 6,
      ));
    }
  }
  
  void _spawnInvasiveParticles(_Tile tile) {
    for (int i = 0; i < 8; i++) {
      _particles.add(_Particle(
        x: tile.x * 50.0 + 25,
        y: tile.y * 50.0 + 25,
        vx: (_rand.nextDouble() - 0.5) * 8,
        vy: (_rand.nextDouble() - 0.5) * 8,
        color: Colors.red,
        life: 1.0,
        size: 3 + _rand.nextDouble() * 4,
      ));
    }
  }
  
  void _addFloatingText(String text, int x, int y, Color color) {
    _floatingTexts.add(_FloatingText(
      text: text,
      x: x * 50.0 + 25,
      y: y * 50.0,
      color: color,
      life: 1.0,
    ));
  }
  
  void _createShockWave(_Tile tile) {
    _shockWaves.add(_ShockWave(
      x: tile.x * 50.0 + 25,
      y: tile.y * 50.0 + 25,
      radius: 10,
      opacity: 0.8,
      color: _seeds[tile.seedIndex].color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F08) : const Color(0xFFF5F0E8),
      body: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_state == GameState.playing ? _shakeAnim.value : 0, 0),
          child: child,
        ),
        child: Stack(
          children: [
            _buildPremiumBackground(isDark, size),
            SafeArea(
              child: switch (_state) {
                GameState.menu => _buildMenu(isDark),
                GameState.playing => _buildGame(isDark, size),
                GameState.levelComplete => _buildLevelComplete(isDark),
                GameState.gameOver => _buildGameOver(isDark),
                GameState.collection => _buildCollection(isDark),
                GameState.levels => _buildLevelSelect(isDark),
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPremiumBackground(bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3 + math.sin(_bgAnim.value * math.pi * 2) * 0.3, -0.5),
            radius: 1.5,
            colors: isDark
              ? [const Color(0xFF1A2810), const Color(0xFF0A0F08), const Color(0xFF080A06)]
              : [const Color(0xFFF8F4E8), const Color(0xFFF0E8D8), const Color(0xFFE8E0D0)],
          ),
        ),
        child: CustomPaint(
          size: size,
          painter: _FarmBackgroundPainter(offset: _bgAnim.value, isDark: isDark),
        ),
      ),
    );
  }

  // ==================== MENU ====================
  Widget _buildMenu(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Title with animation
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.green.withOpacity(0.3 * _glowAnim.value), blurRadius: 40, spreadRadius: 15),
                              BoxShadow(color: Colors.amber.withOpacity(0.2 * _glowAnim.value), blurRadius: 30, spreadRadius: 10),
                            ],
                          ),
                        ),
                      ),
                      const Text('🌾', style: TextStyle(fontSize: 70)),
                    ],
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39)],
                    ).createShader(bounds),
                    child: const Text('SEED', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6, height: 1)),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                    ).createShader(bounds),
                    child: const Text('SAVIOR', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Text('Match • Collect • Save Biodiversity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green, letterSpacing: 1)),
          ),
          const SizedBox(height: 20),
          
          // Mission statement
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.withOpacity(isDark ? 0.2 : 0.1), Colors.brown.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.brown.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Mission', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      Text(
                        'Save India\'s native seeds from extinction! Match to collect, avoid GMO invaders.',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black45, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats card
          _buildPremiumCard([
            _buildStatRow('🏆', 'High Score', '$_highScore', Colors.amber, isDark),
            _buildStatRow('🌱', 'Seeds Saved', '$_totalSeedsSaved', Colors.green, isDark),
            _buildStatRow('⭐', 'Current Level', '$_level / 20', Colors.blue, isDark),
            _buildStatRow('🔥', 'Best Combo', '${_maxCombo}x', Colors.orange, isDark),
          ], isDark),
          const SizedBox(height: 16),
          
          // Did you know card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.withOpacity(0.2), Colors.teal.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green.withOpacity(0.4), Colors.green.withOpacity(0.2)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('💡', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    const Text('DID YOU KNOW?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _getMenuFact(),
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Seed preview
          _buildPremiumCard([
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded, size: 18, color: Colors.green),
                ),
                const SizedBox(width: 10),
                const Text('NATIVE SEEDS TO SAVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _seeds.map((s) => _seedPreviewChip(s, isDark)).toList(),
            ),
          ], isDark),
          const SizedBox(height: 10),
          
          // Enemies warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WATCH OUT FOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.red, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _enemyChip('🧬', 'GMO Seeds', Colors.red),
                          const SizedBox(width: 8),
                          _enemyChip('🧪', 'Chemicals', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Play button
          _buildPremiumButton('▶  PLAY LEVEL $_level', const Color(0xFF4CAF50), () => _startLevel(_level), large: true),
          const SizedBox(height: 14),
          
          Row(
            children: [
              Expanded(child: _buildPremiumButton('📊 Levels', const Color(0xFF2196F3), () => setState(() => _state = GameState.levels))),
              const SizedBox(width: 12),
              Expanded(child: _buildPremiumButton('🌿 Collection', const Color(0xFF9C27B0), () => setState(() => _state = GameState.collection))),
            ],
          ),
          const SizedBox(height: 16),
          
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black26),
            label: Text('Back to Games', style: TextStyle(color: isDark ? Colors.white38 : Colors.black26, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
  
  Widget _enemyChip(String emoji, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
  
  String _getMenuFact() {
    final facts = [
      'India was home to 100,000+ rice varieties. Today only 6,000 survive. Your matches help preserve biodiversity!',
      'Millets need 70% less water than paddy rice and were India\'s staple for 5,000 years before the Green Revolution.',
      'Native seeds are naturally resistant to local pests. They don\'t need chemical pesticides to thrive.',
      'Traditional farmers were expert seed savers. They selected the best seeds each harvest for 10,000+ generations.',
      'The Svalbard Global Seed Vault in Norway stores 1.1 million seed varieties as humanity\'s backup.',
      'Red rice contains anthocyanins - the same antioxidants in blueberries. It was food of royalty!',
      'Finger millet has 3x more calcium than milk. Ancient warriors ate ragi for strength and endurance.',
      'Each native variety lost is a unique solution to climate, soil, and pest challenges - gone forever.',
    ];
    return facts[DateTime.now().minute % facts.length];
  }
  
  Widget _seedPreviewChip(_SeedType seed, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [seed.color.withOpacity(0.3), seed.color.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: seed.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(seed.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(seed.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: seed.color)),
        ],
      ),
    );
  }

  // ==================== GAME ====================
  Widget _buildGame(bool isDark, Size size) {
    final gridWidth = gridSize * 50.0 + 16;
    final offsetX = (size.width - gridWidth) / 2;
    final config = _levelConfigs[(_level - 1).clamp(0, _levelConfigs.length - 1)];
    
    return Stack(
      children: [
        // Decorative top banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.withOpacity(isDark ? 0.3 : 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // HUD
        _buildGameHUD(isDark),
        
        // Seed wisdom tip below HUD
        Positioned(
          top: 118,
          left: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.15 * _glowAnim.value),
                    Colors.orange.withOpacity(0.08 * _glowAnim.value),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getGameTip(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber[200] : Colors.amber[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Grid with decorative frame
        Positioned(
          top: 155,
          left: offsetX - 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.withOpacity(0.3), Colors.brown.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                    (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.15), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12))],
              ),
              child: SizedBox(
                width: gridSize * 50.0,
                height: gridSize * 50.0,
                child: Stack(
                  children: [
                    // Tiles
                    for (int y = 0; y < gridSize; y++)
                      for (int x = 0; x < gridSize; x++)
                        if (_grid[y][x] != null)
                          _buildTile(_grid[y][x]!, isDark),
                    
                    // Particles
                    ..._particles.map((p) => Positioned(
                      left: p.x - p.size / 2,
                      top: p.y - p.size / 2,
                      child: Opacity(
                        opacity: p.life.clamp(0, 1),
                        child: Container(
                          width: p.size,
                          height: p.size,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: p.color.withOpacity(0.6), blurRadius: 6)],
                          ),
                        ),
                      ),
                    )),
                    
                    // Floating texts
                    ..._floatingTexts.map((f) => Positioned(
                      left: f.x - 25,
                      top: f.y,
                      child: Opacity(
                        opacity: f.life.clamp(0, 1),
                        child: Text(
                          f.text,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: f.color,
                            shadows: [Shadow(color: Colors.black87, blurRadius: 6), Shadow(color: f.color, blurRadius: 10)],
                          ),
                        ),
                      ),
                    )),
                    
                    // Shockwaves
                    ..._shockWaves.map((s) => Positioned(
                      left: s.x - s.radius,
                      top: s.y - s.radius,
                      child: Opacity(
                        opacity: s.opacity.clamp(0, 1),
                        child: Container(
                          width: s.radius * 2,
                          height: s.radius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: s.color.withOpacity(s.opacity), width: 4),
                            boxShadow: [BoxShadow(color: s.color.withOpacity(s.opacity * 0.5), blurRadius: 15)],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Bottom info panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  (isDark ? const Color(0xFF0A0F08) : const Color(0xFFF5F0E8)).withOpacity(0.98),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                // Seed collection mini display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _seeds.take(6).map((s) {
                    final count = _seedCollection[s.id] ?? 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [s.color.withOpacity(0.25), s.color.withOpacity(0.1)]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: s.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 2),
                          Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: s.color)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // Knowledge footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green.withOpacity(0.4), Colors.green.withOpacity(0.2)]),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🌱', style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${_level}: ${config.objective}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.green[300] : Colors.green[700]),
                            ),
                            Text(
                              _getLevelKnowledge(),
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black45),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Combo indicator
        if (_combo > 1)
          Positioned(
            top: 165,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange, Colors.red]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.6), blurRadius: 25, spreadRadius: 2),
                      ],
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text('${_combo}x COMBO!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        // Pause button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () => setState(() => _state = GameState.menu),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.black54, Colors.black38]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: const Icon(Icons.pause_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
        
        // Corner decorations
        Positioned(
          top: 150,
          left: 8,
          child: _cornerDecoration('🌾', isDark),
        ),
        Positioned(
          top: 150,
          right: 8,
          child: _cornerDecoration('🌻', isDark),
        ),
      ],
    );
  }
  
  Widget _cornerDecoration(String emoji, bool isDark) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, math.sin(_floatAnim.value * math.pi * 2) * 5),
        child: Opacity(
          opacity: 0.6,
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
  
  String _getGameTip() {
    final tips = [
      'Match 4+ seeds for special effects! ✨',
      'Native seeds need no chemicals to grow 🌿',
      'Avoid GMO tiles - they spread! ⚠️',
      'Build combos for bonus points 🔥',
      'India had 100,000+ rice varieties 🍚',
      'Millets need 70% less water than rice 💧',
      'Traditional seeds store for generations 🏛️',
      'Each seed saved preserves biodiversity 🌍',
    ];
    return tips[(_score + _level) % tips.length];
  }
  
  String _getLevelKnowledge() {
    final knowledge = [
      'Start your journey to save native seeds',
      'Traditional varieties are naturally pest-resistant',
      'Desi wheat has 30% more protein than hybrid',
      'Biodiversity ensures food security',
      'Heritage seeds carry 10,000 years of wisdom',
      'GMO seeds cannot be saved for next season',
      'Organic farming builds soil health naturally',
      'Village seed banks preserve local varieties',
      'Seed guardians protect our food heritage',
      'Every native seed is a genetic treasure',
      'Ancient wisdom meets modern conservation',
      'Crop diversity prevents famine',
      'Seed vaults protect against extinction',
      'Genetic diversity is nature\'s insurance',
      'Traditional seeds adapt to local climate',
      'Resistance to GMO preserves independence',
      'Desi crops need less water and fertilizer',
      'Seed warriors fight for food sovereignty',
      'Svalbard vault stores world\'s seed diversity',
      'Master preservers ensure future food security',
    ];
    return knowledge[(_level - 1).clamp(0, knowledge.length - 1)];
  }
  
  late Animation<double> _floatAnim;
  
  Widget _buildGameHUD(bool isDark) {
    final config = _levelConfigs[(_level - 1).clamp(0, _levelConfigs.length - 1)];
    final progress = (_score / _targetScore).clamp(0.0, 1.0);
    
    return Positioned(
      top: 10,
      left: 10,
      right: 60,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.4)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _hudChip('🎯', 'Level $_level', Colors.blue),
                _hudChip('⭐', '$_score', Colors.amber),
                _hudChip('🎲', '$_movesLeft moves', _movesLeft <= 5 ? Colors.red : Colors.white),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(config.objective, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                    Text('$_score / $_targetScore', style: TextStyle(fontSize: 11, color: progress >= 1 ? Colors.green : Colors.white70, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(color: Colors.white10),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: progress >= 1 
                                  ? [Colors.green, Colors.lightGreen]
                                  : [Colors.amber, Colors.orange],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _hudChip(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
  
  Widget _buildTile(_Tile tile, bool isDark) {
    final isSelected = _selectedTile?.x == tile.x && _selectedTile?.y == tile.y;
    final isInvasive = tile.type == TileType.invasive;
    
    final color = isInvasive ? _invasives[tile.seedIndex].color : _seeds[tile.seedIndex].color;
    final emoji = isInvasive ? _invasives[tile.seedIndex].emoji : _seeds[tile.seedIndex].emoji;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      left: tile.x * 50.0,
      top: tile.y * 50.0,
      child: GestureDetector(
        onTap: () => _selectTile(tile.x, tile.y),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: isInvasive
                ? [color.withOpacity(0.6), color.withOpacity(0.3)]
                : [color.withOpacity(0.5), color.withOpacity(0.2)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : color.withOpacity(0.5),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(color: color.withOpacity(isSelected ? 0.6 : 0.3), blurRadius: isSelected ? 15 : 8),
              if (isSelected) BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10),
              if (isInvasive) BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 12),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: isSelected ? 28 : 24,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LEVEL COMPLETE ====================
  Widget _buildLevelComplete(bool isDark) {
    final config = _levelConfigs[(_level - 1).clamp(0, _levelConfigs.length - 1)];
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Celebration header
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: 0.9 + _pulseAnim.value * 0.1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.green.withOpacity(0.3), Colors.transparent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎉', style: TextStyle(fontSize: 60)),
                ),
              ),
            ),
            
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: i < _stars ? 1.0 : 0.4),
                duration: Duration(milliseconds: 400 + i * 200),
                builder: (_, val, __) => Transform.scale(
                  scale: 0.5 + val * 0.5,
                  child: Opacity(
                    opacity: val,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        i < _stars ? '⭐' : '☆',
                        style: TextStyle(fontSize: 44, color: i < _stars ? null : Colors.grey.withOpacity(0.4)),
                      ),
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 12),
            
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39)]).createShader(bounds),
              child: Text('LEVEL $_level COMPLETE!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
            ),
            Text('"${config.objective}"', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black45)),
            const SizedBox(height: 20),
            
            // Stats card
            _buildPremiumCard([
              _buildStatRow('⭐', 'Score', '$_score', Colors.amber, isDark),
              _buildStatRow('🎯', 'Target', '$_targetScore', Colors.blue, isDark),
              _buildStatRow('🔥', 'Max Combo', '${_maxCombo}x', Colors.orange, isDark),
              _buildStatRow('🌱', 'Seeds Saved', '$_totalSeedsSaved', Colors.green, isDark),
              _buildStatRow('🎲', 'Moves Left', '+$_movesLeft bonus', Colors.teal, isDark),
            ], isDark),
            const SizedBox(height: 16),
            
            // Seed collection progress
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.brown.withOpacity(0.2), Colors.brown.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🌾', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Seeds Collected This Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _seeds.map((s) {
                      final count = _seedCollection[s.id] ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [s.color.withOpacity(0.3), s.color.withOpacity(0.1)]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: s.color.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.color)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Educational wisdom card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.withOpacity(0.25), Colors.teal.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green.withOpacity(0.4), Colors.green.withOpacity(0.2)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('📚', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SEED WISDOM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            Text('Knowledge unlocked!', style: TextStyle(fontSize: 10, color: Colors.green)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📖', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text('Lvl $_level', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.amber)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getEducationalTip(),
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Action buttons
            if (_level < 20)
              _buildPremiumButton('➡  Level ${_level + 1}', const Color(0xFF4CAF50), () => _startLevel(_level + 1), large: true),
            if (_level >= 20)
              _buildPremiumButton('🏆  You\'re a Master!', Colors.amber, () => setState(() => _state = GameState.menu), large: true),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildPremiumButton('🔄 Replay', Colors.orange, () => _startLevel(_level))),
                const SizedBox(width: 10),
                Expanded(child: _buildPremiumButton('🏠 Menu', Colors.blue, () => setState(() => _state = GameState.menu))),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getEducationalTip() {
    final tips = [
      'India once had over 100,000 rice varieties. Today, only 6,000 remain. Each variety was uniquely adapted to local conditions.',
      'Native seeds are adapted to local climate and need no chemical inputs. They have built-in resistance to local pests and diseases.',
      'Hybrid seeds cannot be replanted - farmers must buy new seeds each year. This creates dependency on seed companies.',
      'Millets were India\'s staple food for 5,000 years before rice and wheat. They require 70% less water than paddy rice.',
      'Black gram (Urad dal) contains 25g protein per 100g - more than eggs! It also enriches soil with nitrogen.',
      'Desi mustard oil has omega-3 fatty acids that refined oils lack. Cold-pressed oils retain all nutrients.',
      'Native wheat varieties have 30% more nutrients than modern hybrids. Khapli wheat is gluten-friendly for many.',
      'Traditional farming saved seeds for 10,000+ years of biodiversity. Community seed banks preserved local knowledge.',
      'The Svalbard Global Seed Vault stores 1.1+ million seed samples from every country as backup for global food security.',
      'A single desi cow\'s products can fertilize 30 acres of land naturally through Jeevamrut and Panchagavya.',
      'Red rice varieties contain anthocyanins - the same antioxidants found in blueberries, making them superfoods.',
      'Finger millet (Ragi) has 344mg calcium per 100g - 3x more than milk. It was the staple of South Indian empires.',
      'Native corn varieties have diverse colors - purple, red, blue - each with unique nutritional benefits.',
      'Traditional seed saving created thousands of varieties adapted to microclimates just kilometers apart.',
      'Beej Bachao Andolan (Save Seeds Movement) has conserved 700+ rice varieties in Uttarakhand alone.',
      'Green Revolution reduced crop diversity by 90%. We went from thousands of varieties to just a handful.',
    ];
    return tips[(_level + _score) % tips.length];
  }

  // ==================== GAME OVER ====================
  Widget _buildGameOver(bool isDark) {
    final neededMore = _targetScore - _score;
    final config = _levelConfigs[(_level - 1).clamp(0, _levelConfigs.length - 1)];
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Sad but hopeful icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Colors.orange.withOpacity(0.2), Colors.transparent]),
                  ),
                ),
                const Text('🌱', style: TextStyle(fontSize: 60)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('SEEDS NEED HELP!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text('Level $_level: "${config.objective}"', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black45, fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text('$neededMore more points needed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange)),
            ),
            const SizedBox(height: 20),
            
            _buildPremiumCard([
              _buildStatRow('⭐', 'Score', '$_score / $_targetScore', Colors.amber, isDark),
              _buildStatRow('🔥', 'Max Combo', '${_maxCombo}x', Colors.orange, isDark),
              _buildStatRow('🌱', 'Seeds This Round', '$_totalSeedsSaved', Colors.green, isDark),
            ], isDark),
            const SizedBox(height: 16),
            
            // Encouragement
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('💪', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('TIP FOR NEXT TRY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.green))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGameOverTip(),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Knowledge despite loss
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.brown.withOpacity(0.15), Colors.brown.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.brown.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('📚', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Even in defeat, you learned: ${_getShortFact()}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black45, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            _buildPremiumButton('🔄  Try Again', const Color(0xFF4CAF50), () => _startLevel(_level), large: true),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildPremiumButton('📊 Levels', Colors.blue, () => setState(() => _state = GameState.levels))),
                const SizedBox(width: 10),
                Expanded(child: _buildPremiumButton('🏠 Menu', Colors.grey, () => setState(() => _state = GameState.menu))),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getGameOverTip() {
    final tips = [
      'Look for L-shaped or T-shaped matches - they clear more seeds and give bonus points!',
      'Build combos by planning 2-3 moves ahead. Each combo multiplies your score.',
      'Match 4 seeds in a row to create shockwave effects that clear nearby tiles.',
      'Match 5+ seeds for massive chain reactions and bonus points.',
      'Focus on seeds clustered together - they\'re easier to match quickly.',
      'Watch out for GMO tiles (🧬) - they spread! Clear seeds around them first.',
    ];
    return tips[_rand.nextInt(tips.length)];
  }
  
  String _getShortFact() {
    final facts = [
      'Native seeds adapt to local climate naturally',
      'Traditional varieties need no chemical inputs',
      'Seed diversity is food security insurance',
      'Each variety lost is a unique genetic treasure',
      'Community seed banks preserve generations of wisdom',
    ];
    return facts[_rand.nextInt(facts.length)];
  }

  // ==================== LEVEL SELECT ====================
  Widget _buildLevelSelect(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () { _playSound('select'); setState(() => _state = GameState.menu); },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                      (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELECT LEVEL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text('$_level / 20 unlocked', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('$_highScore', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.amber)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Journey progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seed Guardian Journey', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _level / 20,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(Colors.green),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(_level / 20 * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.green)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: 20,
            itemBuilder: (_, i) {
              final lvl = i + 1;
              final unlocked = lvl <= _level;
              final config = _levelConfigs[i];
              final isCurrent = lvl == _level;
              
              // Difficulty tiers
              Color tierColor;
              String tierEmoji;
              if (lvl <= 5) { tierColor = Colors.green; tierEmoji = '🌱'; }
              else if (lvl <= 10) { tierColor = Colors.blue; tierEmoji = '🌿'; }
              else if (lvl <= 15) { tierColor = Colors.orange; tierEmoji = '🌾'; }
              else { tierColor = Colors.red; tierEmoji = '👑'; }
              
              return GestureDetector(
                onTap: unlocked ? () { _playSound('select'); _startLevel(lvl); } : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: unlocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [tierColor.withOpacity(isCurrent ? 0.4 : 0.25), tierColor.withOpacity(0.1)],
                        )
                      : LinearGradient(colors: [Colors.grey.withOpacity(0.15), Colors.grey.withOpacity(0.05)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent ? tierColor : (unlocked ? tierColor.withOpacity(0.4) : Colors.grey.withOpacity(0.2)),
                      width: isCurrent ? 2 : 1,
                    ),
                    boxShadow: isCurrent ? [BoxShadow(color: tierColor.withOpacity(0.3), blurRadius: 10)] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (unlocked) ...[
                        Text(tierEmoji, style: const TextStyle(fontSize: 14)),
                        Text(
                          '$lvl',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tierColor),
                        ),
                        Text('${config.targetScore}⭐', style: TextStyle(fontSize: 9, color: Colors.amber[600], fontWeight: FontWeight.w700)),
                      ] else ...[
                        const Text('🔒', style: TextStyle(fontSize: 24)),
                        Text('$lvl', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[500])),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Difficulty legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _difficultyLegend('🌱', 'Easy', Colors.green),
                _difficultyLegend('🌿', 'Medium', Colors.blue),
                _difficultyLegend('🌾', 'Hard', Colors.orange),
                _difficultyLegend('👑', 'Master', Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _difficultyLegend(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // ==================== COLLECTION ====================
  Widget _buildCollection(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () { _playSound('select'); setState(() => _state = GameState.menu); },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                      (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(child: Text('SEED BANK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('$_totalSeedsSaved', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Collection stats header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown.withOpacity(0.2), Colors.brown.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.brown.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.brown.withOpacity(0.4), Colors.brown.withOpacity(0.2)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🏛️', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Seed Vault', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Text(
                        'Every seed saved helps preserve biodiversity for future generations.',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _seeds.length,
            itemBuilder: (_, i) {
              final seed = _seeds[i];
              final count = _seedCollection[seed.id] ?? 0;
              final seedFacts = _getSeedDetailedFact(seed.id);
              
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + i * 100),
                builder: (_, val, child) => Transform.translate(
                  offset: Offset(30 * (1 - val), 0),
                  child: Opacity(opacity: val, child: child),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [seed.color.withOpacity(0.2), seed.color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: seed.color.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: seed.color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 65,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(colors: [seed.color.withOpacity(0.4), seed.color.withOpacity(0.1)]),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: seed.color.withOpacity(0.5), width: 2),
                                    boxShadow: [BoxShadow(color: seed.color.withOpacity(0.3), blurRadius: 10)],
                                  ),
                                  child: Center(child: Text(seed.emoji, style: const TextStyle(fontSize: 34))),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [seed.color, seed.color.withOpacity(0.8)]),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(seed.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('NATIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 0.5)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(seed.desc, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Detailed fact
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white).withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                seedFacts,
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54, fontStyle: FontStyle.italic, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Achievement hint
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.15), Colors.amber.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getCollectionMilestoneText(),
                    style: TextStyle(fontSize: 11, color: Colors.amber[700], fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  String _getSeedDetailedFact(String seedId) {
    final facts = {
      'wheat': 'Khapli (Emmer) wheat has 40% more protein than modern varieties. It\'s easier to digest and was grown in India for 8,000 years.',
      'rice': 'Mappillai Samba red rice was traditionally given to grooms for strength. It has low glycemic index, perfect for diabetics.',
      'corn': 'Native corn varieties contain zeaxanthin for eye health. They come in purple, red, black colors - each with unique benefits.',
      'millet': 'Finger millet (Ragi) has 3x more calcium than milk. It was the staple food of Vijayanagara empire\'s mighty warriors.',
      'lentil': 'Black gram fixes nitrogen in soil, naturally enriching it. It contains 25g protein per 100g - a complete plant protein.',
      'mustard': 'Cold-pressed desi mustard oil has natural preservatives. It was India\'s cooking oil for thousands of years before refined oils.',
    };
    return facts[seedId] ?? 'An ancient variety with unique genetic traits adapted to local conditions.';
  }
  
  String _getCollectionMilestoneText() {
    if (_totalSeedsSaved >= 1000) return 'Master Seed Saver! You\'ve preserved 1000+ seeds! 🎉';
    if (_totalSeedsSaved >= 500) return 'Biodiversity Champion! 500 seeds saved. Next: 1000 for Master status!';
    if (_totalSeedsSaved >= 100) return 'Growing collection! ${500 - _totalSeedsSaved} more seeds to Biodiversity Champion!';
    return 'Collect 100 seeds to unlock Seed Guardian achievement! Current: $_totalSeedsSaved';
  }

  // ==================== SHARED UI ====================
  Widget _buildPremiumCard(List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            (isDark ? Colors.white : Colors.black).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildStatRow(String emoji, String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.25), color.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton(String label, Color color, VoidCallback onTap, {bool large = false}) {
    return GestureDetector(
      onTap: () { _playSound('select'); onTap(); },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: large ? 36 : 20, vertical: large ? 20 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7), color.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(large ? 24 : 18),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: large ? 25 : 15, offset: Offset(0, large ? 10 : 6)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: large ? 20 : 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: large ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DATA CLASSES ====================
enum GameState { menu, playing, levelComplete, gameOver, collection, levels }
enum TileType { seed, invasive }

class _LevelConfig {
  final int level;
  final int targetScore;
  final int moves;
  final double invasiveChance;
  final String objective;
  final int seedsToSave;
  const _LevelConfig(this.level, this.targetScore, this.moves, this.invasiveChance, this.objective, this.seedsToSave);
}

class _SeedType {
  final String id, emoji, name, desc;
  final Color color;
  const _SeedType(this.id, this.emoji, this.color, this.name, this.desc);
}

class _InvasiveType {
  final String id, emoji, name, desc;
  final Color color;
  const _InvasiveType(this.id, this.emoji, this.color, this.name, this.desc);
}

class _Tile {
  int x, y;
  final TileType type;
  final int seedIndex;
  _Tile({required this.x, required this.y, required this.type, required this.seedIndex});
}

class _Particle {
  double x, y, vx, vy, life, size;
  final Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.life, this.size = 6});
}

class _FloatingText {
  final String text;
  double x, y, life;
  final Color color;
  _FloatingText({required this.text, required this.x, required this.y, required this.color, required this.life});
}

class _ShockWave {
  double x, y, radius, opacity;
  final Color color;
  _ShockWave({required this.x, required this.y, required this.radius, required this.opacity, required this.color});
}

// ==================== CUSTOM PAINTER ====================
class _FarmBackgroundPainter extends CustomPainter {
  final double offset;
  final bool isDark;
  _FarmBackgroundPainter({required this.offset, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);
    
    // Floating seeds
    for (int i = 0; i < 20; i++) {
      final x = ((rand.nextDouble() + offset * 0.5) % 1.0) * size.width;
      final y = rand.nextDouble() * size.height;
      final seedSize = rand.nextDouble() * 15 + 8;
      
      paint.color = (isDark ? Colors.green : Colors.brown).withOpacity(rand.nextDouble() * 0.08 + 0.02);
      canvas.drawCircle(Offset(x, y), seedSize, paint);
    }
    
    // Plant stems
    paint
      ..color = (isDark ? Colors.green.withOpacity(0.08) : Colors.green.withOpacity(0.06))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 8; i++) {
      final path = Path();
      final startX = ((rand.nextDouble() + offset * 0.3) % 1.0) * size.width;
      path.moveTo(startX, size.height);
      
      double x = startX, y = size.height;
      for (int j = 0; j < 5; j++) {
        x += (rand.nextDouble() - 0.5) * 40;
        y -= rand.nextDouble() * 80 + 40;
        path.quadraticBezierTo(
          x + (rand.nextDouble() - 0.5) * 30,
          y + 30,
          x.clamp(0, size.width),
          y.clamp(0, size.height),
        );
      }
      canvas.drawPath(path, paint);
      
      // Leaf at top
      paint.style = PaintingStyle.fill;
      paint.color = Colors.green.withOpacity(isDark ? 0.1 : 0.08);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 20, height: 12), paint);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _FarmBackgroundPainter old) => old.offset != offset;
}

