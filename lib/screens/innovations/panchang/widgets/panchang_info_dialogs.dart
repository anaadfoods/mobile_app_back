import 'package:grocery_app/common_widgets/global_import.dart';

class PanchangInfoDialogs {
  static void showInauspiciousInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rawEarth.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.rawEarth.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.rawEarth, AppColors.rawEarth],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Inauspicious Timings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  'Understanding unfavorable periods',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoSection(
                            icon: Icons.dangerous_rounded,
                            title: 'Rahu Kaal',
                            color: AppColors.rawEarth,
                            description:
                                'Rahu Kaal is considered the most inauspicious time of the day. According to Vedic astrology, Rahu is a shadow planet that brings obstacles, delays, and negative outcomes. Any new venture started during this period may face unexpected hurdles.',
                            tips: [
                              'Avoid starting new businesses',
                              'Not recommended for travel',
                              'Skip signing important contracts',
                              'Avoid major purchases',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.block_rounded,
                            title: 'Gulika Kaal',
                            color: AppColors.harvestAmber,
                            description:
                                'Gulika (also known as Mandi) is the son of Saturn and represents a highly malefic period. Activities begun during Gulika Kaal may lead to illness, loss, or failure.',
                            tips: [
                              'Avoid medical treatments',
                              'Not suitable for finance',
                              'Skip educational pursuits',
                              'Avoid initiating relationships',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.report_problem_rounded,
                            title: 'Yamaganda Kaal',
                            color: AppColors.rawEarth,
                            description:
                                'Yamaganda means "danger of Yama" (the god of death). Activities started during this time may lead to accidents or health issues.',
                            tips: [
                              'Strictly avoid travel',
                              'No risky activities',
                              'Avoid important ceremonies',
                              'Not suitable for construction',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.harvestAmber.withValues(
                                alpha: isDark ? 0.15 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.harvestAmber.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.harvestAmber,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AutoSizeText(
                                    'Tip: Routine activities and ongoing work can continue during these periods. Only avoid starting new important tasks.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.harvestAmber
                                          : AppColors.harvestAmber,
                                    ),
                                  ),
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
          ),
    );
  }

  static void showAuspiciousInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Auspicious Timings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  'Sacred windows of opportunity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoSection(
                            icon: Icons.wb_twilight_rounded,
                            title: 'Brahma Muhurat',
                            color: AppColors.harvestAmber,
                            description:
                                'Brahma Muhurat literally means "the creator\'s time" and occurs approximately 1 hour 36 minutes before sunrise. This is the most spiritually powerful time for meditation and prayer.',
                            tips: [
                              'Ideal for meditation and yoga',
                              'Best for studying scriptures',
                              'Perfect for spiritual practices',
                              'Enhanced clarity for decisions',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.star_rounded,
                            title: 'Abhijit Muhurat',
                            color: AppColors.harvestAmber,
                            description:
                                'Abhijit Muhurat is the "victorious moment" occurring around midday. It\'s so auspicious that it nullifies all doshas (defects). Lord Krishna was born during this muhurat.',
                            tips: [
                              'Perfect for new ventures',
                              'Excellent for important meetings',
                              'Ideal for signing contracts',
                              'Best for beginning journeys',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.sunny,
                            title: 'Sunrise (Suryodaya)',
                            color: AppColors.harvestAmber,
                            description:
                                'The moment of sunrise is highly auspicious. The first rays of the sun carry healing energy and divine blessings. Morning prayers at this time are especially powerful.',
                            tips: [
                              'Offer water to the Sun',
                              'Practice Surya Namaskar',
                              'Begin your day with gratitude',
                              'Set intentions for the day',
                            ],
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  static void showMasaInfoDialog(
    BuildContext context,
    String currentMasa,
    bool isDark,
  ) {
    final masaInfo = {
      'Chaitra': {
        'month': 'March-April',
        'deity': 'Vishnu',
        'significance':
            'Start of Hindu New Year (Vikram Samvat). Chaitra Navratri begins.',
      },
      'Vaishakha': {
        'month': 'April-May',
        'deity': 'Madhusudana',
        'significance':
            'Buddha Purnima, Akshaya Tritiya. Best for charity and new beginnings.',
      },
      'Jyeshtha': {
        'month': 'May-June',
        'deity': 'Trivikrama',
        'significance': 'Ganga Dussehra, Nirjala Ekadashi. Summer heat peaks.',
      },
      'Ashadha': {
        'month': 'June-July',
        'deity': 'Vamana',
        'significance': 'Guru Purnima, start of Chaturmas. Monsoon begins.',
      },
      'Shravana': {
        'month': 'July-August',
        'deity': 'Sridhara',
        'significance':
            'Shravan Somvar, Raksha Bandhan, Janmashtami. Very auspicious month.',
      },
      'Bhadrapada': {
        'month': 'August-September',
        'deity': 'Hrishikesha',
        'significance':
            'Ganesh Chaturthi, Anant Chaturdashi, Pitru Paksha begins.',
      },
      'Ashwin': {
        'month': 'September-October',
        'deity': 'Padmanabha',
        'significance':
            'Sharad Navratri, Durga Puja, Dussehra. Festival season begins.',
      },
      'Kartik': {
        'month': 'October-November',
        'deity': 'Damodara',
        'significance':
            'Diwali, Govardhan Puja, Tulsi Vivah. Most sacred month for Vaishnavites.',
      },
      'Margashirsha': {
        'month': 'November-December',
        'deity': 'Keshava',
        'significance':
            'Gita Jayanti, Mokshada Ekadashi. Lord Krishna\'s favorite month.',
      },
      'Pausha': {
        'month': 'December-January',
        'deity': 'Narayana',
        'significance': 'Makar Sankranti, Lohri. Winter solstice period.',
      },
      'Magha': {
        'month': 'January-February',
        'deity': 'Madhava',
        'significance': 'Vasant Panchami, Maha Shivaratri. Spring begins.',
      },
      'Phalguna': {
        'month': 'February-March',
        'deity': 'Govinda',
        'significance': 'Holi, Holika Dahan. End of Hindu calendar year.',
      },
    };

    final info =
        masaInfo[currentMasa] ??
        {
          'month': 'Hindu Lunar Month',
          'deity': 'Vishnu',
          'significance':
              'Each month is associated with specific festivals and rituals.',
        };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.rawEarth54.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isDark
                              ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                              : [
                                  AppColors.deepSoilGreen,
                                  const Color(0xFF3A6B24),
                                ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.parchment.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AutoSizeText(
                          '📅',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              '$currentMasa Masa',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppColors.pureWhite
                                        : AppColors.parchment,
                              ),
                            ),
                            AutoSizeText(
                              'Hindu Lunar Month (मास)',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.parchment.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              isDark
                                  ? AppColors.pureWhite
                                  : AppColors.parchment,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.calendar_month,
                          'Gregorian Period',
                          info['month']!,
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.temple_hindu,
                          'Presiding Deity',
                          info['deity']!,
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.auto_awesome,
                          'Significance',
                          info['significance']!,
                          isDark,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2C4A1E,
                            ).withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.parchment.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                '💡 What is Masa?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.pureWhite
                                          : AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AutoSizeText(
                                'Masa (मास) is the Hindu lunar month. There are 12 months in a lunar year, each named after the Nakshatra in which the full moon occurs. The Hindu calendar follows either Amanta (month ends on New Moon) or Purnimanta (month ends on Full Moon) system.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isDark
                                          ? AppColors.pureWhite.withValues(
                                            alpha: 0.54,
                                          )
                                          : AppColors.charcoal54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  static void showPakshaInfoDialog(
    BuildContext context,
    String currentPaksha,
    bool isDark,
  ) {
    final isKrishna = currentPaksha.toLowerCase().contains('krishna');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.rawEarth54.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isKrishna
                              ? isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ]
                              : isDark
                              ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                              : [
                                  AppColors.deepSoilGreen,
                                  const Color(0xFF3A6B24),
                                ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.parchment.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AutoSizeText(
                          isKrishna ? '🌑' : '🌕',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              '$currentPaksha Paksha',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color:
                                    isKrishna
                                        ? AppColors.parchment
                                        : AppColors.charcoal,
                              ),
                            ),
                            AutoSizeText(
                              isKrishna
                                  ? 'Dark Fortnight (कृष्ण पक्ष)'
                                  : 'Bright Fortnight (शुक्ल पक्ष)',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isKrishna
                                        ? AppColors.parchment.withValues(
                                          alpha: 0.8,
                                        )
                                        : AppColors.charcoal54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              isKrishna
                                  ? AppColors.parchment
                                  : AppColors.charcoal54,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isKrishna
                                      ? [
                                        const Color(0xFF0D1A10).withValues(alpha: 0.5),
                                        const Color(0xFF143318).withValues(alpha: 0.3),
                                      ]
                                      : [
                                        AppColors.parchment,
                                        const Color(0xFFFDE68A).withValues(alpha: 0.5),
                                      ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children:
                                isKrishna
                                    ? [
                                      _buildMoonPhase(
                                        '🌕',
                                        'Purnima',
                                        'Day 1',
                                        isDark,
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌖',
                                        'Waning',
                                        'Day 5',
                                        isDark,
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌗',
                                        'Half',
                                        'Day 8',
                                        isDark,
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌑',
                                        'Amavasya',
                                        'Day 15',
                                        isDark,
                                      ),
                                    ]
                                    : [
                                      _buildMoonPhase(
                                        '🌑',
                                        'Amavasya',
                                        'Day 1',
                                        isDark,
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌒',
                                        'Waxing',
                                        'Day 5',
                                        isDark,
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌓',
                                        'Half',
                                        'Day 8',
                                        isDark,
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌕',
                                        'Purnima',
                                        'Day 15',
                                        isDark,
                                      ),
                                    ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          Icons.brightness_2,
                          'Moon Phase',
                          isKrishna
                              ? 'Waning Moon (decreasing light)'
                              : 'Waxing Moon (increasing light)',
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Duration',
                          '15 Tithis (lunar days)',
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.star,
                          'Ends On',
                          isKrishna
                              ? 'Amavasya (New Moon)'
                              : 'Purnima (Full Moon)',
                          isDark,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isKrishna
                                    ? AppColors.parchment
                                    : AppColors.parchment)
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (isKrishna
                                      ? AppColors.parchment
                                      : AppColors.parchment)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                isKrishna
                                    ? '🌙 Krishna Paksha Activities'
                                    : '☀️ Shukla Paksha Activities',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.pureWhite
                                          : AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(isKrishna
                                      ? [
                                        '✅ Pitru Tarpan (ancestral offerings)',
                                        '✅ Tantra Sadhana & occult practices',
                                        '✅ Completion of ongoing tasks',
                                        '✅ Introspection & meditation',
                                        '✅ Shraddha rituals',
                                        '❌ Avoid starting new ventures',
                                        '❌ Avoid marriages & griha pravesh',
                                      ]
                                      : [
                                        '✅ Starting new ventures',
                                        '✅ Marriages & auspicious ceremonies',
                                        '✅ Griha Pravesh (house warming)',
                                        '✅ Religious functions & yagnas',
                                        '✅ Buying property or vehicles',
                                        '✅ Starting education or business',
                                      ])
                                  .map(
                                    (text) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AutoSizeText(
                                        text,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              isDark
                                                  ? AppColors.pureWhite
                                                      .withValues(alpha: 0.54)
                                                  : AppColors.charcoal54,
                                        ),
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
              ],
            ),
          ),
    );
  }

  static void showPanchangInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Understanding Panchang',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  'The five limbs of Vedic time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2C4A1E,
                              ).withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: AutoSizeText(
                              'Panchang (पञ्चाङ्ग) literally means "five limbs" in Sanskrit. It is the ancient Vedic calendar system that tracks five essential elements of time that determine auspiciousness.',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDark
                                        ? AppColors.pureWhite.withValues(
                                          alpha: 0.54,
                                        )
                                        : AppColors.charcoal54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPanchangElementInfo(
                            icon: Icons.brightness_3,
                            title: 'Tithi (तिथि)',
                            subtitle: 'Lunar Day',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Tithi represents the lunar day based on the angle between the Sun and Moon. There are 30 Tithis in a lunar month.',
                            examples: 'Pratipada, Dvitiya, Amavasya, Purnima',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.stars_rounded,
                            title: 'Nakshatra (नक्षत्र)',
                            subtitle: 'Lunar Mansion',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Nakshatra is the lunar constellation where the Moon resides. There are 27 Nakshatras, each spanning 13°20\'.',
                            examples: 'Ashwini, Rohini, Pushya, Revati',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.self_improvement_rounded,
                            title: 'Yoga (योग)',
                            subtitle: 'Auspicious Combination',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Yoga is calculated from the combined longitude of Sun and Moon. There are 27 Yogas, each lasting about one day.',
                            examples: 'Siddhi, Amrita, Shobhana',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.change_history_rounded,
                            title: 'Karana (करण)',
                            subtitle: 'Half Tithi',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Karana is half of a Tithi. There are 11 Karanas. Vishti Karana (Bhadra) is considered inauspicious.',
                            examples: 'Bava, Balava, Vishti (inauspicious)',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.wb_sunny_rounded,
                            title: 'Vara (वार)',
                            subtitle: 'Weekday',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Vara is the day of the week, ruled by different planets. Each day has specific favorable activities.',
                            examples: 'Ravivara (Sun), Somavara (Mon)',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.brightness_2_rounded,
                            title: 'Paksha (पक्ष)',
                            subtitle: 'Lunar Fortnight',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Paksha divides the lunar month into two halves. Shukla (bright) for new beginnings, Krishna (dark) for completion.',
                            examples: 'Shukla Paksha, Krishna Paksha',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  static void showMoonRashiInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.nightlight_round,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Moon & Rashi',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AutoSizeText(
                                  'Lunar influence on daily life',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildMoonRashiSection(
                            icon: Icons.arrow_upward_rounded,
                            title: 'Moonrise (चन्द्रोदय)',
                            color: AppColors.harvestAmber,
                            description:
                                'Moonrise marks when the Moon becomes visible above the eastern horizon. The energy after moonrise is favorable for creativity and nurturing.',
                            significance: [
                              'Ideal for Moon worship',
                              'Favorable for creative endeavors',
                              'Important for Karva Chauth',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildMoonRashiSection(
                            icon: Icons.arrow_downward_rounded,
                            title: 'Moonset (चन्द्रास्त)',
                            color: AppColors.harvestAmber,
                            description:
                                'Moonset is when the Moon descends below the western horizon. Important for calculating lunar day transitions.',
                            significance: [
                              'Marks end of lunar visibility',
                              'Relevant for fasting observances',
                              'Affects meditation practices',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildMoonRashiSection(
                            icon: Icons.wb_sunny_rounded,
                            title: 'Sun Rashi (सूर्य राशि)',
                            color: AppColors.harvestAmber,
                            description:
                                'Sun Rashi indicates which zodiac sign the Sun is transiting. Determines solar months and Sankranti festivals.',
                            significance: [
                              'Determines solar months',
                              'Influences personality',
                              'Important for timing festivals',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildMoonRashiSection(
                            icon: Icons.nightlight_rounded,
                            title: 'Moon Rashi (चन्द्र राशि)',
                            color: AppColors.deepSoilGreen,
                            description:
                                'Moon Rashi shows which zodiac sign the Moon occupies. More important than Sun sign in Vedic astrology for emotions and mental well-being.',
                            significance: [
                              'Governs emotions',
                              'Determines Janma Rashi',
                              'Crucial for Muhurat selection',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF3F5E46).withValues(alpha: isDark ? 0.2 : 0.1),
                                  const Color(0xFF1A3D24).withValues(alpha: isDark ? 0.2 : 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lightbulb_outline,
                                      color: AppColors.parchment,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AutoSizeText(
                                        'The 12 Rashis (Zodiac Signs)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.parchment
                                              : AppColors.parchment,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    'Mesha (Aries)',
                                    'Vrishabha (Taurus)',
                                    'Mithuna (Gemini)',
                                    'Karka (Cancer)',
                                    'Simha (Leo)',
                                    'Kanya (Virgo)',
                                    'Tula (Libra)',
                                    'Vrishchika (Scorpio)',
                                    'Dhanu (Sagittarius)',
                                    'Makara (Capricorn)',
                                    'Kumbha (Aquarius)',
                                    'Meena (Pisces)',
                                  ]
                                      .map(
                                        (rashi) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3F5E46).withValues(
                                              alpha: isDark ? 0.2 : 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: AutoSizeText(
                                            rashi,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.parchment70
                                                  : const Color(0xFF1A3D24),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
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
          ),
    );
  }

  static Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Color color,
    required String description,
    required List<String> tips,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              AutoSizeText(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSizeText(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.pureWhite.withValues(alpha: 0.54)
                  : AppColors.charcoal54,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tips
                .map(
                  (tip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: color, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: AutoSizeText(
                            tip,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.pureWhite.withValues(
                                      alpha: 0.54,
                                    )
                                  : AppColors.charcoal54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static Widget _buildMoonPhase(String emoji, String label, String day, bool isDark) {
    return Column(
      children: [
        AutoSizeText(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        AutoSizeText(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.pureWhite.withValues(alpha: 0.54)
                : AppColors.charcoal54,
          ),
        ),
        AutoSizeText(
          day,
          style: TextStyle(
            fontSize: 9,
            color: isDark
                ? AppColors.pureWhite.withValues(alpha: 0.54)
                : AppColors.charcoal38,
          ),
        ),
      ],
    );
  }

  static Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.parchment.withValues(alpha: 0.1)
                : AppColors.rawEarth54.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.pureWhite.withValues(alpha: 0.54)
                : AppColors.charcoal54,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.pureWhite.withValues(alpha: 0.54)
                      : AppColors.charcoal45,
                ),
              ),
              const SizedBox(height: 2),
              AutoSizeText(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildPanchangElementInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String description,
    required String examples,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    AutoSizeText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSizeText(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.pureWhite.withValues(alpha: 0.54)
                  : AppColors.charcoal54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.format_list_bulleted, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: AutoSizeText(
                    examples,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.pureWhite.withValues(alpha: 0.60)
                          : AppColors.charcoal45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMoonRashiSection({
    required IconData icon,
    required String title,
    required Color color,
    required String description,
    required List<String> significance,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSizeText(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.pureWhite.withValues(alpha: 0.54)
                  : AppColors.charcoal54,
            ),
          ),
          const SizedBox(height: 12),
          ...significance.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AutoSizeText(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.pureWhite.withValues(alpha: 0.60)
                            : AppColors.charcoal45,
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
}
