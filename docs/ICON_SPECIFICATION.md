# Anaad Foods — Icon & Visual Asset Specification
**Modules:** Panchang (Vedic Calendar), Kundli (Jyotish), Chat (Aahar Vigyan & AI Health Memory)  
**Version:** 2.0  
**Target Architecture:** Flutter Clean Architecture Design System v2.0  

---

## 1. Design & Technical Standards

### 📐 Asset Specifications
| Property | Specification | Notes |
| :--- | :--- | :--- |
| **Format** | Vector `.svg` (Primary) / `.png` @ 3x | SVGs must be optimized (no embedded bitmaps). |
| **Standard Grid** | `24 × 24 dp` | Used for inline list items, chips, action buttons. |
| **Hero / Badge Grid** | `48 × 48 dp` or `64 × 64 dp` | Used for cards, onboarding sheets, category headers. |
| **Stroke Style** | Outlined / Dual-Tone | Uniform 1.5px to 2.0px stroke weight with rounded caps (`stroke-linecap="round"`). |
| **ViewBox** | `0 0 24 24` (or `0 0 48 48`) | Maintain centered geometry with 2px internal padding. |

### 🎨 Color Token Palette
```dart
// Primary Identity
AppColors.forest        = Color(0xFF1E4D2B); // Deep Soil / Ayurvedic Green
AppColors.gold          = Color(0xFFC88A2C); // Sacred Gold / Panchang Accent
AppColors.harvestAmber  = Color(0xFFE89D25); // Solar Amber Warmth

// Doshas & Astrological Elements
AppColors.vata          = Color(0xFF0288D1); // Air & Ether (Sky Blue)
AppColors.pitta         = Color(0xFFE65100); // Fire & Water (Flame Orange)
AppColors.kapha         = Color(0xFF2E7D32); // Earth & Water (Forest Green)
AppColors.jyotish       = Color(0xFF5B2C6F); // Planetary & Celestial (Royal Purple)
```

---

## 2. Panchang Module (Vedic Cosmic Rhythm & Daily Elements)

### A. The 5 Panchang Core Elements (*Pancha-Anga*)
| Asset ID | UI Key / File Name | Context | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `PCH_01` | `tithi.svg` | Daily Lunar Day | Crescent moon with waxing/waning phase aura rings. |
| `PCH_02` | `vara.svg` | Solar Weekday | Radiant 7-ray solar disc representing the planetary ruler of the day. |
| `PCH_03` | `nakshatra.svg` | Lunar Constellation | Cluster of 3 sparkling asterism stars forming a cosmic constellation. |
| `PCH_04` | `yoga.svg` | Angular Relationship | Two intersecting celestial orbit rings harmonizing at the center. |
| `PCH_05` | `karana.svg` | Half Tithi | Balanced dual-drop or Yin-Yang balance representing the half-lunar phase. |

### B. Solar & Lunar Timing Windows
| Asset ID | File Name | Context | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `SUN_01` | `sunrise.svg` | Surya Udaya | Sun emerging over horizon with upward rays. |
| `SUN_02` | `sunset.svg` | Surya Asta | Sun dipping below horizon with gentle dusk waves. |
| `MOON_01`| `moonrise.svg` | Chandra Udaya | Glowing crescent moon rising above the horizon line. |
| `MOON_02`| `moonset.svg` | Chandra Asta | Crescent moon sinking beneath the night horizon. |
| `MOON_03`| `purnima.svg` | Full Moon | Full circular moon with radiant luminous outer corona. |
| `MOON_04`| `amavasya.svg` | New Moon | Dark celestial sphere with subtle glowing eclipse halo. |

### C. Auspicious & Inauspicious Muhurtas
| Asset ID | File Name | Context | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `MUH_01` | `abhijit_muhurta.svg` | Midday Auspicious | Victorious sun emblem adorned with a golden crown / laurel. |
| `MUH_02` | `brahma_muhurta.svg` | Pre-Dawn Spiritual | Blooming lotus with the morning star rising above it. |
| `MUH_03` | `amrit_kalam.svg` | Nectar Window | Sacred Vedic Kalash (urn) with mango leaves pouring divine nectar. |
| `MUH_04` | `rahu_kalam.svg` | Inauspicious Window | Serpent head (Rahu) with cosmic eclipse shadow & caution badge. |
| `MUH_05` | `yamaganda_kalam.svg`| Obstacle Window | Protective shield paired with an hourglass / time indicator. |
| `MUH_06` | `gulika_kalam.svg` | Saturnian Window | Saturn planetary ring enclosing a clock dial. |
| `MUH_07` | `durmuhurtam.svg` | Unfavourable Time | Rounded caution triangle integrated with clock hands. |
| `MUH_08` | `varjyam.svg` | Avoidance Window | Crossed celestial circle denoting negative planetary rays. |

