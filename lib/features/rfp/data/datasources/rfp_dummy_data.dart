import '../../domain/entities/rfp_vegetable.dart';
import '../../domain/entities/rfp_delivery.dart';

/// Static dummy datasets and schedule generator for RFP mock data source.
class RfpDummyData {
  static const List<RfpVegetable> p1Vegetables = [
    RfpVegetable(
      id: 'v01',
      name: 'Tomato',
      description: 'Cherry & Vine varieties',
      iconName: 'spa',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v02',
      name: 'Carrot',
      description: 'Sweet Imperator carrots',
      iconName: 'eco',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v03',
      name: 'Spinach',
      description: 'Baby leaf organic spinach',
      iconName: 'grass',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v04',
      name: 'Beans',
      description: 'Crisp French green beans',
      iconName: 'spa',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v05',
      name: 'Capsicum',
      description: 'Mixed bell peppers',
      iconName: 'eco',
      season: 'summer',
    ),
    RfpVegetable(
      id: 'v06',
      name: 'Radish',
      description: 'Daiko & red globe radishes',
      iconName: 'spa',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v07',
      name: 'Cucumber',
      description: 'English greenhouse cucumbers',
      iconName: 'eco',
      season: 'summer',
    ),
    RfpVegetable(
      id: 'v08',
      name: 'Brinjal',
      description: 'Purple Indian eggplant',
      iconName: 'spa',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v09',
      name: 'Fenugreek',
      description: 'Fresh methi leaves',
      iconName: 'grass',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v10',
      name: 'Coriander',
      description: 'Aromatic dhaniya bunches',
      iconName: 'eco',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v11',
      name: 'Mint',
      description: 'Spearmint pudina leaves',
      iconName: 'grass',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v12',
      name: 'Green Chili',
      description: 'Hot finger chilies',
      iconName: 'local_fire_department',
      season: 'all',
    ),
  ];

  static const List<RfpVegetable> p2Vegetables = [
    RfpVegetable(
      id: 'v13',
      name: 'Okra',
      description: 'Tender lady finger',
      iconName: 'spa',
      season: 'summer',
    ),
    RfpVegetable(
      id: 'v14',
      name: 'Bitter Gourd',
      description: 'Fresh karela',
      iconName: 'eco',
      season: 'summer',
    ),
    RfpVegetable(
      id: 'v15',
      name: 'Bottle Gourd',
      description: 'Organic lauki',
      iconName: 'spa',
      season: 'summer',
    ),
    RfpVegetable(
      id: 'v16',
      name: 'Ridge Gourd',
      description: 'Farm-fresh turai',
      iconName: 'eco',
      season: 'summer',
    ),
    RfpVegetable(
      id: 'v17',
      name: 'Pumpkin',
      description: 'Sweet kaddu',
      iconName: 'spa',
      season: 'autumn',
    ),
    RfpVegetable(
      id: 'v18',
      name: 'Cauliflower',
      description: 'Compact white phool gobi',
      iconName: 'eco',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v19',
      name: 'Cabbage',
      description: 'Crisp patta gobi',
      iconName: 'spa',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v20',
      name: 'Peas',
      description: 'Sweet green matar',
      iconName: 'grass',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v21',
      name: 'Drumstick',
      description: 'Moringa sahjan pods',
      iconName: 'eco',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v22',
      name: 'Green Garlic',
      description: 'Young hara lehsun shoots',
      iconName: 'grass',
      season: 'winter',
    ),
  ];

