import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cow → Soil Cycle - Ultimate Challenge Edition
/// Fast-paced, educational, beautiful
class CowToSoilCycleGameScreen extends StatefulWidget {
  const CowToSoilCycleGameScreen({super.key});
  @override
  State<CowToSoilCycleGameScreen> createState() => _GameState();
}

class _GameState extends State<CowToSoilCycleGameScreen> with TickerProviderStateMixin {
  // Core game state
  GamePhase _phase = GamePhase.menu;
  int _level = 1, _score = 0, _combo = 0, _maxCombo = 0, _lives = 3;
  double _progress = 0.0;
  bool _paused = false;
  Timer? _timer;
  final _rand = math.Random();
  
  // Animations - Enhanced with more controllers
  late AnimationController _pulseCtrl, _shakeCtrl, _glowCtrl;
  late AnimationController _floatCtrl, _rotateCtrl, _shimmerCtrl, _breatheCtrl;
  late Animation<double> _pulse, _shake, _glow;
  late Animation<double> _float, _rotate, _shimmer, _breathe;
  
  // Particles for visual effects
  List<_Particle> _particles = [];
  List<_Sparkle> _sparkles = [];
  
  // Phase 1: Feeding
  List<_FodderItem> _fodder = [];
  int _happiness = 50, _taps = 0;
  
  // Phase 2: Collection
  double _bucketX = 0.5;
  List<_Drop> _drops = [];
  int _collected = 0, _collectTarget = 12;
  
  // Phase 3: Mixing
  double _dung = 0, _urine = 0, _jaggery = 0, _water = 0, _ferment = 0;
  bool _fermenting = false;
  
  // Phase 4: Grid
  List<List<_Cell>> _grid = [];
  int _nutrients = 0, _nutrientTarget = 8;
  
  // Phase 5: Defense (FAST - 25 seconds)
  List<_Pest> _pests = [];
  List<_Defender> _defenders = [];
  double _cropHP = 100;
  int _defenseTimer = 25;
  