### D. The 6 Ritus (*Shad Ritu* — Seasonal Diet Transitions)
| Asset ID | File Name | Vedic Season | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `RTU_01` | `ritu_vasanta.svg` | Vasanta (Spring) | Fresh sprouting leaf shoot with blooming flower petal. |
| `RTU_02` | `ritu_grishma.svg` | Grishma (Summer) | Blazing summer sun paired with a traditional clay water vessel. |
| `RTU_03` | `ritu_varsha.svg` | Varsha (Monsoon) | Nimbus cloud with refreshing raindrops nourishing the soil. |
| `RTU_04` | `ritu_sharad.svg` | Sharad (Autumn) | Calming autumn sun with clear crisp atmospheric waves. |
| `RTU_05` | `ritu_hemanta.svg` | Hemanta (Pre-Winter) | Morning dewdrop resting on a grass blade with cool breeze lines. |
| `RTU_06` | `ritu_shishira.svg`| Shishira (Winter) | Delicate frost snowflake crystal beside a warm hearth flame. |

---

## 3. Kundli Module (Janam Kundli & Vedic Astrology)

### A. Navagraha (*The 9 Celestial Planets*)
| Asset ID | File Name | Planet & Sanskrit | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `GRA_01` | `graha_surya.svg` | Sun (*Surya*) | Royal solar disc with 12 distinct flames radiating outward. |
| `GRA_02` | `graha_chandra.svg`| Moon (*Chandra*) | Graceful silver crescent cradling a celestial drop. |
| `GRA_03` | `graha_mangal.svg` | Mars (*Mangal*) | Fiery spear/shield with a vibrant ruby-red core. |
| `GRA_04` | `graha_budha.svg` | Mercury (*Budha*) | Emerald green sprouting bud with winged intellectual motifs. |
| `GRA_05` | `graha_guru.svg` | Jupiter (*Guru / Brihaspati*) | Sacred golden conch (*Shankha*) with teacher’s tilak marking. |
| `GRA_06` | `graha_shukra.svg`| Venus (*Shukra*) | Radiant diamond facet combined with a lotus of beauty and luxury. |
| `GRA_07` | `graha_shani.svg` | Saturn (*Shani*) | Deep sapphire ringed planet surrounded by karmic orbit tracks. |
| `GRA_08` | `graha_rahu.svg` | Rahu (*North Node*) | Ascending smoke coil / celestial dragon head silhouette. |
| `GRA_09` | `graha_ketu.svg` | Ketu (*South Node*) | Spiritual victory flag (*Dhwaja*) / descending comet tail. |

### B. 12 Rashis (*Vedic Zodiac Signs*)
| Asset ID | File Name | Sign (Sanskrit / English) | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `RAS_01` | `rashi_mesha.svg` | Mesha (Aries) | Dynamic Ram horns curved in forward motion. |
| `RAS_02` | `rashi_vrishabha.svg` | Vrishabha (Taurus) | Sturdy Bull head silhouette with strong horns. |
| `RAS_03` | `rashi_mithuna.svg` | Mithuna (Gemini) | Harmonious twin pillars / dual faces in symmetry. |
| `RAS_04` | `rashi_karka.svg` | Karka (Cancer) | Protective Crab claws with a rhythmic ocean tide curve. |
| `RAS_05` | `rashi_simha.svg` | Simha (Leo) | Majestic Lion mane stylized into a royal solar crest. |
| `RAS_06` | `rashi_kanya.svg` | Kanya (Virgo) | Maiden silhouette holding a wholesome sheaf of wheat grain. |
| `RAS_07` | `rashi_tula.svg` | Tula (Libra) | Classical balance scale in perfect horizontal equilibrium. |
| `RAS_08` | `rashi_vrishchika.svg`| Vrishchika (Scorpio) | Coiled Scorpion tail with sharp raised stinger. |
| `RAS_09` | `rashi_dhanu.svg` | Dhanu (Sagittarius) | Drawn archer's bow with an arrow aimed upward at 45°. |
| `RAS_10` | `rashi_makara.svg` | Makara (Capricorn) | Mythical sea-goat with curved ibex horns and aquatic tail. |
| `RAS_11` | `rashi_kumbha.svg` | Kumbha (Aquarius) | Earthen pitcher pouring cosmic stream of vital waters. |
| `RAS_12` | `rashi_meena.svg` | Meena (Pisces) | Pair of swimming fish connected in a circular yin-yang flow. |

