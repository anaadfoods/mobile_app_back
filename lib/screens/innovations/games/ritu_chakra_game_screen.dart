import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// 🌸 RITU CHAKRA - Seasonal Farming Strategy
/// Master the 6 Hindu seasons! Plan crops, manage resources, survive weather events.
/// A year-long cycle of growth, harvest, and wisdom.
class RituChakraGameScreen extends StatefulWidget {
  const RituChakraGameScreen({super.key});
  @override
  State<RituChakraGameScreen> createState() => _RituChakraState();
}

class _RituChakraState extends State<RituChakraGameScreen>
    with TickerProviderStateMixin {
  // Game State
  GamePhase _phase = GamePhase.menu;
  int _year = 1;
  int _currentRitu = 0; // 0-5 for 6 seasons
  int _dayInRitu = 1;
  int _score = 0;
  int _highScore = 0;
  int _coins = 0;
  int _wisdom = 0; // Knowledge points

  // Resources
  double _water = 100;
  double _seeds = 50;
  double _fertilizer = 30;
  double _energy = 100;
  int _harvest = 0;

  // Farm grid (5x4 = 20 plots)
  late List<List<_Plot>> _farmGrid;

  // Weather & Events
  String _currentWeather = 'clear';
  List<_Event> _activeEvents = [];
  List<_Notification> _notifications = [];

  // Particles
  List<_Particle> _particles = [];
  List<_WeatherParticle> _weatherParticles = [];

  // Achievements & Unlocks
  final Map<String, bool> _achievements = {};
  final Map<String, int> _cropsMastered = {};

  // Animation controllers - Enhanced with more controllers
  late AnimationController _sunCtrl,
      _seasonCtrl,
      _pulseCtrl,
      _weatherCtrl,
      _glowCtrl;
  late AnimationController _floatCtrl, _rotateCtrl, _shimmerCtrl, _breatheCtrl;
  late Animation<double> _sunAnim,
      _seasonAnim,
      _pulseAnim,
      _weatherAnim,
      _glowAnim;
  late Animation<double> _floatAnim, _rotateAnim, _shimmerAnim, _breatheAnim;
  Timer? _gameTimer;
  final _rand = math.Random();

  // The 6 Ritus (Seasons) - Enhanced with traditional knowledge
  static const _ritus = [
    _Ritu(
      'vasant',
      'Vasant',
      '🌸',
      'Spring',
      AppColors.parchment,
      AppColors.parchment,
      'Chaitra-Vaishakh',
      'Perfect for sowing. Mild weather, flowers bloom.',
      knowledge:
          '🌸 Vasant Ritu: Spring Season (Feb-Mar)\n\n🌱 Agricultural Significance:\n• Best time for sowing summer crops\n• Soil preparation with organic manure\n• Plant wheat, barley, grams, and vegetables\n• Ideal temperature: 20-25°C\n\n🙏 Traditional Wisdom:\n• "Vasant is king of seasons" - Basant Panchami\n• Goddess Saraswati worshipped for knowledge\n• Mustard fields bloom like gold carpets\n• Time of renewal and new beginnings\n\n🌾 Traditional Crops:\n• Wheat ( Gehun) - Main rabi crop\n• Mustard (Sarson) - Oil and spice\n• Lentils (Masoor) - Protein source\n• Vegetables - Cauliflower, peas, spinach\n\n💧 Water Management:\n• Moderate irrigation needed\n• Dew provides natural moisture\n• Check soil moisture before watering\n\n🪴 Traditional Practices:\n• Apply Jeevamrut before sowing\n• Use desi cow dung for soil health\n• Follow lunar calendar for planting\n• Mulching to retain soil moisture',
      festivals: ['Vasant Panchami', 'Holi', 'Gudi Padwa'],
      traditionalTips: [
        'Sow seeds during Krishna Paksha',
        'Apply neem cake to prevent pests',
        'Plant marigold borders for natural pest control',
      ],
    ),

    _Ritu(
      'grishma',
      'Grishma',
      '☀️',
      'Summer',
      AppColors.parchment,
      AppColors.parchment,
      'Jyeshtha-Ashadh',
      'Hot & dry. Conserve water, protect crops from heat.',
      knowledge:
          '☀️ Grishma Ritu: Summer Season (Apr-May)\n\n🌡️ Agricultural Significance:\n• Peak summer with temperatures 35-45°C\n• Critical period for water management\n• Harvest of rabi crops completes\n• Land preparation for kharif crops\n\n🔥 Traditional Wisdom:\n• "Grishma tests farmer\'s patience"\n• Time of intense heat and water scarcity\n• Ancient water conservation methods\n• Shade trees protect young saplings\n\n🌾 Traditional Crops:\n• Bajra (Pearl Millet) - Drought resistant\n• Jowar (Sorghum) - Hardy grain\n• Moong (Green Gram) - Quick crop\n• Cotton - Heat tolerant cash crop\n\n💧 Water Management:\n• Early morning irrigation (4-6 AM)\n• Drip irrigation most efficient\n• Mulching reduces water loss by 70%\n• Check soil at 6-inch depth\n\n🪴 Traditional Practices:\n• Create shaded nurseries\n• Use greenhouses for sensitive plants\n• Apply ash to control pests\n• Windbreaks with bamboo or trees\n\n🌡️ Heat Protection:\n• Cover sensitive plants with straw\n• Use terracotta pots for better insulation\n• Apply Ghanabhram (liquid mulch)',
      festivals: ['Ganga Saptami', 'Nirjala Ekadashi', 'Vat Savitri'],
      traditionalTips: [
        'Irrigate during Brahma Muhurta',
        'Use buttermilk spray for heat stress',
        'Plant drought-resistant native varieties',
      ],
    ),

    _Ritu(
      'varsha',
      'Varsha',
      '🌧️',
      'Monsoon',
      AppColors.parchment,
      AppColors.parchment,
      'Shravan-Bhadra',
      'Heavy rains. Plant paddy, watch for floods.',
      knowledge:
          '🌧️ Varsha Ritu: Monsoon Season (Jun-Jul)\n\n🌊 Agricultural Significance:\n• Main kharif cropping season\n• 80% of annual rainfall received\n• Rice transplantation period\n• Natural soil rejuvenation\n\n🌦️ Traditional Wisdom:\n• "Varsha brings life to barren land"\n• Time of abundance and growth\n• Ancient rainwater harvesting\n• Farmers pray to Indra for rains\n\n🌾 Traditional Crops:\n• Rice (Dhan) - Staple food crop\n• Maize (Makai) - Food and fodder\n• Arhar (Pigeon Pea) - Protein source\n• Soybean - Oil and protein\n• Sugarcane - Cash crop\n\n💧 Water Management:\n• Create contour bunds to prevent erosion\n• Build farm ponds for rainwater storage\n• Use raised beds in waterlogged areas\n• Maintain proper drainage channels\n\n🪴 Traditional Practices:\n• SRI method for rice cultivation\n• Apply farmyard manure before rains\n• Use mixed cropping for risk management\n• Plant legumes for nitrogen fixation\n\n🌊 Flood Protection:\n• Build embankments on field boundaries\n• Plant deep-rooted trees on bunds\n• Create elevated storage for seeds\n\n🐛 Pest Management:\n• Neem oil sprays during dry spells\n• Light traps for insects at night\n• Biological pest control with birds',
      festivals: [
        'Guru Purnima',
        'Nag Panchami',
        'Raksha Bandhan',
        'Krishna Janmashtami',
      ],
      traditionalTips: [
        'Transplant rice during Ashadha',
        'Use Azolla as bio-fertilizer',
        'Apply Trichoderma for disease control',
      ],
    ),

    _Ritu(
      'sharad',
      'Sharad',
      '🍂',
      'Autumn',
      AppColors.parchment,
      AppColors.parchment,
      'Ashwin-Kartik',
      'Cool nights. Harvest time, prepare for winter.',
      knowledge:
          '🍂 Sharad Ritu: Autumn Season (Aug-Sep)\n\n🌾 Agricultural Significance:\n• Main harvest season for kharif crops\n• Clear skies and pleasant weather\n• Ideal temperature: 25-30°C\n• Post-monsoon cropping period\n\n🌅 Traditional Wisdom:\n• "Sharad rewards farmer\'s hard work"\n• Time of celebration and abundance\n• Navratri - nine nights of celebration\n• Moon is brightest and clearest\n\n🌾 Traditional Crops:\n• Rice harvesting continues\n• Maize ready for harvest\n• Pulses - Tur, Urad, Moong\n• Oilseeds - Groundnut, Sesame\n• Vegetables - Onion, tomato\n\n🌾 Harvesting Techniques:\n• Use sickles for manual harvesting\n• Threshing on clean threshing floors\n• Winnowing during afternoon breeze\n• Store in cool, dry places\n\n🪴 Post-Harvest Practices:\n• Solar drying of grains\n• Apply neem leaves for storage pest control\n• Use bamboo granaries with proper ventilation\n• Maintain moisture content below 12%\n\n🌱 Rabi Crop Preparation:\n• Land preparation for wheat\n• Apply FYM and compost\n• Create raised beds for drainage\n• Test soil for nutrient deficiencies\n\n🎊 Cultural Significance:\n• Harvest festivals across India\n• Onam in Kerala - rice harvest\n• Durga Puja - celebration of abundance\n• Diwali - festival of lights and prosperity',
      festivals: [
        'Ganesh Chaturthi',
        'Navratri',
        'Durga Puja',
        'Dussehra',
        'Diwali',
      ],
      traditionalTips: [
        'Harvest during bright moonlight',
        'Store grains in bamboo structures',
        'Apply turmeric paste to prevent pests',
      ],
    ),

    _Ritu(
      'hemant',
      'Hemant',
      '🌫️',
      'Pre-Winter',
      AppColors.parchment,
      AppColors.parchment,
      'Margshirsh-Paush',
      'Mild cold. Plant winter crops, store harvest.',
      knowledge:
          '🌫️ Hemant Ritu: Pre-Winter Season (Oct-Nov)\n\n❄️ Agricultural Significance:\n• Beginning of rabi cropping season\n• Cool temperatures: 15-20°C\n• Ideal for wheat and barley sowing\n• Time for soil preparation\n\n🌾 Traditional Wisdom:\n• "Hemant prepares for winter\'s test"\n• Time of transition and preparation\n• Margshirsh month considered auspicious\n• Cows fed special diet for health\n\n🌾 Traditional Crops:\n• Wheat (Gehun) - Primary rabi crop\n• Barley (Jau) - Traditional grain\n• Mustard (Sarson) - Winter oilseed\n• Coriander - Spice crop\n• Peas - Vegetable crop\n• Potatoes - Tubers\n\n🌱 Sowing Practices:\n• Line sowing for better yield\n• Seed treatment with cow dung\n• Optimal seed depth: 2-3 inches\n• Spacing: 6-8 inches between rows\n\n💧 Water Management:\n• Light irrigation after sowing\n• Avoid waterlogging\n• Check soil moisture regularly\n• Use furrow irrigation method\n\n🪴 Traditional Practices:\n• Apply Ghanabhram (liquid manure)\n• Use crop rotation principles\n• Plant border crops for pest control\n• Prepare compost from crop residue\n\n🐄 Livestock Care:\n• Provide warm shelters\n• Feed jaggery and turmeric mixture\n• Use cow dung for biogas\n• Store fodder for winter\n\n🌡️ Frost Protection:\n• Cover sensitive plants with straw\n• Create windbreaks with hedges\n• Use smoke to prevent frost damage',
      festivals: [
        'Bhai Dooj',
        'Chhath Puja',
        'Guru Nanak Jayanti',
        'Makar Sankranti',
      ],
      traditionalTips: [
        'Sow wheat after Makar Sankranti',
        'Use mustard cake as fertilizer',
        'Apply mulch to protect from frost',
      ],
    ),

    _Ritu(
      'shishir',
      'Shishir',
      '❄️',
      'Winter',
      AppColors.parchment,
      AppColors.parchment,
      'Magh-Phalgun',
      'Cold & frost. Protect crops, plan for spring.',
      knowledge:
          '❄️ Shishir Ritu: Winter Season (Dec-Jan)\n\n🥶 Agricultural Significance:\n• Coldest period: 5-15°C\n• Frost risk in northern regions\n• Critical growth period for rabi crops\n• Time for maintenance and planning\n\n⚡ Traditional Wisdom:\n• "Shishir tests farmer\'s foresight"\n• Time of conservation and protection\n• Magh month holy for farming\n• Traditional knowledge sharing season\n\n🌾 Crop Management:\n• Wheat tillering stage\n• Barley heading stage\n• Mustard flowering\n• Pea pod development\n\n🛡️ Frost Protection:\n• Light irrigation before dawn\n• Create smoke layers in fields\n• Cover plants with straw or cloth\n• Use frost-resistant varieties\n\n💧 Water Management:\n• Minimal irrigation needed\n• Check for frost damage\n• Maintain soil moisture\n• Avoid waterlogging\n\n🪴 Traditional Practices:\n• Apply ash to control fungal diseases\n• Use neem oil for pest control\n• Prune fruit trees during dormancy\n• Prepare land for spring crops\n\n🌱 Spring Preparation:\n• Test soil for nutrients\n• Prepare compost piles\n• Plan crop rotation\n• Repair farm equipment\n\n🐄 Livestock Management:\n• Provide warm bedding\n• Supplement feed with minerals\n• Protect from cold winds\n• Store milk properly\n\n📚 Knowledge Transfer:\n• Time for learning and planning\n• Share farming experiences\n• Prepare seed selection\n• Study traditional almanacs',
      festivals: ['Vasant Panchami', 'Maha Shivaratri', 'Holi'],
      traditionalTips: [
        'Protect crops from frost',
        'Use greenhouses for vegetables',
        'Store seeds in warm, dry places',
      ],
    ),
  ];

  // Crops with seasonal preferences
  static const _crops = [
    _Crop(
      'wheat',
      '🌾',
      'Wheat',
      ['hemant', 'shishir'],
      60,
      80,
      AppColors.parchment,
    ),
    _Crop(
      'rice',
      '🍚',
      'Paddy',
      ['varsha', 'sharad'],
      90,
      100,
      AppColors.parchment,
    ),
    _Crop(
      'millet',
      '🫘',
      'Millet',
      ['grishma', 'varsha'],
      45,
      60,
      AppColors.parchment,
    ),
    _Crop(
      'mustard',
      '🌻',
      'Mustard',
      ['hemant', 'shishir'],
      50,
      70,
      AppColors.parchment,
    ),
    _Crop(
      'cotton',
      '☁️',
      'Cotton',
      ['varsha', 'sharad'],
      120,
      90,
      AppColors.parchment,
    ),
    _Crop(
      'sugarcane',
      '🎋',
      'Sugarcane',
      ['vasant', 'grishma'],
      150,
      120,
      AppColors.parchment,
    ),
    _Crop(
      'vegetables',
      '🥬',
      'Vegetables',
      ['vasant', 'sharad'],
      30,
      40,
      AppColors.parchment,
    ),
    _Crop(
      'pulses',
      '🥜',
      'Pulses',
      ['sharad', 'hemant'],
      70,
      55,
      AppColors.parchment,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initFarm();
  }

  void _initAnimations() {
    // Sun rotation (60 seconds for full rotation)
    _sunCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _sunAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_sunCtrl);

    // Season transition (20 seconds)
    _seasonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _seasonAnim = Tween<double>(begin: 0, end: 1).animate(_seasonCtrl);

    // Pulse effect (1.5 seconds)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Weather effects (3 seconds)
    _weatherCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _weatherAnim = Tween<double>(begin: 0, end: 1).animate(_weatherCtrl);

    // Glow effect (2 seconds)
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_glowCtrl);

    // Floating animation (4 seconds)
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Rotation for decorative elements (10 seconds)
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _rotateAnim = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateCtrl);

    // Shimmer effect (2.5 seconds)
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerCtrl);

    // Breathing effect for UI elements (3 seconds)
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
  }

  void _initFarm() {
    _farmGrid = List.generate(
      4,
      (y) => List.generate(5, (x) => _Plot(x: x, y: y)),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _sunCtrl.dispose();
    _seasonCtrl.dispose();
    _pulseCtrl.dispose();
    _weatherCtrl.dispose();
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _shimmerCtrl.dispose();
    _breatheCtrl.dispose();
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
    }
  }

  // ==================== GAME LOGIC ====================
  void _startGame() {
    _haptic('medium');
    setState(() {
      _phase = GamePhase.playing;
      _year = 1;
      _currentRitu = 0;
      _dayInRitu = 1;
      _score = 0;
      _water = 100;
      _seeds = 50;
      _fertilizer = 30;
      _energy = 100;
      _harvest = 0;
      _currentWeather = 'clear';
      _activeEvents = [];
      _notifications = [];
      _particles = [];
      _weatherParticles = [];
      _initFarm();
    });
    _startGameLoop();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (_phase != GamePhase.playing) return;

      setState(() {
        // Update particles
        _particles =
            _particles.where((p) {
              p.life -= 0.02;
              p.x += p.vx;
              p.y += p.vy;
              p.vy += 0.1;
              return p.life > 0;
            }).toList();

        // Update weather particles
        _updateWeatherParticles();

        // Update notifications
        _notifications =
            _notifications.where((n) {
              n.life -= 0.01;
              return n.life > 0;
            }).toList();
      });
    });
  }

  void _updateWeatherParticles() {
    final ritu = _ritus[_currentRitu];

    // Spawn weather particles based on season
    if (_currentWeather == 'rain' || ritu.id == 'varsha') {
      if (_rand.nextDouble() < 0.3) {
        _weatherParticles.add(
          _WeatherParticle(
            x: _rand.nextDouble() * 400,
            y: -10,
            vx: -1,
            vy: 8 + _rand.nextDouble() * 4,
            type: 'rain',
          ),
        );
      }
    } else if (ritu.id == 'shishir' && _rand.nextDouble() < 0.1) {
      _weatherParticles.add(
        _WeatherParticle(
          x: _rand.nextDouble() * 400,
          y: -10,
          vx: _rand.nextDouble() * 2 - 1,
          vy: 2 + _rand.nextDouble() * 2,
          type: 'snow',
        ),
      );
    } else if (ritu.id == 'vasant' && _rand.nextDouble() < 0.05) {
      _weatherParticles.add(
        _WeatherParticle(
          x: _rand.nextDouble() * 400,
          y: -10,
          vx: _rand.nextDouble() * 3 - 1.5,
          vy: 1 + _rand.nextDouble() * 2,
          type: 'petal',
        ),
      );
    }

    // Update existing particles
    _weatherParticles =
        _weatherParticles.where((p) {
          p.x += p.vx;
          p.y += p.vy;
          return p.y < 600;
        }).toList();

    // Limit particles
    if (_weatherParticles.length > 100) {
      _weatherParticles = _weatherParticles.sublist(
        _weatherParticles.length - 100,
      );
    }
  }

  void _advanceDay() {
    if (_energy < 10) {
      _addNotification('⚠️ Too tired! Rest or eat to regain energy.');
      return;
    }

    _haptic('light');
    setState(() {
      _dayInRitu++;
      _energy = (_energy - 5).clamp(0, 100);

      // Process crops
      _processCrops();

      // Random events
      if (_rand.nextDouble() < 0.15) _triggerEvent();

      // Season change every 60 days (approx 2 months)
      if (_dayInRitu > 60) {
        _dayInRitu = 1;
        _currentRitu = (_currentRitu + 1) % 6;
        _onSeasonChange();

        // Year complete
        if (_currentRitu == 0) {
          _year++;
          _onYearComplete();
        }
      }

      // Natural resource changes
      _applySeasonalEffects();
    });
  }

  void _processCrops() {
    final ritu = _ritus[_currentRitu];

    for (var row in _farmGrid) {
      for (var plot in row) {
        if (plot.crop != null && !plot.isHarvested) {
          final crop = _crops.firstWhere((c) => c.id == plot.crop);
          final isIdealSeason = crop.idealSeasons.contains(ritu.id);

          // Growth
          double growthRate = isIdealSeason ? 2.0 : 0.8;
          if (_water < 30) growthRate *= 0.5;
          if (plot.isWatered) growthRate *= 1.3;
          if (plot.isFertilized) growthRate *= 1.2;

          plot.growth += growthRate;
          plot.daysPlanted++;
          plot.isWatered = false; // Reset daily

          // Ready to harvest?
          if (plot.growth >= 100) {
            plot.isReadyToHarvest = true;
          }

          // Crop death
          if (_water < 10 && !isIdealSeason) {
            if (_rand.nextDouble() < 0.1) {
              plot.crop = null;
              plot.growth = 0;
              _addNotification('💀 A ${crop.name} crop died from drought!');
            }
          }
        }
      }
    }
  }

  void _applySeasonalEffects() {
    final ritu = _ritus[_currentRitu];

    switch (ritu.id) {
      case 'grishma': // Hot summer
        _water = (_water - 2).clamp(0, 100);
        break;
      case 'varsha': // Monsoon
        _water = (_water + 3).clamp(0, 100);
        break;
      case 'shishir': // Winter
        _energy = (_energy - 1).clamp(0, 100);
        break;
    }
  }

  void _onSeasonChange() {
    final ritu = _ritus[_currentRitu];
    _addNotification('🌀 ${ritu.name} (${ritu.english}) begins!');
    _score += 50;
    _wisdom += 5;

    // Bonus resources based on season
    switch (ritu.id) {
      case 'varsha':
        _water = 100;
        _addNotification('🌧️ Monsoon rains fill your water reserves!');
        break;
      case 'sharad':
        _addNotification('🍂 Harvest season! Gather your crops.');
        break;
    }
  }

  void _onYearComplete() {
    _haptic('heavy');
    _addNotification('🎉 Year $_year complete! Well done, farmer!');
    _score += 200 + (_harvest * 2);
    _coins += _harvest ~/ 2;

    if (_score > _highScore) _highScore = _score;

    // Check for victory
    if (_year >= 3 && _harvest >= 500) {
      setState(() => _phase = GamePhase.victory);
      _gameTimer?.cancel();
    }
  }

  void _triggerEvent() {
    final currentRitu = _ritus[_currentRitu];
    final events =
        [
          // Season-specific events
          if (currentRitu.id == 'vasant')
            _Event(
              'basant_panchami',
              '🌸',
              'Basant Panchami',
              'Saraswati blesses your knowledge! +10 wisdom',
              () {
                _wisdom += 10;
              },
            ),
          if (currentRitu.id == 'grishma')
            _Event(
              'heat_wave',
              '🔥',
              'Heat Wave',
              'Extreme heat! Water evaporates faster',
              () => _water = (_water - 15).clamp(0, 100),
            ),
          if (currentRitu.id == 'varsha')
            _Event(
              'monsoon_blessing',
              '🌧️',
              'Monsoon Blessing',
              'Abundant rains! Water reserves full',
              () => _water = 100,
            ),
          if (currentRitu.id == 'sharad')
            _Event(
              'harvest_festival',
              '🎊',
              'Harvest Festival',
              'Celebrate abundance! +30 energy, +15 wisdom',
              () {
                _energy = (_energy + 30).clamp(0, 100);
                _wisdom += 15;
              },
            ),
          if (currentRitu.id == 'hemant')
            _Event(
              'dew_blessing',
              '💧',
              'Morning Dew',
              'Natural moisture nourishes crops',
              () => _processCropsBonus(1.2),
            ),
          if (currentRitu.id == 'shishir')
            _Event(
              'frost_warning',
              '❄️',
              'Frost Warning',
              'Protect your crops from frost!',
              () => _damageCrops(10),
            ),

          // General events
          _Event(
            'drought',
            '🏜️',
            'Drought Warning',
            'Water levels dropping fast!',
            () => _water = (_water - 20).clamp(0, 100),
          ),
          _Event(
            'pest',
            '🐛',
            'Pest Attack',
            'Pests are eating your crops!',
            () => _damageCrops(15),
          ),
          _Event(
            'festival',
            '🪔',
            'Harvest Festival',
            'Celebrate! +20 energy, +10 wisdom',
            () {
              _energy = (_energy + 20).clamp(0, 100);
              _wisdom += 10;
            },
          ),
          _Event(
            'rain',
            '🌧️',
            'Heavy Rain',
            'Unexpected rain! Water reserves full.',
            () => _water = 100,
          ),
          _Event(
            'market',
            '🏪',
            'Market Day',
            'Good prices! +50% harvest value.',
            () => _harvest = (_harvest * 1.5).toInt(),
          ),
          _Event(
            'blessing',
            '🙏',
            'Divine Blessing',
            'The gods favor your farm! All resources +20',
            () {
              _water = (_water + 20).clamp(0, 100);
              _seeds = (_seeds + 20).clamp(0, 100);
              _fertilizer = (_fertilizer + 20).clamp(0, 100);
              _energy = (_energy + 20).clamp(0, 100);
            },
          ),
          _Event(
            'compost_ready',
            '🌱',
            'Compost Ready',
            'Your compost is ready! +15 fertilizer',
            () => _fertilizer = (_fertilizer + 15).clamp(0, 100),
          ),
          _Event(
            'community_help',
            '🤝',
            'Community Help',
            'Neighbors help! +10 seeds, +10 energy',
            () {
              _seeds = (_seeds + 10).clamp(0, 100);
              _energy = (_energy + 10).clamp(0, 100);
            },
          ),
        ].where((e) => e != null).cast<_Event>().toList();

    final event = events[_rand.nextInt(events.length)];
    event.effect();
    _addNotification('${event.emoji} ${event.name}: ${event.description}');
  }

  void _processCropsBonus(double multiplier) {
    for (var row in _farmGrid) {
      for (var plot in row) {
        if (plot.crop != null && !plot.isHarvested) {
          plot.growth = (plot.growth * multiplier).clamp(0, 100);
        }
      }
    }
  }

  void _damageCrops(double damage) {
    for (var row in _farmGrid) {
      for (var plot in row) {
        if (plot.crop != null && !plot.isHarvested) {
          plot.growth = (plot.growth - damage).clamp(0, 100);
        }
      }
    }
  }

  void _plantCrop(int x, int y, String cropId) {
    final plot = _farmGrid[y][x];
    if (plot.crop != null || _seeds < 5) return;

    _haptic('medium');
    setState(() {
      plot.crop = cropId;
      plot.growth = 0;
      plot.daysPlanted = 0;
      plot.isHarvested = false;
      plot.isReadyToHarvest = false;
      _seeds -= 5;
      _energy -= 3;

      final crop = _crops.firstWhere((c) => c.id == cropId);
      _spawnParticles(x * 70.0 + 35, y * 70.0 + 35, crop.color);
    });
  }

  void _waterPlot(int x, int y) {
    if (_water < 5) return;
    final plot = _farmGrid[y][x];
    if (plot.crop == null || plot.isWatered) return;

    _haptic('light');
    setState(() {
      plot.isWatered = true;
      _water -= 5;
      _energy -= 1;
      _spawnParticles(x * 70.0 + 35, y * 70.0 + 35, AppColors.deepSoilGreen);
    });
  }

  void _fertilizePlot(int x, int y) {
    if (_fertilizer < 5) return;
    final plot = _farmGrid[y][x];
    if (plot.crop == null || plot.isFertilized) return;

    _haptic('light');
    setState(() {
      plot.isFertilized = true;
      _fertilizer -= 5;
      _energy -= 2;
      _spawnParticles(x * 70.0 + 35, y * 70.0 + 35, AppColors.rawEarth);
    });
  }

  void _harvestPlot(int x, int y) {
    final plot = _farmGrid[y][x];
    if (!plot.isReadyToHarvest) return;

    _haptic('heavy');
    final crop = _crops.firstWhere((c) => c.id == plot.crop);

    setState(() {
      final yieldAmount = crop.baseYield + (_rand.nextInt(20) - 10);
      _harvest += yieldAmount;
      _score += yieldAmount;
      _seeds += 2; // Get some seeds back

      plot.crop = null;
      plot.growth = 0;
      plot.isHarvested = true;
      plot.isReadyToHarvest = false;
      plot.isFertilized = false;

      _cropsMastered[crop.id] = (_cropsMastered[crop.id] ?? 0) + 1;

      _addNotification('🌾 Harvested ${crop.name}! +$yieldAmount yield');
      _spawnParticles(
        x * 70.0 + 35,
        y * 70.0 + 35,
        AppColors.harvestAmber,
        count: 20,
      );
    });
  }

  void _spawnParticles(double x, double y, Color color, {int count = 10}) {
    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          x: x,
          y: y,
          vx: (_rand.nextDouble() - 0.5) * 8,
          vy: -_rand.nextDouble() * 6 - 2,
          color: color,
          life: 1.0,
        ),
      );
    }
  }

  void _addNotification(String message) {
    _notifications.add(_Notification(message: message, life: 1.0));
  }

  void _rest() {
    _haptic('light');
    setState(() {
      _energy = (_energy + 30).clamp(0, 100);
      _advanceDay();
      _advanceDay();
      _advanceDay();
    });
  }

  void _buyResources(String type) {
    if (_coins < 10) return;
    _haptic('select');
    setState(() {
      _coins -= 10;
      switch (type) {
        case 'seeds':
          _seeds = (_seeds + 20).clamp(0, 100);
          break;
        case 'fertilizer':
          _fertilizer = (_fertilizer + 15).clamp(0, 100);
          break;
        case 'water':
          _water = (_water + 30).clamp(0, 100);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic seasonal background
          _buildSeasonalBackground(isDark, size),

          // Weather effects overlay
          _buildWeatherOverlay(),

          // Main content
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: switch (_phase) {
                GamePhase.menu => _buildMenu(isDark),
                GamePhase.playing => _buildGameScreen(isDark, size),
                GamePhase.victory => _buildVictory(isDark),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalBackground(bool isDark, Size size) {
    final ritu = _ritus[_phase == GamePhase.playing ? _currentRitu : 0];

    return AnimatedBuilder(
      animation: _seasonAnim,
      builder:
          (_, __) => AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ritu.colorLight.withValues(alpha: isDark ? 0.3 : 0.6),
                  ritu.colorDark.withValues(alpha: isDark ? 0.2 : 0.4),
                  isDark ? AppColors.parchment : AppColors.parchment,
                ],
              ),
            ),
            child: CustomPaint(
              size: size,
              painter: _SeasonBackgroundPainter(
                ritu: ritu,
                progress: _seasonAnim.value,
                isDark: isDark,
              ),
            ),
          ),
    );
  }

  Widget _buildWeatherOverlay() {
    return IgnorePointer(
      child: Stack(
        children:
            _weatherParticles.map((p) {
              Widget particle;
              switch (p.type) {
                case 'rain':
                  particle = Container(
                    width: 2,
                    height: 15,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.deepSoilGreen.withValues(alpha: 0.1),
                          AppColors.deepSoilGreen.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                  break;
                case 'snow':
                  particle = Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.parchment.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.parchment.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                  break;
                case 'petal':
                  particle = Text(
                    '🌸',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.harvestAmber.withValues(alpha: 0.8),
                    ),
                  );
                  break;
                default:
                  particle = const SizedBox();
              }
              return Positioned(left: p.x, top: p.y, child: particle);
            }).toList(),
      ),
    );
  }

  // ==================== PROFESSIONAL MENU ====================
  Widget _buildMenu(bool isDark) {
    final primaryColor = AppColors.parchment; // Deep orange
    final textColor = isDark ? AppColors.parchment : AppColors.parchment;
    final subtleColor = isDark ? AppColors.parchment60 : AppColors.charcoal54;

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
            'Ritu Chakra',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seasonal Farming Strategy',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: subtleColor,
            ),
          ),
          const SizedBox(height: 32),

          // Clean season cards
          _buildCleanSeasonSection(
            isDark,
            primaryColor,
            textColor,
            subtleColor,
          ),
          const SizedBox(height: 24),

          // Simple description
          _buildCleanDescription(isDark, primaryColor, textColor, subtleColor),
          const SizedBox(height: 32),

          // Clean play button
          _buildCleanPlayButton(primaryColor),
          const SizedBox(height: 16),

          // Clean knowledge section
          _buildCleanKnowledgeSection(
            isDark,
            primaryColor,
            textColor,
            subtleColor,
          ),
          const SizedBox(height: 16),

          // Simple back button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '← Back to Games',
              style: TextStyle(color: subtleColor, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCleanSeasonSection(
    bool isDark,
    Color primary,
    Color textColor,
    Color subtleColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The 6 Seasons',
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
            itemCount: _ritus.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final ritu = _ritus[i];
              return Container(
                width: 85,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.parchment.withValues(alpha: 0.05)
                          : ritu.colorLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark
                            ? AppColors.parchment.withValues(alpha: 0.1)
                            : ritu.colorDark.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(ritu.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      ritu.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      ritu.months,
                      style: TextStyle(fontSize: 8, color: subtleColor),
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

  Widget _buildCleanDescription(
    bool isDark,
    Color primary,
    Color textColor,
    Color subtleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.03)
                : primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Master Seasonal Farming',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Plan your crops according to the 6 Hindu seasons. Manage resources, survive weather events, and harvest wisdom!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subtleColor, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSimpleFeature('🌾', '6 Seasons', subtleColor),
              _buildSimpleFeature('🌦️', 'Weather', subtleColor),
              _buildSimpleFeature('📚', 'Wisdom', subtleColor),
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
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
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
              color: primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: AppColors.parchment,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Start Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.parchment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanKnowledgeSection(
    bool isDark,
    Color primary,
    Color textColor,
    Color subtleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.03)
                : primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : primary.withValues(alpha: 0.1),
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
            '🌞 The Hindu calendar divides the year into 6 seasons, each lasting 2 months, based on natural agricultural cycles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subtleColor, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            '🌾 Traditional Indian farming aligns planting and harvesting with these seasonal patterns for optimal crop growth.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subtleColor, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showKnowledgeModal(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
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
      builder:
          (_) => AlertDialog(
            backgroundColor: isDark ? AppColors.parchment : AppColors.parchment,
            title: Text(
              'Seasonal Farming Wisdom',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.parchment : AppColors.parchment,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildKnowledgeItem(
                    '🌸 Vasanta (Spring)',
                    'March-April: Perfect for sowing summer crops like wheat, barley, and pulses. Temperature: 20-30°C',
                  ),
                  const SizedBox(height: 12),
                  _buildKnowledgeItem(
                    '☀️ Grishma (Summer)',
                    'May-June: Heat-loving crops thrive. Time for cotton, sugarcane, and rice transplantation. Temperature: 30-40°C',
                  ),
                  const SizedBox(height: 12),
                  _buildKnowledgeItem(
                    '🌧️ Varsha (Monsoon)',
                    'July-August: Peak planting season. Heavy rainfall supports rice, maize, and vegetable cultivation. Temperature: 25-30°C',
                  ),
                  const SizedBox(height: 12),
                  _buildKnowledgeItem(
                    '🍂 Sharad (Autumn)',
                    'September-October: Harvest time for kharif crops. Sowing of rabi crops begins. Temperature: 20-25°C',
                  ),
                  const SizedBox(height: 12),
                  _buildKnowledgeItem(
                    '❄️ Hemanta (Winter)',
                    'November-December: Cool season crops. Wheat, mustard, and peas grow well. Temperature: 10-20°C',
                  ),
                  const SizedBox(height: 12),
                  _buildKnowledgeItem(
                    '🌱 Shishira (Late Winter)',
                    'January-February: Peak harvest season. Preparation for next cycle begins. Temperature: 15-25°C',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: isDark ? AppColors.parchment : AppColors.charcoal,
                  ),
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
            color: AppColors.parchment,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.rawEarth54,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Enhanced animated logo with multiple effects
  Widget _buildEnhancedLogo(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnim,
        _rotateAnim,
        _glowAnim,
        _floatAnim,
      ]),
      builder:
          (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Outer glow effect only - no container background
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder:
                          (_, __) => DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.harvestAmber.withValues(
                                    alpha: _glowAnim.value * 0.4,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                  // Rotating seasonal wheel - glow only, no solid background
                  AnimatedBuilder(
                    animation: _rotateAnim,
                    builder:
                        (_, __) => Transform.rotate(
                          angle: _rotateAnim.value * 0.2,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.harvestAmber.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: AppColors.harvestAmber.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                  // Inner circle with sun
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.harvestAmber!,
                          AppColors.harvestAmber!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.parchment.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.harvestAmber.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('☀️', style: TextStyle(fontSize: 28)),
                          Text(
                            'ऋतु',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.rawEarth,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Floating season icons - glow only, no solid background
                  ...List.generate(6, (i) {
                    final angle = (i / 6) * math.pi * 2 - math.pi / 2;
                    final floatOffset =
                        math.sin(_floatAnim.value * math.pi * 2 + i) * 5;
                    return Positioned(
                      left: 80 + math.cos(angle) * 65 - 15 + floatOffset,
                      top: 80 + math.sin(angle) * 65 - 15 + floatOffset,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _ritus[i].colorDark.withValues(alpha: 0.6),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _ritus[i].emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
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
          animation: _shimmerAnim,
          builder:
              (_, __) => ShaderMask(
                shaderCallback:
                    (bounds) => LinearGradient(
                      colors: [
                        AppColors.harvestAmber.withValues(alpha: 0.8),
                        AppColors.harvestAmber.withValues(
                          alpha: _shimmerAnim.value.clamp(0, 1),
                        ),
                        AppColors.deepSoilGreen.withValues(alpha: 0.8),
                      ],
                    ).createShader(bounds),
                child: const Text(
                  '🌸 RITU CHAKRA 🌾',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.parchment,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _breatheAnim,
          builder:
              (_, __) => Transform.scale(
                scale: _breatheAnim.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rawEarth.withValues(alpha: 0.2),
                        AppColors.harvestAmber.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.rawEarth.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'The Eternal Wheel of Seasons',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.parchment70 : AppColors.charcoal54,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
        ),
      ],
    );
  }

  // Interactive season wheel
  Widget _buildInteractiveSeasonWheel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.harvestAmber.withValues(alpha: 0.15),
            AppColors.deepSoilGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.harvestAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🌍 THE SIX SEASONS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder:
                  (_, i) => _buildInteractiveSeasonCard(_ritus[i], isDark, i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSeasonCard(_Ritu ritu, bool isDark, int index) {
    return GestureDetector(
      onTap: () => _showSeasonKnowledge(ritu, isDark),
      child: AnimatedBuilder(
        animation: _breatheAnim,
        builder:
            (_, __) => Transform.scale(
              scale: _breatheAnim.value + (index % 2) * 0.02,
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ritu.colorLight.withValues(alpha: 0.4),
                      ritu.colorDark.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ritu.colorDark.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ritu.colorDark.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(ritu.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      ritu.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: ritu.colorDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      ritu.english,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.rawEarth54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ritu.colorDark.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tap to learn',
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.w700,
                          color: ritu.colorDark,
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

  // Enhanced game explanation with animations
  Widget _buildEnhancedGameExplanation(bool isDark) {
    return AnimatedBuilder(
      animation: _breatheAnim,
      builder:
          (_, __) => Transform.scale(
            scale: _breatheAnim.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.deepSoilGreen.withValues(alpha: 0.15),
                    AppColors.deepSoilGreen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.deepSoilGreen,
                              AppColors.deepSoilGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🎮', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'MASTER THE WHEEL OF SEASONS',
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
                    'Become a master farmer by understanding ancient Indian seasonal wisdom. Plant crops according to Ritu, manage resources wisely, and survive 3 years to achieve mastery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.parchment70 : AppColors.charcoal54,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniFeature(
                        '🌾',
                        '6 Seasons',
                        AppColors.deepSoilGreen,
                      ),
                      _buildMiniFeature(
                        '💧',
                        'Resource Mgt',
                        AppColors.deepSoilGreen,
                      ),
                      _buildMiniFeature(
                        '🏆',
                        '3 Year Goal',
                        AppColors.harvestAmber,
                      ),
                      _buildMiniFeature(
                        '📚',
                        'Ancient Wisdom',
                        AppColors.harvestAmber,
                      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  // Interactive season cards with knowledge
  Widget _buildInteractiveSeasonCards(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.harvestAmber.withValues(alpha: 0.15),
            AppColors.rawEarth.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.harvestAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🌱 EXPLORE SEASONAL WISDOM',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (_, i) => _buildSeasonKnowledgeCard(_ritus[i], isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonKnowledgeCard(_Ritu ritu, bool isDark) {
    return GestureDetector(
      onTap: () => _showSeasonKnowledge(ritu, isDark),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder:
            (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ritu.colorLight.withValues(alpha: 0.3),
                      ritu.colorDark.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ritu.colorDark.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ritu.colorDark.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(ritu.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      ritu.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: ritu.colorDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      ritu.months,
                      style: const TextStyle(
                        fontSize: 7,
                        color: AppColors.rawEarth54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // Enhanced how to play section
  Widget _buildEnhancedHowToPlay(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepSoilGreen.withValues(alpha: 0.15),
            AppColors.deepSoilGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '📋 FARMER\'S GUIDE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildEnhancedStep(
            '1️⃣',
            'SELECT CROP',
            'Choose crops that match current season for best growth',
            AppColors.deepSoilGreen,
            isDark,
          ),
          _buildEnhancedStep(
            '2️⃣',
            'PLANT SEEDS',
            'Tap empty plots to plant. Each crop costs 5 seeds',
            AppColors.rawEarth,
            isDark,
          ),
          _buildEnhancedStep(
            '3️⃣',
            'CARE DAILY',
            'Water and fertilize crops. Manage energy wisely',
            AppColors.deepSoilGreen,
            isDark,
          ),
          _buildEnhancedStep(
            '4️⃣',
            'HARVEST',
            'Collect crops when golden. Gain seeds and experience',
            AppColors.harvestAmber,
            isDark,
          ),
          _buildEnhancedStep(
            '5️⃣',
            'SURVIVE',
            'Complete 3 years. Adapt to each season\'s challenges',
            AppColors.harvestAmber,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStep(
    String num,
    String title,
    String desc,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _breatheAnim,
        builder:
            (_, __) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        num,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
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
                          desc,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isDark
                                    ? AppColors.parchment60
                                    : AppColors.charcoal54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            AppColors.harvestAmber.withValues(alpha: 0.15),
            AppColors.harvestAmber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.harvestAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.harvestAmber, AppColors.harvestAmber],
                  ),
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
            'Learn traditional Indian agricultural practices passed down through generations. Each Ritu holds sacred knowledge about sustainable farming.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWisdomPillar(
                '🌾',
                'Sacred Crops',
                'Traditional varieties with spiritual significance',
              ),
              _buildWisdomPillar(
                '💧',
                'Water Harmony',
                'Ancient techniques for water conservation',
              ),
              _buildWisdomPillar(
                '🙏',
                'Lunar Farming',
                'Following cosmic cycles for planting',
              ),
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
              AppColors.harvestAmber.withValues(alpha: 0.1),
              AppColors.harvestAmber.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.harvestAmber.withValues(alpha: 0.2),
          ),
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
                color: AppColors.harvestAmber,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(fontSize: 7, color: AppColors.rawEarth54),
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
      animation: _pulseAnim,
      builder:
          (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: GestureDetector(
              onTap: _startGame,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.parchment,
                      AppColors.parchment,
                      AppColors.parchment,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepSoilGreen.withValues(alpha: 0.6),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.parchment,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'BEGIN YOUR JOURNEY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.parchment,
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
        animation: _shimmerAnim,
        builder:
            (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.deepSoilGreen.withValues(alpha: 0.2),
                    AppColors.deepSoilGreen.withValues(
                      alpha: 0.1 + _shimmerAnim.value * 0.1,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
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
                      color: AppColors.deepSoilGreen,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // Show season knowledge modal
  void _showSeasonKnowledge(_Ritu ritu, bool isDark) {
    _haptic('medium');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (_) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? AppColors.parchment : AppColors.parchment,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header with season info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ritu.colorLight.withValues(alpha: 0.3),
                          ritu.colorDark.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ritu.colorDark.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ritu.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.rawEarth.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.rawEarth.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: AppColors.rawEarth,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ritu.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: ritu.colorDark,
                          ),
                        ),
                        Text(
                          ritu.english,
                          style: TextStyle(
                            fontSize: 14,
                            color: ritu.colorDark.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          ritu.months,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.rawEarth54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Knowledge content
                  _buildKnowledgeSection(ritu.knowledge, isDark),
                  const SizedBox(height: 20),

                  // Festivals
                  _buildFestivalsSection(
                    ritu.festivals,
                    ritu.colorDark,
                    isDark,
                  ),
                  const SizedBox(height: 20),

                  // Traditional tips
                  _buildTipsSection(
                    ritu.traditionalTips,
                    ritu.colorDark,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Show complete knowledge modal
  void _showCompleteKnowledge(bool isDark) {
    _haptic('medium');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (_) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: isDark ? AppColors.parchment : AppColors.parchment,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                            color: AppColors.rawEarth.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.rawEarth.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.rawEarth,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // All seasons knowledge
                  ...List.generate(6, (i) {
                    final ritu = _ritus[i];
                    return Column(
                      children: [
                        _buildCompactSeasonCard(ritu, isDark),
                        if (i < 5) const SizedBox(height: 16),
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
            AppColors.deepSoilGreen.withValues(alpha: 0.1),
            AppColors.deepSoilGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌱 Agricultural Knowledge',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.deepSoilGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            knowledge,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFestivalsSection(
    List<String> festivals,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎉 Seasonal Festivals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...festivals.map(
            (festival) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      festival,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.parchment70
                                : AppColors.charcoal54,
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
  }

  Widget _buildTipsSection(List<String> tips, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.harvestAmber.withValues(alpha: 0.1),
            AppColors.harvestAmber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.harvestAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Traditional Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.harvestAmber,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.harvestAmber,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.parchment70
                                : AppColors.charcoal54,
                        height: 1.4,
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
  }

  Widget _buildCompactSeasonCard(_Ritu ritu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ritu.colorLight.withValues(alpha: 0.2),
            ritu.colorDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ritu.colorDark.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ritu.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ritu.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ritu.colorDark,
                      ),
                    ),
                    Text(
                      '${ritu.english} • ${ritu.months}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.rawEarth54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ritu.description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tutorialSection(
    String title,
    String content,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOldMenu(bool isDark) {
    // Keep as fallback
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),

          // Epic animated logo
          AnimatedBuilder(
            animation: _pulseAnim,
            builder:
                (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating seasonal wheel
                      AnimatedBuilder(
                        animation: _sunAnim,
                        builder:
                            (_, __) => Transform.rotate(
                              angle: _sunAnim.value * 0.1,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors:
                                        _ritus.map((r) => r.colorLight).toList()
                                          ..add(_ritus[0].colorLight),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.harvestAmber.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                      // Inner circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.harvestAmber!,
                              AppColors.harvestAmber!,
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.parchment.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.charcoal.withValues(alpha: 0.2),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('☀️', style: TextStyle(fontSize: 40)),
                              Text(
                                'ऋतु',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.rawEarth,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Season icons around
                      ...List.generate(6, (i) {
                        final angle = (i / 6) * math.pi * 2 - math.pi / 2;
                        return Positioned(
                          left: 80 + math.cos(angle) * 85 - 15,
                          top: 80 + math.sin(angle) * 85 - 15,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _ritus[i].colorDark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.parchment,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _ritus[i].colorDark.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _ritus[i].emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        );
                      }),
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
              'RITU CHAKRA',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: AppColors.parchment,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback:
                (bounds) => const LinearGradient(
                  colors: [AppColors.parchment, AppColors.parchment],
                ).createShader(bounds),
            child: const Text(
              'The Wheel of Seasons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.parchment,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.deepSoilGreen.withValues(alpha: 0.2),
                  AppColors.harvestAmber.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              '🌾 Master Traditional Seasonal Farming 🌾',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.deepSoilGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats card
          _buildGlassCard([
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBubble(
                  '🏆',
                  'Best',
                  '$_highScore',
                  AppColors.harvestAmber,
                ),
                _buildStatBubble(
                  '🪙',
                  'Coins',
                  '$_coins',
                  AppColors.harvestAmber,
                ),
                _buildStatBubble(
                  '📚',
                  'Wisdom',
                  '$_wisdom',
                  AppColors.harvestAmber,
                ),
              ],
            ),
          ], isDark),
          const SizedBox(height: 16),

          // Season cards
          const Text(
            'THE 6 RITUS (SEASONS)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (_, i) => _buildSeasonCard(_ritus[i], isDark),
            ),
          ),
          const SizedBox(height: 24),

          // Play button
          _buildPremiumButton(
            '🌱  START FARMING',
            AppColors.parchment,
            _startGame,
            large: true,
          ),
          const SizedBox(height: 16),

          // Info card
          _buildGlassCard([
            const Row(
              children: [
                Text('📖', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '• Plant crops that match the current season\n'
              '• Water and fertilize for better growth\n'
              '• Harvest when ready, manage resources\n'
              '• Survive 3 years to master the Ritu Chakra!',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
                height: 1.5,
              ),
            ),
          ], isDark),
          const SizedBox(height: 16),

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

  Widget _buildSeasonCard(_Ritu ritu, bool isDark) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ritu.colorLight.withValues(alpha: 0.4),
            ritu.colorDark.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ritu.colorDark.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: ritu.colorDark.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(ritu.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            ritu.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ritu.colorDark,
            ),
          ),
          Text(
            ritu.english,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? AppColors.parchment54 : AppColors.charcoal38,
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
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 4),
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
          style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // ==================== GAME SCREEN ====================
  Widget _buildGameScreen(bool isDark, Size size) {
    final ritu = _ritus[_currentRitu];

    return Column(
      children: [
        // Top HUD
        _buildGameHUD(isDark, ritu),

        // Main game area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                // Season info banner
                _buildSeasonBanner(ritu, isDark),
                const SizedBox(height: 10),

                // Resources bar
                _buildResourcesBar(isDark),
                const SizedBox(height: 10),

                // Farm grid
                _buildFarmGrid(isDark),
                const SizedBox(height: 10),

                // Crop selection
                _buildCropSelection(isDark),
                const SizedBox(height: 10),

                // Action buttons
                _buildActionButtons(isDark),
                const SizedBox(height: 10),

                // Notifications
                if (_notifications.isNotEmpty) _buildNotifications(isDark),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameHUD(bool isDark, _Ritu ritu) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ritu.colorDark.withValues(alpha: 0.8),
            ritu.colorLight.withValues(alpha: 0.4),
            AppColors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                color: AppColors.charcoal26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppColors.parchment,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Year $_year • Day $_dayInRitu/60',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.parchment,
                ),
              ),
              Text(
                '${ritu.emoji} ${ritu.name}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.parchment.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildHudChip('⭐', '$_score', AppColors.harvestAmber),
          const SizedBox(width: 6),
          _buildHudChip('🌾', '$_harvest', AppColors.deepSoilGreen),
          const SizedBox(width: 6),
          _buildHudChip('🪙', '$_coins', AppColors.harvestAmber),
        ],
      ),
    );
  }

  Widget _buildHudChip(String emoji, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.charcoal26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonBanner(_Ritu ritu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ritu.colorLight.withValues(alpha: 0.3),
            ritu.colorDark.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ritu.colorDark.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(ritu.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ritu.name} (${ritu.english})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ritu.colorDark,
                  ),
                ),
                Text(
                  ritu.months,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isDark ? AppColors.parchment54 : AppColors.charcoal38,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ritu.description,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isDark ? AppColors.parchment70 : AppColors.charcoal54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.08,
            ),
            AppColors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildResourceGauge('💧', 'Water', _water, AppColors.deepSoilGreen),
          _buildResourceGauge('🌱', 'Seeds', _seeds, AppColors.deepSoilGreen),
          _buildResourceGauge('💩', 'Fert', _fertilizer, AppColors.rawEarth),
          _buildResourceGauge('⚡', 'Energy', _energy, AppColors.harvestAmber),
        ],
      ),
    );
  }

  Widget _buildResourceGauge(
    String emoji,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 3),
        Container(
          width: 50,
          height: 6,
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
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmGrid(bool isDark) {
    final hasSelectedCrop = _selectedCrop != null;
    final hasReadyHarvest = _farmGrid.any(
      (row) => row.any((p) => p.isReadyToHarvest),
    );

    return Column(
      children: [
        // Hint text
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (hasReadyHarvest
                    ? AppColors.harvestAmber
                    : (hasSelectedCrop
                        ? AppColors.deepSoilGreen
                        : AppColors.deepSoilGreen))
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            hasReadyHarvest
                ? '✨ TAP GOLDEN CROPS TO HARVEST!'
                : hasSelectedCrop
                ? '👆 TAP AN EMPTY PLOT TO PLANT'
                : '👇 SELECT A CROP BELOW FIRST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  hasReadyHarvest
                      ? AppColors.harvestAmber
                      : (hasSelectedCrop
                          ? AppColors.deepSoilGreen
                          : AppColors.deepSoilGreen),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.rawEarth.withValues(alpha: 0.2),
                AppColors.deepSoilGreen.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.rawEarth.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.rawEarth.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              for (int y = 0; y < 4; y++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int x = 0; x < 5; x++) _buildPlot(x, y, isDark),
                  ],
                ),
            ],
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('🟫', 'Empty', AppColors.rawEarth),
              _legendItem('💧', 'Watered', AppColors.deepSoilGreen),
              _legendItem('✨', 'Ready!', AppColors.harvestAmber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(String emoji, String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlot(int x, int y, bool isDark) {
    final plot = _farmGrid[y][x];
    final hasCrop = plot.crop != null;
    Color plotColor = AppColors.rawEarth!;
    String displayEmoji = '🟫';

    if (hasCrop) {
      final crop = _crops.firstWhere((c) => c.id == plot.crop);
      displayEmoji = crop.emoji;
      plotColor = crop.color;

      if (plot.isReadyToHarvest) {
        plotColor = AppColors.harvestAmber;
      }
    }

    return GestureDetector(
      onTap: () {
        if (plot.isReadyToHarvest) {
          _harvestPlot(x, y);
        } else if (!hasCrop && _selectedCrop != null) {
          _plantCrop(x, y, _selectedCrop!);
        }
      },
      onLongPress: () {
        if (hasCrop && !plot.isReadyToHarvest) {
          _showPlotMenu(x, y, isDark);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 58,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              plotColor.withValues(alpha: 0.6),
              plotColor.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                plot.isReadyToHarvest
                    ? AppColors.harvestAmber
                    : (plot.isWatered
                            ? AppColors.deepSoilGreen
                            : AppColors.rawEarth)
                        .withValues(alpha: 0.5),
            width: plot.isReadyToHarvest ? 3 : 2,
          ),
          boxShadow:
              plot.isReadyToHarvest
                  ? [
                    BoxShadow(
                      color: AppColors.harvestAmber.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                  : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(displayEmoji, style: TextStyle(fontSize: hasCrop ? 24 : 16)),
            if (hasCrop && !plot.isReadyToHarvest)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (plot.growth / 100).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.deepSoilGreen,
                            AppColors.deepSoilGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            if (plot.isWatered)
              const Positioned(
                top: 2,
                right: 2,
                child: Text('💧', style: TextStyle(fontSize: 10)),
              ),
            if (plot.isFertilized)
              const Positioned(
                top: 2,
                left: 2,
                child: Text('✨', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }

  String? _selectedCrop;

  Widget _buildCropSelection(bool isDark) {
    final ritu = _ritus[_currentRitu];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🌱 SELECT CROP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⭐ = Best for this season!',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepSoilGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _crops.length,
            itemBuilder: (_, i) {
              final crop = _crops[i];
              final isIdeal = crop.idealSeasons.contains(ritu.id);
              final isSelected = _selectedCrop == crop.id;

              return GestureDetector(
                onTap: () {
                  _haptic('select');
                  setState(() => _selectedCrop = isSelected ? null : crop.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 65,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isSelected
                              ? [
                                crop.color.withValues(alpha: 0.5),
                                crop.color.withValues(alpha: 0.3),
                              ]
                              : [
                                crop.color.withValues(alpha: 0.2),
                                crop.color.withValues(alpha: 0.1),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected
                              ? crop.color
                              : crop.color.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: crop.color.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ]
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(crop.emoji, style: const TextStyle(fontSize: 20)),
                      Text(
                        crop.name,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: crop.color,
                        ),
                      ),
                      if (isIdeal)
                        const Text('⭐', style: TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPlotMenu(int x, int y, bool isDark) {
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
                const Text(
                  '🌿 PLOT ACTIONS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlotAction(
                      '💧',
                      'Water',
                      AppColors.deepSoilGreen,
                      () {
                        Navigator.pop(context);
                        _waterPlot(x, y);
                      },
                    ),
                    _buildPlotAction('💩', 'Fertilize', AppColors.rawEarth, () {
                      Navigator.pop(context);
                      _fertilizePlot(x, y);
                    }),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPlotAction(
    String emoji,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            '☀️',
            'Next Day',
            AppColors.harvestAmber,
            _advanceDay,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            '😴',
            'Rest (+3 days)',
            AppColors.harvestAmber,
            _rest,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            '🛒',
            'Shop',
            AppColors.deepSoilGreen,
            () => _showShop(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
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
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.parchment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShop(bool isDark) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🛒 SHOP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '🪙 $_coins',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.harvestAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShopItem(
                      '🌱',
                      'Seeds',
                      '+20',
                      AppColors.deepSoilGreen,
                      () => _buyResources('seeds'),
                    ),
                    _buildShopItem(
                      '💩',
                      'Fertilizer',
                      '+15',
                      AppColors.rawEarth,
                      () => _buyResources('fertilizer'),
                    ),
                    _buildShopItem(
                      '💧',
                      'Water',
                      '+30',
                      AppColors.deepSoilGreen,
                      () => _buyResources('water'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Each item costs 10 coins',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.parchment54 : AppColors.charcoal38,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildShopItem(
    String emoji,
    String name,
    String bonus,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              bonus,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '🪙 10',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.harvestAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifications(bool isDark) {
    return Column(
      children:
          _notifications
              .take(3)
              .map(
                (n) => Opacity(
                  opacity: n.life.clamp(0, 1),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      n.message,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.parchment,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
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
                    child: const Text('🏆', style: TextStyle(fontSize: 80)),
                  ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    colors: [AppColors.harvestAmber, AppColors.harvestAmber],
                  ).createShader(bounds),
              child: const Text(
                'MASTER FARMER!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.parchment,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You mastered the Ritu Chakra in $_year years!',
              style: TextStyle(
                color: isDark ? AppColors.parchment60 : AppColors.charcoal45,
              ),
            ),
            const SizedBox(height: 24),

            _buildGlassCard([
              _buildStatRow(
                '⭐',
                'Final Score',
                '$_score',
                AppColors.harvestAmber,
                isDark,
              ),
              _buildStatRow(
                '🌾',
                'Total Harvest',
                '$_harvest',
                AppColors.deepSoilGreen,
                isDark,
              ),
              _buildStatRow(
                '📚',
                'Wisdom Gained',
                '$_wisdom',
                AppColors.harvestAmber,
                isDark,
              ),
              _buildStatRow(
                '🪙',
                'Coins Earned',
                '$_coins',
                AppColors.harvestAmber,
                isDark,
              ),
            ], isDark),
            const SizedBox(height: 24),

            _buildPremiumButton(
              '🔄 Play Again',
              AppColors.deepSoilGreen,
              _startGame,
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

  // ==================== SHARED WIDGETS ====================
  Widget _buildGlassCard(List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.1,
            ),
            (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
              alpha: 0.03,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.charcoal).withValues(
            alpha: 0.1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal54,
              ),
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
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: large ? 18 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(large ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: large ? 18 : 12,
              offset: Offset(0, large ? 8 : 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: large ? 17 : 14,
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

enum GamePhase { menu, playing, victory }

class _Ritu {
  final String id;
  final String name;
  final String emoji;
  final String english;
  final Color colorLight;
  final Color colorDark;
  final String months;
  final String description;
  final String knowledge;
  final List<String> festivals;
  final List<String> traditionalTips;

  const _Ritu(
    this.id,
    this.name,
    this.emoji,
    this.english,
    this.colorLight,
    this.colorDark,
    this.months,
    this.description, {
    required this.knowledge,
    required this.festivals,
    required this.traditionalTips,
  });
}

class _Crop {
  final String id, emoji, name;
  final List<String> idealSeasons;
  final int growthDays, baseYield;
  final Color color;
  const _Crop(
    this.id,
    this.emoji,
    this.name,
    this.idealSeasons,
    this.growthDays,
    this.baseYield,
    this.color,
  );
}

class _Plot {
  final int x, y;
  String? crop;
  double growth = 0;
  int daysPlanted = 0;
  bool isWatered = false;
  bool isFertilized = false;
  bool isHarvested = false;
  bool isReadyToHarvest = false;
  _Plot({required this.x, required this.y});
}

class _Event {
  final String id, emoji, name, description;
  final VoidCallback effect;
  _Event(this.id, this.emoji, this.name, this.description, this.effect);
}

class _Particle {
  double x, y, vx, vy, life;
  final Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
  });
}

class _WeatherParticle {
  double x, y, vx, vy;
  final String type;
  _WeatherParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.type,
  });
}

class _Notification {
  final String message;
  double life;
  _Notification({required this.message, required this.life});
}

// ==================== CUSTOM PAINTER ====================
class _SeasonBackgroundPainter extends CustomPainter {
  final _Ritu ritu;
  final double progress;
  final bool isDark;

  _SeasonBackgroundPainter({
    required this.ritu,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);

    // Seasonal elements
    for (int i = 0; i < 15; i++) {
      final x = (rand.nextDouble() + progress * 0.2) % 1.0 * size.width;
      final y = rand.nextDouble() * size.height;
      final elemSize = rand.nextDouble() * 20 + 10;

      paint.color = ritu.colorLight.withValues(
        alpha: rand.nextDouble() * 0.1 + 0.03,
      );
      canvas.drawCircle(Offset(x, y), elemSize, paint);
    }

    // Ground
    paint
      ..color = AppColors.rawEarth.withValues(alpha: isDark ? 0.15 : 0.1)
      ..style = PaintingStyle.fill;

    final groundPath = Path();
    groundPath.moveTo(0, size.height * 0.85);
    for (double x = 0; x <= size.width; x += 30) {
      groundPath.lineTo(
        x,
        size.height * 0.85 + math.sin((x + progress * 100) * 0.02) * 10,
      );
    }
    groundPath.lineTo(size.width, size.height);
    groundPath.lineTo(0, size.height);
    groundPath.close();
    canvas.drawPath(groundPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SeasonBackgroundPainter old) =>
      old.progress != progress || old.ritu.id != ritu.id;
}