  // Enhanced educational content with comprehensive traditional knowledge
  static const _phaseEducation = {
    GamePhase.phase1_feeding: {
      'title': '🐄 Why Desi Cow?',
      'knowledge': '🐄 DESI COW - MOTHER OF AGRICULTURE\n\n🌱 Sacred Significance:\n• "Gaavo Vishwasya Matarah" - Cows are mothers of the world\n• 33 crore deities reside in the cow\n• Kamadhenu - wish-fulfilling divine cow\n• Symbol of prosperity and non-violence\n\n🥛 A2 Milk Superiority:\n• Contains A2 beta-casein protein (easier to digest)\n• Rich in Omega-3 fatty acids\n• Higher levels of vitamins and minerals\n• No BCM-7 (associated with health issues)\n\n🌍 Environmental Benefits:\n• One desi cow fertilizes 30 acres naturally\n• Produces 300+ beneficial microbe species\n• Methane emissions 40% lower than crossbreeds\n• Carbon-negative farming partner\n\n🏥 Medicinal Properties:\n• Panchagavya - 5 cow products used in Ayurveda\n• Cow urine has antimicrobial properties\n• Ghee improves brain function and immunity\n• Dung ash treats skin diseases\n\n💰 Economic Value:\n• Lifetime returns: 10x investment cost\n• Multiple income streams: milk, dung, urine, calves\n• Low maintenance compared to crossbreeds\n• Indigenous breeds adapted to local climate',
      'points': [
        'Desi cow breeds (Gir, Sahiwal, Red Sindhi) have A2 milk protein',
        'Their dung contains 300+ beneficial microbe species',
        'One cow can fertilize 30 acres naturally',
        'Desi cows are heat-tolerant and disease-resistant',
      ],
      'message': 'Healthy cow = Healthy farm ecosystem!',
      'breeds': [
        {'name': 'Gir', 'origin': 'Gujarat', 'milk': '12-15L/day', 'special': 'Drought resistant'},
        {'name': 'Sahiwal', 'origin': 'Punjab', 'milk': '8-10L/day', 'special': 'Heat tolerant'},
        {'name': 'Red Sindhi', 'origin': 'Sindh', 'milk': '6-8L/day', 'special': 'Disease resistant'},
        {'name': 'Tharparkar', 'origin': 'Rajasthan', 'milk': '5-7L/day', 'special': 'Survives in desert'},
      ],
    },
    GamePhase.phase2_collection: {
      'title': '🪣 The Golden Inputs',
      'knowledge': '🪣 COW PRODUCTS - LIQUID GOLD\n\n💩 Cow Dung Properties:\n• NPK Ratio: 3:2:1 (balanced nutrition)\n• Contains 70% organic matter\n• Rich in beneficial bacteria and fungi\n• Natural pesticide and fungicide\n• Improves soil structure and water retention\n• pH neutralizer for acidic soils\n\n💧 Cow Urine Benefits:\n• Contains growth hormones (auxins, gibberellins)\n• Natural pest repellent (contains 8 volatile compounds)\n• Urea content: 2.5% (natural nitrogen source)\n• Antimicrobial properties (kills pathogens)\n• Enhances seed germination by 40%\n• Shelf life: 6 months (no preservatives needed)\n\n🔬 Scientific Validation:\n• IIT Delhi research: 1L urine = 10g urea fertilizer\n• ICAR studies: 20% higher crop yields with cow products\n• NASA research: Cow dung biogas for space stations\n• WHO recognizes traditional cow-based farming\n\n💎 Economic Value:\n• Daily production: 15-20kg dung, 8-12L urine\n• Market value: ₹2-3/kg dung, ₹5-8/L urine\n• Processing value: Jeevamrut sells for ₹50/L\n• Vermicomposting: 3x faster with cow dung',
      'points': [
        'Cow dung is rich in nitrogen, phosphorus & potassium',
        'Cow urine has natural growth hormones & pest repellents',
        'Fresh inputs have maximum microbial activity',
        'Never mix with chemicals - kills beneficial microbes',
      ],
      'message': 'These "waste" products are farming gold!',
    },
    GamePhase.phase3_mixing: {
      'title': '🧫 Jeevamrut - The Life Potion',
      'knowledge': '🧫 JEEVAMRUT - NECTAR OF LIFE\n\n📜 Traditional Recipe:\n• 10kg fresh cow dung + 10L cow urine\n• 2kg jaggery + 2kg gram flour (besan)\n• 200L water + 1 handful forest soil\n• Ferment for 48 hours in shade\n• Stir clockwise twice daily (morning & evening)\n\n🦠 Microbial Magic:\n• 1 billion beneficial bacteria per mL\n• 5 types of nitrogen-fixing bacteria\n• 3 types of phosphate-solubilizing bacteria\n• 2 types of potash-mobilizing bacteria\n• 8 types of decomposing fungi\n\n🌱 Application Guidelines:\n• Dosage: 200L per acre every 15 days\n• Dilution: 1:10 with water before application\n• Best time: Early morning or evening\n• Method: Foliar spray or soil drenching\n• Storage: Use within 7 days of preparation\n\n📊 Proven Results:\n• 30% reduction in chemical fertilizer use\n• 25% increase in crop yields\n• 40% improvement in soil organic carbon\n• 50% reduction in pest infestation\n• 60% water requirement reduction\n\n🏆 Success Stories:\n• Maharashtra farmer: 20% higher sugarcane yield\n• Karnataka farmer: Zero pesticide cost for 3 years\n• Punjab farmer: Soil health index improved from 45 to 85\n• Organic certification achieved in 2 years',
      'points': [
        '10kg dung + 10L urine + 2kg jaggery + 2kg besan + 200L water',
        'Ferment for 48 hours in shade, stir twice daily',
        'Contains billions of soil-friendly bacteria',
        'Apply 200L per acre every 15 days',
      ],
      'message': 'Jeevamrut means "nectar of life" for soil!',
    },
    GamePhase.phase4_application: {
      'title': '🌱 Living Soil Science',
      'knowledge': '🌱 LIVING SOIL - EARTH\'S SKIN\n\n🔬 Soil Microbiology:\n• 1 billion bacteria per teaspoon of healthy soil\n• 10,000 species of microbes in 1 gram soil\n• Mycorrhizal fungi extend root reach by 100x\n• Earthworms process 10 tons soil/acre yearly\n• 60% of soil life is microscopic\n\n🌿 Plant-Microbe Relationships:\n• Roots release sugars (exudates) to feed microbes\n• Bacteria convert atmospheric N2 to plant-available N\n• Fungi transport nutrients and water to roots\n• Actinomycetes decompose complex organic matter\n• Protozoa regulate bacterial populations\n\n💧 Soil Structure:\n• Soil aggregates: 0.25-10mm clumps held by glue\n• Porosity: 25% air, 25% water, 50% solids\n• Organic matter: 5% ideal for Indian soils\n• pH: 6.5-7.5 optimal for most crops\n• CEC (Cation Exchange Capacity): 15-25 meq/100g\n\n🌍 Carbon Sequestration:\n• 1% increase in soil organic carbon = 50 tons CO2/acre\n• Healthy soil stores 3x more carbon than atmosphere\n• No-till farming increases carbon by 1%/year\n• Cover crops prevent carbon loss by 70%\n• Compost adds stable carbon for 50+ years\n\n📊 Soil Health Indicators:\n• Earthworm count: 15-20 per sq ft (healthy)\n• Respiration rate: 20-40 mg CO2/kg soil/day\n• Infiltration rate: 2-5 inches/hour\n• Aggregate stability: 60-80% water-stable aggregates\n• Microbial biomass: 500-1000 µg C/g soil',
      'points': [
        'Healthy soil has 1 billion bacteria per teaspoon',
        'Roots release sugars to attract beneficial microbes',
        'Mycorrhizal fungi extend root reach by 100x',
        'Earthworms process 10 tons of soil per acre yearly',
      ],
      'message': 'Feed the soil, not the plant!',
    },
    GamePhase.phase5_defense: {
      'title': '🛡️ Nature\'s Army',
      'knowledge': '🛡️ BIOLOGICAL PEST CONTROL\n\n🐛 Beneficial Insects:\n• Ladybugs: Eat 5,000 aphids in lifetime\n• Lacewings: Consume 600 aphids/week\n• Dragonflies: Eat 100 mosquitoes/day\n• Praying mantis: Eat various pests continuously\n• Parasitic wasps: Lay eggs in pest larvae\n\n🕷️ Natural Predators:\n• Spiders: Catch 400-800 million insects/year globally\n• Frogs: Eat body weight in insects daily\n• Lizards: Control 50-100 insects/day\n• Birds: One family eats 6,000 insects/season\n• Bats: Consume 1,200 mosquitoes/hour\n\n🌿 Plant Defense Mechanisms:\n• Companion planting: Marigold repels nematodes\n• Trap crops: Mustard attracts flea beetles\n• Repellent plants: Neem drives away 200+ pests\n• Insectary plants: Sunflower feeds beneficial insects\n• Push-pull strategy: Desmodium + Napier grass\n\n🧪 Natural Pesticides:\n• Neem oil: Affects 200+ insect species\n• Garlic extract: Repels aphids and spider mites\n• Chili spray: Deters larger pests\n• Tobacco solution: Kills soft-bodied insects\n• Cow urine: Natural pest repellent\n\n📊 Integrated Pest Management:\n• 80% pest reduction with beneficial insects\n• 90% cost reduction vs chemical pesticides\n• 100% safe for humans and environment\n• Improves crop quality and shelf life\n• Increases biodiversity on farm\n\n🏆 Success Metrics:\n• Tamil Nadu farmer: Zero pesticide cost, 30% higher yield\n• Kerala farmer: Export quality spices with natural farming\n• Andhra farmer: 2x income with organic certification',
      'points': [
        'Ladybugs eat 5,000 aphids in lifetime',
        'Spiders catch 400-800 million tons of insects yearly',
        'Frogs consume their body weight in bugs daily',
        'Beneficial insects need chemical-free farms to thrive',
      ],
      'message': 'Biodiversity is the best pest control!',
    },
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  void _initAnimations() {
    // Pulse effect (800ms)
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    
    // Shake effect (80ms)
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _shake = Tween<double>(begin: -8, end: 8).animate(_shakeCtrl);
    
    // Glow effect (1500ms)
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    
    // Floating animation (4 seconds)
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _float = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    
    // Rotation for decorative elements (10 seconds)
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateCtrl);
    
    // Shimmer effect (2.5 seconds)
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerCtrl);
    
    // Breathing effect for UI elements (3 seconds)
    _breatheCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _breathe = Tween<double>(begin: 0.98, end: 1.02).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _shimmerCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  void _playSound(String type) {
    switch (type) {
      case 'tap': HapticFeedback.lightImpact(); break;
      case 'success': HapticFeedback.mediumImpact(); SystemSound.play(SystemSoundType.click); break;
      case 'fail': HapticFeedback.heavyImpact(); break;
      case 'win': HapticFeedback.heavyImpact(); SystemSound.play(SystemSoundType.click); break;
      case 'collect': HapticFeedback.selectionClick(); break;
    }
  }