### C. Kundli Input & Chart Interface
| Asset ID | File Name | Context | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `KND_01` | `kundli_chart.svg` | Natal Chart Tab | Traditional South/North Indian diamond chart geometry. |
| `KND_02` | `birth_calendar.svg`| Date of Birth | Clean calendar card marked with a birth star emblem. |
| `KND_03` | `birth_clock.svg` | Time of Birth | Analog clock with hour, minute, and second precision hands. |
| `KND_04` | `slot_sunrise.svg` | Quick Time: Morning 06:00 | Rising sun at 6 AM over a clean horizon line. |
| `KND_05` | `slot_noon.svg` | Quick Time: Midday 12:00 | Zenith sun positioned directly overhead. |
| `KND_06` | `slot_sunset.svg` | Quick Time: Evening 18:00 | Setting sun touching the evening horizon. |
| `KND_07` | `slot_midnight.svg`| Quick Time: Midnight 00:00| Crescent moon under a star-studded midnight sky. |
| `KND_08` | `location_geo.svg` | Birth Place / City | Map location pin with internal compass rose. |
| `KND_09` | `vimshottari.svg` | Dasha Timeline | Flowing planetary progression timeline with milestones. |
| `KND_10` | `transit_food.svg` | Planetary Transit Food | Planet entering a supportive bowl of grains and herbs. |

---

## 4. Chat, Aahar Vigyan & AI Health Memory

### A. The 3 Pillars of Aahar Vigyan & Hero Elements
| Asset ID | File Name | Pillar / Component | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `AHV_01` | `pillar_ayurveda.svg`| Step 1: Ayurveda | Classical Ayurvedic mortar & pestle with fresh healing leaves. |
| `AHV_02` | `pillar_panchang.svg`| Daily: Panchang | Sun and Moon cosmic wheel harmonized with daily elements. |
| `AHV_03` | `pillar_jyotish.svg` | Step 2: Jyotish | Astrological natal chart ring aligned with grain affinities. |
| `AHV_04` | `sacred_mandala.svg`| Rotating Mandala / AI Core | 8-petal sacred geometric Sri Yantra mandala. |

### B. The 3 Doshas (*Constitutional Blueprints*)
| Asset ID | File Name | Dosha | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `DSH_01` | `dosha_vata.svg` | Vata (Air + Ether) | Dynamic swirling breeze and celestial ether vortex lines. |
| `DSH_02` | `dosha_pitta.svg`| Pitta (Fire + Water) | Sharp upward flame emerging from a cooling water drop base. |
| `DSH_03` | `dosha_kapha.svg`| Kapha (Earth + Water) | Stable mountain foundation cradled by calm river waves. |
| `DSH_04` | `dosha_tridosha.svg`| Tridosha Equilibrium | Three intertwined elemental nodes in perfect circular harmony. |

### C. Shad Rasa (*The 6 Ayurvedic Tastes*)
| Asset ID | File Name | Rasa (Sanskrit / English) | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `RSA_01` | `rasa_madhura.svg`| Madhura (Sweet) | Hexagonal honey cell with rich golden droplet / ripe grain. |
| `RSA_02` | `rasa_amla.svg` | Amla (Sour) | Sliced Indian gooseberry (*Amla*) / citrus wedge. |
| `RSA_03` | `rasa_lavana.svg`| Lavana (Salty) | Natural pure Himalayan rock salt (*Saindhava*) crystals. |
| `RSA_04` | `rasa_katu.svg` | Katu (Pungent) | Dried ginger root (*Shunthi*) and black peppercorns. |
| `RSA_05` | `rasa_tikta.svg` | Tikta (Bitter) | Fresh Neem leaf and sliced bitter gourd (*Karela*). |
| `RSA_06` | `rasa_kashaya.svg`| Kashaya (Astringent) | Open pomegranate showing ruby seeds and Haritaki fruit. |