  static const List<RfpVegetable> p3Vegetables = [
    RfpVegetable(
      id: 'v23',
      name: 'Sweet Potato',
      description: 'Orange-fleshed shakarkandi',
      iconName: 'spa',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v24',
      name: 'Turnip',
      description: 'White shalgam roots',
      iconName: 'eco',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v25',
      name: 'Beetroot',
      description: 'Deep red chukandar',
      iconName: 'spa',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v26',
      name: 'Onion',
      description: 'Nashik red pyaaz',
      iconName: 'eco',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v27',
      name: 'Potato',
      description: 'Himalayan aloo',
      iconName: 'spa',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v28',
      name: 'Garlic',
      description: 'Full-bulb lehsun',
      iconName: 'eco',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v29',
      name: 'Ginger',
      description: 'Aromatic adrak rhizomes',
      iconName: 'spa',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v30',
      name: 'Turmeric',
      description: 'Fresh haldi roots',
      iconName: 'eco',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v31',
      name: 'Lemongrass',
      description: 'Fragrant stalks',
      iconName: 'grass',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v32',
      name: 'Curry Leaves',
      description: 'Kadhi patta sprigs',
      iconName: 'eco',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v33',
      name: 'Spring Onion',
      description: 'Green hara pyaaz',
      iconName: 'grass',
      season: 'winter',
    ),
  ];

  static const List<RfpVegetable> p4Vegetables = [
    RfpVegetable(
      id: 'v34',
      name: 'Baby Corn',
      description: 'Miniature corn cobs',
      iconName: 'spa',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v35',
      name: 'Zucchini',
      description: 'Italian green courgettes',
      iconName: 'eco',
      season: 'summer',
    ),
    RfpVegetable(
      id: 'v36',
      name: 'Asparagus',
      description: 'Tender green spears',
      iconName: 'grass',
      season: 'spring',
    ),
    RfpVegetable(
      id: 'v37',
      name: 'Avocado',
      description: 'Hass variety',
      iconName: 'eco',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v38',
      name: 'Cherry Tomato',
      description: 'Red & yellow medley',
      iconName: 'spa',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v39',
      name: 'Kale',
      description: 'Curly organic leaves',
      iconName: 'grass',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v40',
      name: 'Broccoli',
      description: 'Dense green florets',
      iconName: 'eco',
      season: 'winter',
    ),
    RfpVegetable(
      id: 'v41',
      name: 'Lettuce',
      description: 'Butterhead & romaine mix',
      iconName: 'grass',
      season: 'all',
    ),
    RfpVegetable(
      id: 'v42',
      name: 'Celery',
      description: 'Crisp stalks with leaves',
      iconName: 'eco',
      season: 'winter',
    ),
  ];

  static List<RfpDelivery> generateDeliverySchedule() {
    final schedule = <RfpDelivery>[];
    final baseDate = DateTime(2026, 10, 5); // First Monday

    for (int week = 1; week <= 12; week++) {
      final monDate = baseDate.add(Duration(days: (week - 1) * 7));
      final thuDate = monDate.add(const Duration(days: 3));

      final String status;
      if (week <= 3) {
        status = 'delivered';
      } else if (week == 4) {
        status = 'upcoming';
      } else {
        status = 'scheduled';
      }

      schedule.add(
        RfpDelivery(
          id: 'del_${week}_mon',
          weekNumber: week,
          date: monDate,
          dayOfWeek: 'Monday',
          status: status,
          patches: const [
            RfpDeliveryPatch(
              patchId: 'patch_p1',
              patchLabel: 'P1',
              weightKg: 7.5,
              includedVegetables: ['Tomato', 'Spinach', 'Carrot', 'Beans'],
            ),
          ],
          description: week <= 3 ? 'Delivered safely' : 'Scheduled dispatch',
          trackingLabel: week == 4 ? 'Dispatched' : null,
        ),
      );

      schedule.add(
        RfpDelivery(
          id: 'del_${week}_thu',
          weekNumber: week,
          date: thuDate,
          dayOfWeek: 'Thursday',
          status: status,
          patches: const [
            RfpDeliveryPatch(
              patchId: 'patch_p1',
              patchLabel: 'P1',
              weightKg: 5.0,
              includedVegetables: ['Capsicum', 'Cucumber', 'Brinjal'],
            ),
            RfpDeliveryPatch(
              patchId: 'patch_p2',
              patchLabel: 'P2',
              weightKg: 2.5,
              includedVegetables: ['Okra', 'Peas'],
            ),
          ],
          description: week <= 3 ? 'Delivered safely' : 'Scheduled dispatch',
          trackingLabel: null,
        ),
      );
    }
    return schedule;
  }
}