  void _shake_() {
    _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
  }

  void _loseLife() {
    _playSound('fail');
    _shake_();
    setState(() { _lives--; _combo = 0; });
    if (_lives <= 0) _gameOver();
  }

  void _addScore(int pts) {
    _playSound('collect');
    setState(() {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      _score += (pts * (1 + _combo * 0.15)).round();
    });
  }

  void _gameOver() {
    _timer?.cancel();
    _playSound('fail');
    setState(() => _phase = GamePhase.gameOver);
  }

  void _startGame() {
    _playSound('success');
    setState(() {
      _phase = GamePhase.phase1_feeding;
      _level = 1; _score = 0; _combo = 0; _maxCombo = 0; _lives = 3;
    });
    _startPhase1();
  }

  void _showPhaseComplete() {
    _timer?.cancel();
    final edu = _phaseEducation[_phase]!;
    _playSound('win');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF1A1F2E), const Color(0xFF0D1117)]
                : [Colors.white, const Color(0xFFF0F7FF)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, -10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(99))),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Success header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 25, offset: const Offset(0, 8))],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text('Phase Complete! 🎉', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 24),
                      
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statBubble('⭐', '$_score', 'Score', Colors.amber),
                          _statBubble('🔥', '${_combo}x', 'Combo', Colors.orange),
                          _statBubble('❤️', '$_lives', 'Lives', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 28),
                      
                      // Educational content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.withOpacity(isDark ? 0.25 : 0.12),
                              Colors.teal.withOpacity(isDark ? 0.15 : 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.school_rounded, color: Colors.green, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(edu['title'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...(edu['points'] as List<String>).map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(p, style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black54))),
                                ],
                              ),
                            )),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(isDark ? 0.2 : 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.amber.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Text('💡', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(edu['message'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.amber.shade700))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Continue button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _nextPhase();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Continue to Next Phase', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statBubble(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4), width: 2),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
      ],
    );
  }

  void _nextPhase() {
    _playSound('success');
    switch (_phase) {
      case GamePhase.phase1_feeding: setState(() => _phase = GamePhase.phase2_collection); _startPhase2(); break;
      case GamePhase.phase2_collection: setState(() => _phase = GamePhase.phase3_mixing); _startPhase3(); break;
      case GamePhase.phase3_mixing: setState(() => _phase = GamePhase.phase4_application); _startPhase4(); break;
      case GamePhase.phase4_application: setState(() => _phase = GamePhase.phase5_defense); _startPhase5(); break;
      case GamePhase.phase5_defense: _levelComplete(); break;
      default: break;
    }
  }

  void _levelComplete() {
    _timer?.cancel();
    _playSound('win');
    setState(() => _phase = GamePhase.levelComplete);
  }

  void _nextLevel() {
    _playSound('success');
    setState(() { _level++; _lives = math.min(_lives + 1, 5); _phase = GamePhase.phase1_feeding; });
    _startPhase1();
  }

  // ========== PHASE 1: FEEDING (15 taps) ==========
  void _startPhase1() {
    _fodder = []; _happiness = 50; _taps = 0; _progress = 0;
    final target = 12 + (_level * 2);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (_paused || !mounted) return;
      if (_fodder.length < 5 + _level) {
        final good = _rand.nextDouble() > (0.2 + _level * 0.02);
        _fodder.add(_FodderItem(
          id: DateTime.now().millisecondsSinceEpoch,
          x: _rand.nextDouble() * 0.75 + 0.1,
          y: _rand.nextDouble() * 0.45 + 0.15,
          good: good,
          emoji: good ? ['🌾', '🥕', '🌿', '🍀'][_rand.nextInt(4)] : ['☠️', '🧪', '💀'][_rand.nextInt(3)],
          ttl: 2.5,
        ));
      }
      setState(() {
        _fodder = _fodder.where((f) { f.ttl -= 0.06; return f.ttl > 0; }).toList();
        _progress = _taps / target;
        _happiness = (_happiness - 0.4).clamp(0, 100).toInt();
      });
      if (_taps >= target && _happiness >= 35) _showPhaseComplete();
      if (_happiness <= 0) { _loseLife(); _happiness = 25; }
    });
  }

  void _tapFodder(_FodderItem f) {
    _playSound('tap');
    setState(() {
      _fodder.removeWhere((x) => x.id == f.id);
      if (f.good) { _taps++; _happiness = (_happiness + 10).clamp(0, 100).toInt(); _addScore(15); }
      else { _happiness = (_happiness - 25).clamp(0, 100).toInt(); _combo = 0; _shake_(); }
    });
  }

  // ========== PHASE 2: COLLECTION (12 catches) ==========
  void _startPhase2() {
    _bucketX = 0.5; _drops = []; _collected = 0; _collectTarget = 10 + _level * 2; _progress = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      if (_paused || !mounted) return;
      if (_rand.nextDouble() < 0.12 + _level * 0.015) {
        final good = _rand.nextDouble() > 0.18;
        _drops.add(_Drop(
          id: DateTime.now().millisecondsSinceEpoch,
          x: _rand.nextDouble() * 0.8 + 0.1,
          y: 0, speed: 0.012 + _level * 0.002,
          good: good,
          emoji: good ? ['💧', '🟤', '🟡'][_rand.nextInt(3)] : '☠️',
        ));
      }
      setState(() {
        for (var d in _drops) d.y += d.speed;
        final bL = _bucketX - 0.1, bR = _bucketX + 0.1;
        _drops = _drops.where((d) {
          if (d.y > 0.82) {
            if (d.x >= bL && d.x <= bR) {
              if (d.good) { _collected++; _addScore(20); } else _loseLife();
            } else if (d.good) _combo = 0;
            return false;
          }
          return d.y < 1;
        }).toList();
        _progress = _collected / _collectTarget;
      });
      if (_collected >= _collectTarget) _showPhaseComplete();
    });
  }

  // ========== PHASE 3: MIXING ==========
  void _startPhase3() {
    _dung = 0; _urine = 0; _jaggery = 0; _water = 0; _ferment = 0; _fermenting = false; _progress = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (_paused || !mounted) return;
      setState(() {
        if (_fermenting) {
          _ferment += 0.015 + _level * 0.003;
          _progress = _ferment;
        }
      });
      if (_ferment >= 1) {
        final ok = (_dung - 0.30).abs() < 0.12 && (_urine - 0.20).abs() < 0.10 &&
                   (_jaggery - 0.15).abs() < 0.08 && (_water - 0.35).abs() < 0.12;
        if (ok) { _addScore(120); _showPhaseComplete(); }
        else { _loseLife(); _ferment = 0; _fermenting = false; }
      }
    });
  }

  void _setIngredient(String type, double v) {
    if (_fermenting) return;
    _playSound('tap');
    setState(() {
      switch (type) {
        case 'd': _dung = v; break;
        case 'u': _urine = v; break;
        case 'j': _jaggery = v; break;
        case 'w': _water = v; break;
      }
      final total = _dung + _urine + _jaggery + _water;
      if (total > 1) { final f = 1 / total; _dung *= f; _urine *= f; _jaggery *= f; _water *= f; }
    });
  }

  void _startFerment() {
    if (_fermenting) return;
    final total = _dung + _urine + _jaggery + _water;
    if (total < 0.85) { _playSound('fail'); return; }
    _playSound('success');
    setState(() => _fermenting = true);
  }

  // ========== PHASE 4: GRID ==========
  void _startPhase4() {
    _grid = List.generate(5, (y) => List.generate(5, (x) => _Cell(x, y)));
    _nutrients = 0; _nutrientTarget = 6 + _level; _progress = 0;
    _grid[4][2].root = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (_paused || !mounted) return;
      setState(() {
        _progress = _nutrients / _nutrientTarget;
        // Grow roots toward nutrients
        for (int y = 0; y < 5; y++) {
          for (int x = 0; x < 5; x++) {
            if (_grid[y][x].root) {
              for (var d in [[-1,0],[1,0],[0,-1],[0,1]]) {
                final nx = x + d[0], ny = y + d[1];
                if (nx >= 0 && nx < 5 && ny >= 0 && ny < 5) {
                  if (_grid[ny][nx].nutrient && !_grid[ny][nx].root && _rand.nextDouble() < 0.08) {
                    _grid[ny][nx].root = true;
                    _grid[ny][nx].nutrient = false;
                    _addScore(25);
                  }
                }
              }
            }
          }
        }
      });
      if (_nutrients >= _nutrientTarget) _showPhaseComplete();
    });
  }

  void _placeNutrient(int x, int y) {
    if (_grid[y][x].nutrient || _grid[y][x].root) return;
    _playSound('tap');
    setState(() { _grid[y][x].nutrient = true; _nutrients++; });
  }

  // ========== PHASE 5: DEFENSE (FAST - 25 seconds!) ==========
  void _startPhase5() {
    _pests = []; _defenders = []; _cropHP = 100; _defenseTimer = 25; _progress = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (_paused || !mounted) return;
      
      // Spawn pests FREQUENTLY for action
      if (_rand.nextDouble() < 0.08 + _level * 0.01) {
        _pests.add(_Pest(
          id: DateTime.now().millisecondsSinceEpoch,
          x: _rand.nextBool() ? -0.05 : 1.05,
          y: 0.25 + _rand.nextDouble() * 0.5,
          speed: 0.008 + _level * 0.002,
          emoji: ['🐛', '🦗', '🐜', '🪲'][_rand.nextInt(4)],
          hp: 1 + (_level ~/ 2),
        ));
      }
      
      setState(() {
        // Move pests toward center FAST
        for (var p in _pests) {
          p.x += (0.5 - p.x).sign * p.speed * 1.5;
        }
        
        // Defenders attack nearby pests
        for (var d in _defenders) {
          _Pest? target;
          double minDist = 0.2;
          for (var p in _pests) {
            final dist = (p.x - d.x).abs() + (p.y - d.y).abs();
            if (dist < minDist) { minDist = dist; target = p; }
          }
          if (target != null) {
            target.hp--;
            if (target.hp <= 0) {
              _pests.remove(target);
              _addScore(30);
            }
          } else {
            // Move toward nearest pest
            _Pest? nearest;
            double nearestDist = double.infinity;
            for (var p in _pests) {
              final dist = (p.x - d.x).abs() + (p.y - d.y).abs();
              if (dist < nearestDist) { nearestDist = dist; nearest = p; }
            }
            if (nearest != null) {
              d.x += (nearest.x - d.x).sign * 0.015;
              d.y += (nearest.y - d.y).sign * 0.015;
            }
          }
        }
        
        // Damage crops if pests reach center
        for (var p in _pests) {
          if ((p.x - 0.5).abs() < 0.12) {
            _cropHP -= 1.2;
            _combo = 0;
          }
        }
        
        // Timer countdown
        if (t.tick % 20 == 0 && _defenseTimer > 0) _defenseTimer--;
        _progress = 1 - (_defenseTimer / 25);
      });
      
      if (_cropHP <= 0) { _loseLife(); _cropHP = 50; }
      if (_defenseTimer <= 0 && _cropHP > 20) _showPhaseComplete();
    });
  }

  void _deployDefender(double x, double y) {
    if (_defenders.length >= 4 + _level) return;
    _playSound('success');
    setState(() {
      _defenders.add(_Defender(
        id: DateTime.now().millisecondsSinceEpoch,
        x: x, y: y,
        emoji: ['🐞', '🦎', '🕷️', '🐸'][_rand.nextInt(4)],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1C) : const Color(0xFFF0F7FF),
      body: AnimatedBuilder(
        animation: _shake,
        builder: (_, child) => Transform.translate(offset: Offset(_shake.value, 0), child: child),
        child: Stack(
          children: [
            _buildBg(isDark),
            SafeArea(
              child: Column(
                children: [
                  if (_phase != GamePhase.menu && _phase != GamePhase.gameOver && _phase != GamePhase.levelComplete) _buildHeader(isDark),
                  Expanded(child: _buildPhase(isDark, size)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBg(bool isDark) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: isDark
              ? [Color.lerp(const Color(0xFF1A2F1A), const Color(0xFF0F1A0F), _glow.value)!, const Color(0xFF0A0F1C)]
              : [Color.lerp(const Color(0xFFE8F5E8), const Color(0xFFF0F7FF), _glow.value)!, const Color(0xFFF0F7FF)],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () { _playSound('tap'); setState(() => _paused = !_paused); },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.orange, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_getPhaseTitle(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
              ),
              _miniStat('⭐', '$_score', Colors.amber),
              const SizedBox(width: 6),
              _miniStat('🔥', '${_combo}x', Colors.deepOrange),
              const SizedBox(width: 6),
              _miniStat('❤️', '$_lives', Colors.red),
              const SizedBox(width: 6),
              _miniStat('🎯', 'L$_level', Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress.clamp(0, 1),
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(_getPhaseColor()),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String e, String v, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: c)),
        ],
      ),
    );
  }

  String _getPhaseTitle() => switch (_phase) {
    GamePhase.phase1_feeding => '🐄 Phase 1: Feed the Cow',
    GamePhase.phase2_collection => '🪣 Phase 2: Collect Inputs',
    GamePhase.phase3_mixing => '🧫 Phase 3: Mix Jeevamrut',
    GamePhase.phase4_application => '🌱 Phase 4: Nourish Soil',
    GamePhase.phase5_defense => '🛡️ Phase 5: Defend! (${_defenseTimer}s)',
    _ => 'Cow → Soil Cycle',
  };

  Color _getPhaseColor() => switch (_phase) {
    GamePhase.phase1_feeding => Colors.blue,
    GamePhase.phase2_collection => Colors.green,
    GamePhase.phase3_mixing => Colors.purple,
    GamePhase.phase4_application => Colors.brown,
    GamePhase.phase5_defense => Colors.red,
    _ => Colors.green,
  };

  Widget _buildPhase(bool isDark, Size size) => switch (_phase) {
    GamePhase.menu => _menuUI(isDark),
    GamePhase.phase1_feeding => _phase1UI(isDark, size),
    GamePhase.phase2_collection => _phase2UI(isDark, size),
    GamePhase.phase3_mixing => _phase3UI(isDark),
    GamePhase.phase4_application => _phase4UI(isDark),
    GamePhase.phase5_defense => _phase5UI(isDark, size),
    GamePhase.gameOver => _gameOverUI(isDark),
    GamePhase.levelComplete => _levelCompleteUI(isDark),
  };

  // ========== PROFESSIONAL MENU UI ==========
  Widget _menuUI(bool isDark) {
    final primaryColor = const Color(0xFF2E7D32); // Forest green
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtleColor = isDark ? Colors.white60 : Colors.black54;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Keep the animated logo
          _buildEnhancedLogo(isDark),
          const SizedBox(height: 28),
          
          // Clean title
          Text(
            'Cow to Soil Cycle',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Natural Farming Through Play',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: subtleColor,
            ),
          ),
          const SizedBox(height: 32),
          
          // Clean phase cards
          _buildCleanPhaseSection(isDark, primaryColor, textColor, subtleColor),
          const SizedBox(height: 24),
          
          // Simple description
          _buildCleanDescription(isDark, primaryColor, textColor, subtleColor),
          const SizedBox(height: 32),
          
          // Clean play button
          _buildCleanPlayButton(primaryColor),
          const SizedBox(height: 16),
          
          // Clean knowledge section
          _buildCleanKnowledgeSection(isDark, primaryColor, textColor, subtleColor),
          const SizedBox(height: 16),
          
          // Simple back button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '← Back to Games',
              style: TextStyle(
                color: subtleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildCleanPhaseSection(bool isDark, Color primary, Color textColor, Color subtleColor) {
    final phases = [
      {'emoji': '🐄', 'name': 'Feed', 'desc': 'Nourish cow'},
      {'emoji': '🪣', 'name': 'Collect', 'desc': 'Gather inputs'},
      {'emoji': '🧫', 'name': 'Mix', 'desc': 'Make Jeevamrut'},
      {'emoji': '🌱', 'name': 'Apply', 'desc': 'Enrich soil'},
      {'emoji': '🛡️', 'name': 'Defend', 'desc': 'Protect crops'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The 5 Phases',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: phases.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return Container(
                width: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : primary.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(phases[i]['emoji']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      phases[i]['name']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      phases[i]['desc']!,
                      style: TextStyle(fontSize: 9, color: subtleColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCleanDescription(bool isDark, Color primary, Color textColor, Color subtleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Learn Natural Farming',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Experience the complete cow-to-soil cycle through 5 interactive phases. Discover ancient farming wisdom while playing!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: subtleColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSimpleFeature('🐄', '5 Phases', subtleColor),
              _buildSimpleFeature('🌱', 'Organic', subtleColor),
              _buildSimpleFeature('📚', 'Educational', subtleColor),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleFeature(String emoji, String text, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
  
  Widget _buildCleanPlayButton(Color primary) {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Start Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCleanKnowledgeSection(bool isDark, Color primary, Color textColor, Color subtleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Did You Know?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🐄 Desi cows produce A2 milk which is easier to digest and contains beta-casein protein that\'s beneficial for health.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: subtleColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '🌱 Jeevamrut made from cow products contains 9 times more beneficial microorganisms than chemical fertilizers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: subtleColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showKnowledgeModal(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Learn More',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: primary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showKnowledgeModal(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        title: Text(
          'Natural Farming Wisdom',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKnowledgeItem('🐄 Desi Cow Breeds', 'Gir, Sahiwal, Tharparkar - native breeds perfectly adapted to Indian climate and produce nutrient-rich A2 milk.'),
              const SizedBox(height: 12),
              _buildKnowledgeItem('🧪 Jeevamrut Formula', 'Cow dung + urine + jaggery + pulse flour + water = Natural fertilizer with 9x more microbes than chemicals.'),
              const SizedBox(height: 12),
              _buildKnowledgeItem('🌍 Soil Health', 'One cow can enrich 1 acre of land naturally, reducing need for chemical fertilizers by 80%.'),
              const SizedBox(height: 12),
              _buildKnowledgeItem('🌾 Crop Protection', 'Natural pesticides from cow products protect crops without harming beneficial insects or soil life.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildKnowledgeItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.4,
          ),
        ),
      ],
    );
  }
  
  // Enhanced animated logo with multiple effects
  Widget _buildEnhancedLogo(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _rotate, _glow, _float]),
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Outer glow effect only - no container background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (_, __) => DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(_glow.value * 0.4),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Rotating glow ring - no solid background
              AnimatedBuilder(
                animation: _rotate,
                builder: (_, __) => Transform.rotate(
                  angle: _rotate.value * 0.3,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                        BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 15, spreadRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
              // Inner circle with cow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🐄', style: TextStyle(fontSize: 40)),
                      Text('गौ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              // Floating phase icons - glow only, no solid background
              ...List.generate(5, (i) {
                final angle = (i / 5) * math.pi * 2 - math.pi / 2;
                final floatOffset = math.sin(_float.value * math.pi * 2 + i) * 5;
                final phaseIcons = ['🐄', '🪣', '🧫', '🌱', '🛡️'];
                final phaseColors = [Colors.blue, Colors.green, Colors.purple, Colors.brown, Colors.red];
                return Positioned(
                  left: 90 + math.cos(angle) * 75 - 18 + floatOffset,
                  top: 90 + math.sin(angle) * 75 - 18 + floatOffset,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: phaseColors[i].withOpacity(0.6), blurRadius: 15, spreadRadius: 3),
                      ],
                    ),
                    child: Center(child: Text(phaseIcons[i], style: const TextStyle(fontSize: 18))),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
  
  // Enhanced title with shimmer effect
  Widget _buildEnhancedTitle(bool isDark) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shimmer,
          builder: (_, __) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.green.withOpacity(0.8),
                Colors.blue.withOpacity(_shimmer.value.clamp(0, 1)),
                Colors.purple.withOpacity(0.8),
              ],
            ).createShader(bounds),
            child: const Text(
              '🐄 Cow → Soil Cycle',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _breathe,
          builder: (_, __) => Transform.scale(
            scale: _breathe.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                'Natural Farming Through Play',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Interactive phase wheel
  Widget _buildInteractivePhaseWheel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '🔄 THE 5 PHASES',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, i) => _buildInteractivePhaseCard(i, isDark),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteractivePhaseCard(int index, bool isDark) {
    final phases = [
      {'emoji': '🐄', 'name': 'Feed', 'color': Colors.blue, 'desc': 'Nourish the cow'},
      {'emoji': '🪣', 'name': 'Collect', 'color': Colors.green, 'desc': 'Gather inputs'},
      {'emoji': '🧫', 'name': 'Mix', 'color': Colors.purple, 'desc': 'Make Jeevamrut'},
      {'emoji': '🌱', 'name': 'Apply', 'color': Colors.brown, 'desc': 'Nourish soil'},
      {'emoji': '🛡️', 'name': 'Defend', 'color': Colors.red, 'desc': 'Protect crops'},
    ];
    final phase = phases[index];
    final phaseColor = phase['color'] as Color;
    
    return GestureDetector(
      onTap: () => _showPhaseKnowledge(index, isDark),
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (_, __) => Transform.scale(
          scale: _breathe.value + (index % 2) * 0.02,
          child: Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  phaseColor.withOpacity(0.4),
                  phaseColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: phaseColor.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(color: phaseColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text(phase['emoji'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  phase['name'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: phaseColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  phase['desc'] as String,
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: phaseColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap to learn',
                    style: TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: phaseColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Enhanced game explanation
  Widget _buildEnhancedGameExplanation(bool isDark) {
    return AnimatedBuilder(
      animation: _breathe,
      builder: (_, __) => Transform.scale(
        scale: _breathe.value,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.15),
                Colors.teal.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🎮', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'MASTER NATURAL FARMING',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Experience the complete cow-to-soil cycle through 5 interactive phases. Learn ancient farming wisdom while playing!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniFeature('🐄', '5 Phases', Colors.green),
                  _buildMiniFeature('🌱', 'Organic', Colors.brown),
                  _buildMiniFeature('📚', 'Educational', Colors.purple),
                  _buildMiniFeature('🏆', 'Challenges', Colors.amber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiniFeature(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          Text(
            text,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Traditional wisdom section
  Widget _buildTraditionalWisdomSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.15),
            Colors.pink.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📚', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ANCIENT FARMING WISDOM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Discover traditional Indian agricultural practices passed down through generations. Learn about desi cows, natural farming, and sustainable living.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWisdomPillar('🐄', 'Desi Cows', 'Sacred animals with A2 milk'),
              _buildWisdomPillar('🌱', 'Soil Health', 'Living soil ecosystem'),
              _buildWisdomPillar('🧪', 'Jeevamrut', 'Natural life potion'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWisdomPillar(String emoji, String title, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.pink.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 7,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  // Enhanced play button with animations
  Widget _buildEnhancedPlayButton() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: GestureDetector(
          onTap: _startGame,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'BEGIN YOUR JOURNEY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Knowledge button
  Widget _buildKnowledgeButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showCompleteKnowledge(isDark),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.indigo.withOpacity(0.1 + _shimmer.value * 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📖', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text(
                'EXPLORE COMPLETE KNOWLEDGE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Show phase knowledge modal
  void _showPhaseKnowledge(int phaseIndex, bool isDark) {
    _playSound('tap');
    final phases = [
      GamePhase.phase1_feeding,
      GamePhase.phase2_collection,
      GamePhase.phase3_mixing,
      GamePhase.phase4_application,
      GamePhase.phase5_defense,
    ];
    final edu = _phaseEducation[phases[phaseIndex]]!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    edu['title'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.close, color: Colors.red, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Knowledge content
              _buildKnowledgeSection(edu['knowledge'] as String, isDark),
              const SizedBox(height: 20),
              
              // Additional info for phase 1 (cow breeds)
              if (phaseIndex == 0 && edu.containsKey('breeds'))
                _buildCowBreedsSection(edu['breeds'] as List<Map<String, String>>, isDark),
              
              // Key points
              _buildKeyPointsSection(edu['points'] as List<String>, isDark),
              const SizedBox(height: 20),
              
              // Message
              _buildMessageSection(edu['message'] as String, isDark),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show complete knowledge modal
  void _showCompleteKnowledge(bool isDark) {
    _playSound('tap');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📚 COMPLETE KNOWLEDGE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.close, color: Colors.red, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // All phases knowledge
              ...List.generate(5, (i) {
                final phases = [
                  GamePhase.phase1_feeding,
                  GamePhase.phase2_collection,
                  GamePhase.phase3_mixing,
                  GamePhase.phase4_application,
                  GamePhase.phase5_defense,
                ];
                final edu = _phaseEducation[phases[i]]!;
                return Column(
                  children: [
                    _buildCompactPhaseCard(edu['title'] as String, i, isDark),
                    if (i < 4) const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildKnowledgeSection(String knowledge, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.teal.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌱 Comprehensive Knowledge',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            knowledge,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCowBreedsSection(List<Map<String, String>> breeds, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.indigo.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🐄 Desi Cow Breeds',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          ...breeds.map((breed) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${breed['name']} - ${breed['origin']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Milk: ${breed['milk']} | Special: ${breed['special']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildKeyPointsSection(List<String> points, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.amber.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔑 Key Points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, color: Colors.orange)),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildMessageSection(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.pink.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.purple,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactPhaseCard(String title, int index, bool isDark) {
    final phaseIcons = ['🐄', '🪣', '🧫', '🌱', '🛡️'];
    final phaseColors = [Colors.blue, Colors.green, Colors.purple, Colors.brown, Colors.red];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            phaseColors[index].withOpacity(0.2),
            phaseColors[index].withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: phaseColors[index].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(phaseIcons[index], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: phaseColors[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _phase1UI(bool isDark, Size size) {
    return Stack(
      children: [
        // Background particles
        if (_particles.isNotEmpty)
          ..._particles.map((p) => Positioned(
            left: p.x * size.width,
            top: p.y * size.height,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: p.color,
                shape: BoxShape.circle,
              ),
            ),
          )),
        
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Text('🐄 Happiness:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _happiness / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(_happiness > 60 ? Colors.green : _happiness > 30 ? Colors.orange : Colors.red),
                          minHeight: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$_happiness%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _happiness > 50 ? Colors.green : Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _breathe,
                builder: (_, __) => Transform.scale(
                  scale: _breathe.value,
                  child: const Text('🐄', style: TextStyle(fontSize: 70)),
                ),
              ),
              Text('Tap healthy fodder! Avoid chemicals!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black45)),
            ],
          ),
        ),
        ..._fodder.map((f) => Positioned(
          left: f.x * (size.width - 70),
          top: f.y * (size.height * 0.5) + 60,
          child: GestureDetector(
            onTap: () => _tapFodder(f),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: f.good ? _pulse.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: f.good ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: f.good ? Colors.green : Colors.red, width: 2),
                    boxShadow: [BoxShadow(color: (f.good ? Colors.green : Colors.red).withOpacity(0.3), blurRadius: 8)],
                  ),
                  child: Text(f.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
        )),
        Positioned(
          top: 8, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
              child: Text('🌾🥕🌿 = Good  |  ☠️🧪 = Bad', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ),
      ],
    );
  }
  Widget _phase2UI(bool isDark, Size size) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _bucketX = (_bucketX + d.delta.dx / size.width).clamp(0.1, 0.9)),
      child: Stack(
        children: [
          Positioned(top: 15, left: 0, right: 0, child: Center(child: Column(children: [
            const Text('🐄💨', style: TextStyle(fontSize: 45)),
            Text('Collected: $_collected / $_collectTarget', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54)),
          ]))),
          ..._drops.map((d) => Positioned(
            left: d.x * size.width - 22,
            top: d.y * (size.height * 0.65) + 80,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (d.good ? Colors.amber : Colors.red).withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(color: (d.good ? Colors.amber : Colors.red).withOpacity(0.6), width: 2),
                boxShadow: [BoxShadow(color: (d.good ? Colors.amber : Colors.red).withOpacity(0.4), blurRadius: 12)],
              ),
              child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 24))),
            ),
          )),
          Positioned(
            bottom: 30,
            left: _bucketX * size.width - 50,
            child: Column(children: [
              Container(
                width: 100, height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.brown.shade300, Colors.brown.shade700]),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
                  border: Border.all(color: Colors.brown.shade900, width: 3),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: const Center(child: Text('🪣', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 6),
              Text('← Drag →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : Colors.black45)),
            ]),
          ),
        ],
      ),
    );
  }

  // ========== PHASE 3 UI ==========
  Widget _phase3UI(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Mix Perfect Jeevamrut 🧫', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.withOpacity(0.3))),
            child: Text('Target: Dung ~30% | Urine ~20% | Jaggery ~15% | Water ~35%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.purple), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          // Mixing pot
          Container(
            height: 160,
            decoration: BoxDecoration(color: Colors.brown.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.brown.withOpacity(0.4), width: 3)),
            child: Stack(children: [
              Positioned.fill(child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (_water > 0) Container(height: 140 * _water, color: Colors.blue.withOpacity(0.4)),
                  if (_jaggery > 0) Container(height: 140 * _jaggery, color: Colors.amber.withOpacity(0.6)),
                  if (_urine > 0) Container(height: 140 * _urine, color: Colors.yellow.withOpacity(0.5)),
                  if (_dung > 0) Container(height: 140 * _dung, color: Colors.brown.withOpacity(0.7)),
                ]),
              )),
              Center(child: Text(_fermenting ? '🧫 Fermenting... ${(_ferment * 100).round()}%' : '🫕 Add ingredients below', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87))),
            ]),
          ),
          const SizedBox(height: 16),
          _ingredientRow('🟤 Dung', _dung, 0.30, 'd', Colors.brown, isDark),
          _ingredientRow('🟡 Urine', _urine, 0.20, 'u', Colors.amber, isDark),
          _ingredientRow('🍯 Jaggery', _jaggery, 0.15, 'j', Colors.orange, isDark),
          _ingredientRow('💧 Water', _water, 0.35, 'w', Colors.blue, isDark),
          const SizedBox(height: 16),
          if (!_fermenting) GestureDetector(
            onTap: _startFerment,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 15)],
              ),
              child: const Text('🧫 Start Fermentation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientRow(String label, double val, double target, String type, Color c, bool isDark) {
    final close = (val - target).abs() < 0.1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: close ? Colors.green : c.withOpacity(0.3), width: close ? 2 : 1),
      ),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87))),
          GestureDetector(
            onTap: () => _setIngredient(type, (val - 0.05).clamp(0, 1)),
            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, size: 18)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(activeTrackColor: c, inactiveTrackColor: c.withOpacity(0.2), thumbColor: c),
              child: Slider(value: val, onChanged: _fermenting ? null : (v) => _setIngredient(type, v)),
            ),
          ),
          GestureDetector(
            onTap: () => _setIngredient(type, (val + 0.05).clamp(0, 1)),
            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, size: 18)),
          ),
          const SizedBox(width: 8),
          Text('${(val * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: close ? Colors.green : c)),
        ],
      ),
    );
  }

  // ========== PHASE 4 UI ==========
  Widget _phase4UI(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Nourish the Soil 🌱', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 6),
          Text('Tap to place nutrients. Roots will grow toward them!', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text('Placed: $_nutrients / $_nutrientTarget', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.brown.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.brown.withOpacity(0.3), width: 2)),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: 25,
                itemBuilder: (_, i) {
                  final x = i % 5, y = i ~/ 5;
                  final cell = _grid[y][x];
                  return GestureDetector(
                    onTap: () => _placeNutrient(x, y),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(colors: [
                          cell.root ? Colors.green.withOpacity(0.5) : cell.nutrient ? Colors.amber.withOpacity(0.5) : Colors.brown.withOpacity(0.15),
                          cell.root ? Colors.green.withOpacity(0.2) : cell.nutrient ? Colors.amber.withOpacity(0.2) : Colors.brown.withOpacity(0.05),
                        ]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cell.root ? Colors.green : cell.nutrient ? Colors.amber : Colors.brown.withOpacity(0.25), width: cell.root || cell.nutrient ? 2 : 1),
                      ),
                      child: Center(child: Text(cell.root ? '🌿' : cell.nutrient ? '✨' : '', style: const TextStyle(fontSize: 22))),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend('🌿', 'Root', Colors.green), const SizedBox(width: 20),
            _legend('✨', 'Nutrient', Colors.amber), const SizedBox(width: 20),
            _legend('⬜', 'Soil', Colors.brown),
          ]),
        ],
      ),
    );
  }

  Widget _legend(String e, String l, Color c) => Row(children: [Text(e), const SizedBox(width: 4), Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c))]);

  // ========== PHASE 5 UI (FAST!) ==========
  Widget _phase5UI(bool isDark, Size size) {
    return GestureDetector(
      onTapDown: (d) => _deployDefender(d.localPosition.dx / size.width, (d.localPosition.dy - 50) / (size.height * 0.7)),
      child: Stack(
        children: [
          // Timer display
          Positioned(
            top: 10, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: (_defenseTimer < 10 ? Colors.red : Colors.green).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (_defenseTimer < 10 ? Colors.red : Colors.green).withOpacity(0.5)),
                ),
                child: Text(
                  '⏱️ ${_defenseTimer}s remaining - DEFEND!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _defenseTimer < 10 ? Colors.red : Colors.green),
                ),
              ),
            ),
          ),
          // Crop area
          Positioned(
            left: size.width * 0.32, top: size.height * 0.25,
            child: Container(
              width: size.width * 0.36, height: size.height * 0.22,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.5), width: 3),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🥬🌽🥕', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text('HP: ${_cropHP.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _cropHP > 50 ? Colors.green : Colors.red)),
                const SizedBox(height: 4),
                SizedBox(width: 80, child: LinearProgressIndicator(value: _cropHP / 100, backgroundColor: Colors.grey.withOpacity(0.3), valueColor: AlwaysStoppedAnimation(_cropHP > 50 ? Colors.green : Colors.red))),
              ]),
            ),
          ),
          // Pests
          ..._pests.map((p) => Positioned(
            left: p.x * size.width - 22,
            top: p.y * size.height * 0.6 + 60,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.25), shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 2)),
              child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 24))),
            ),
          )),
          // Defenders
          ..._defenders.map((d) => Positioned(
            left: d.x * size.width - 24,
            top: d.y * size.height * 0.6 + 60,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 12)],
              ),
              child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 26))),
            ),
          )),
          // Deploy hint
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                child: Text('👆 TAP anywhere to deploy defenders! (${_defenders.length}/${4 + _level})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== GAME OVER / LEVEL COMPLETE ==========
  Widget _gameOverUI(bool isDark) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💀', style: TextStyle(fontSize: 70)),
        const SizedBox(height: 20),
        Text('Game Over', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 20),
        _endStat('Final Score', '$_score', Colors.amber, isDark),
        const SizedBox(height: 10),
        _endStat('Max Combo', '${_maxCombo}x', Colors.orange, isDark),
        const SizedBox(height: 10),
        _endStat('Level', '$_level', Colors.blue, isDark),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _btn('🔄 Retry', Colors.green, _startGame),
          const SizedBox(width: 14),
          _btn('🏠 Menu', Colors.blue, () => setState(() => _phase = GamePhase.menu)),
        ]),
      ]),
    ),
  );

  Widget _levelCompleteUI(bool isDark) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        const Text('🎉', style: TextStyle(fontSize: 70)),
        const SizedBox(height: 16),
        Text('Level $_level Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text('You completed the entire Cow → Soil Cycle! 🐄→🌱→🥬', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green)),
        const SizedBox(height: 20),
        _endStat('Score', '$_score', Colors.amber, isDark),
        const SizedBox(height: 10),
        _endStat('Lives', '$_lives', Colors.red, isDark),
        const SizedBox(height: 10),
        _endStat('Max Combo', '${_maxCombo}x', Colors.orange, isDark),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.3))),
          child: Column(children: [
            const Text('🌍 Your Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_getLevelTip(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, height: 1.5), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _btn('➡️ Level ${_level + 1}', Colors.green, _nextLevel),
          const SizedBox(width: 14),
          _btn('🏠 Menu', Colors.blue, () => setState(() => _phase = GamePhase.menu)),
        ]),
      ]),
    ),
  );

  String _getLevelTip() {
    final tips = [
      'You helped one desi cow support an entire acre of farmland!',
      'Your Jeevamrut contains billions of beneficial soil microbes!',
      'Natural defenders you deployed can protect farms for generations!',
      'Healthy soil from this cycle can hold 20x more water than degraded soil!',
      'Zero chemicals used = Zero harm to farmers, consumers, and environment!',
    ];
    return tips[(_level - 1) % tips.length];
  }

  Widget _endStat(String l, String v, Color c, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(l, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
      const SizedBox(width: 16),
      Text(v, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
    ]),
  );

  Widget _btn(String l, Color c, VoidCallback onTap) => GestureDetector(
    onTap: () { _playSound('tap'); onTap(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c, c.withOpacity(0.8)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))]),
      child: Text(l, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
    ),
  );
}