### D. AI Health Memory Dossier Tabs
| Asset ID | File Name | Memory Tab | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `MEM_01` | `mem_body_type.svg` | Body Type (Prakriti) | Human energy silhouette surrounded by 3 dosha rings. |
| `MEM_02` | `mem_food_thali.svg`| Food Thali Nutrition | Traditional bronze Indian thali plate with 6 authentic katoris. |
| `MEM_03` | `mem_medical_ocr.svg`| Medical Diagnostic OCR | Medical report sheet with high-tech optical laser scanner line. |
| `MEM_04` | `mem_summary.svg` | 360° Health Dossier | Official health scroll certificate with ribbon seal and star. |

### E. Chat Interface & User Actions
| Asset ID | File Name | Action / Control | Visual Metaphor & Description |
| :--- | :--- | :--- | :--- |
| `ACT_01` | `ai_sparkle.svg` | AI Insight / Suggestion | Distinctive 4-point glowing star cluster. |
| `ACT_02` | `camera_thali.svg` | Camera Thali / Report | Camera shutter icon framed by organic leaf corners. |
| `ACT_03` | `gallery_upload.svg`| Upload Document / Image | File folder with photo and PDF thumbnail tabs. |
| `ACT_04` | `voice_mic.svg` | Voice Chat Input | Modern microphone capsule with audio frequency ripples. |
| `ACT_05` | `send_message.svg` | Send Query | Angled paper airplane with directional speed trails. |
| `ACT_06` | `retake_quiz.svg` | Retake Assessment | Circular refresh arrows enclosing a quiz clipboard. |
| `ACT_07` | `delete_memory.svg`| Clear AI Memory | Minimalist wastebasket with sparkle dust transition. |
| `ACT_08` | `download_pdf.svg` | Download Dossier PDF | Downward arrow leading into an official document tray. |

---

## 5. Recommended Directory Structure for Assets

```text
assets/
└── icons/
    ├── panchang/
    │   ├── tithi.svg
    │   ├── vara.svg
    │   ├── nakshatra.svg
    │   ├── yoga.svg
    │   ├── karana.svg
    │   ├── sunrise.svg
    │   ├── sunset.svg
    │   ├── moonrise.svg
    │   ├── moonset.svg
    │   ├── abhijit_muhurta.svg
    │   ├── brahma_muhurta.svg
    │   ├── amrit_kalam.svg
    │   ├── rahu_kalam.svg
    │   ├── ritu_vasanta.svg
    │   ├── ritu_grishma.svg
    │   ├── ritu_varsha.svg
    │   ├── ritu_sharad.svg
    │   ├── ritu_hemanta.svg
    │   └── ritu_shishira.svg
    ├── kundli/
    │   ├── graha_surya.svg
    │   ├── graha_chandra.svg
    │   ├── graha_mangal.svg
    │   ├── graha_budha.svg
    │   ├── graha_guru.svg
    │   ├── graha_shukra.svg
    │   ├── graha_shani.svg
    │   ├── graha_rahu.svg
    │   ├── graha_ketu.svg
    │   ├── rashi_mesha.svg ... rashi_meena.svg (12 files)
    │   ├── kundli_chart.svg
    │   ├── slot_sunrise.svg
    │   ├── slot_noon.svg
    │   ├── slot_sunset.svg
    │   └── slot_midnight.svg
    ├── aahar_vigyan/
    │   ├── pillar_ayurveda.svg
    │   ├── pillar_panchang.svg
    │   ├── pillar_jyotish.svg
    │   ├── sacred_mandala.svg
    │   ├── dosha_vata.svg
    │   ├── dosha_pitta.svg
    │   ├── dosha_kapha.svg
    │   ├── dosha_tridosha.svg
    │   └── rasa_madhura.svg ... rasa_kashaya.svg (6 files)
    └── memory/
        ├── mem_body_type.svg
        ├── mem_food_thali.svg
        ├── mem_medical_ocr.svg
        └── mem_summary.svg
```