// ========== ENUMS & DATA CLASSES ==========
enum GamePhase { menu, phase1_feeding, phase2_collection, phase3_mixing, phase4_application, phase5_defense, gameOver, levelComplete }

class _FodderItem { final int id; final double x, y; final bool good; final String emoji; double ttl; _FodderItem({required this.id, required this.x, required this.y, required this.good, required this.emoji, required this.ttl}); }
class _Drop { final int id; double x, y; final double speed; final bool good; final String emoji; _Drop({required this.id, required this.x, required this.y, required this.speed, required this.good, required this.emoji}); }
class _Cell { final int x, y; bool nutrient = false, root = false; _Cell(this.x, this.y); }
class _Pest { final int id; double x, y; final double speed; final String emoji; int hp; _Pest({required this.id, required this.x, required this.y, required this.speed, required this.emoji, required this.hp}); }
class _Defender { final int id; double x, y; final String emoji; _Defender({required this.id, required this.x, required this.y, required this.emoji}); }

// Particle classes for enhanced visual effects
class _Particle {
  double x, y, vx, vy, life;
  final Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.life});
}

class _Sparkle {
  double x, y, size, opacity, speed;
  final Color color;
  _Sparkle({required this.x, required this.y, required this.size, required this.opacity, required this.speed, required this.color});
}
