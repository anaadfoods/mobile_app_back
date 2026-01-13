/// Models for Vrat Calendar API response
/// GET /api/panchang-calender/vrat-calendar/

class VratCalendarResponse {
	final String start;
	final String end;
	final int days;
	final String tz;
	final String locale;
	final String calendarSystem;
	final String profile;
	final int count;
	final int uniqueDatesCount;
	final List<String> dates;
	final List<VratItem> items;

	const VratCalendarResponse({
		required this.start,
		required this.end,
		required this.days,
		required this.tz,
		required this.locale,
		required this.calendarSystem,
		required this.profile,
		required this.count,
		required this.uniqueDatesCount,
		required this.dates,
		required this.items,
	});

	factory VratCalendarResponse.fromJson(Map<String, dynamic> json) {
		final rawDates = json['dates'];
		final rawItems = json['items'];

		return VratCalendarResponse(
			start: (json['start'] ?? '').toString(),
			end: (json['end'] ?? '').toString(),
			days: (json['days'] as num?)?.toInt() ?? 0,
			tz: (json['tz'] ?? json['timezone'] ?? '').toString(),
			locale: (json['locale'] ?? '').toString(),
			calendarSystem: (json['calendar_system'] ?? '').toString(),
			profile: (json['profile'] ?? '').toString(),
			count: (json['count'] as num?)?.toInt() ?? 0,
			uniqueDatesCount: (json['unique_dates_count'] as num?)?.toInt() ?? 0,
			dates: rawDates is List ? rawDates.map((e) => e.toString()).toList() : const [],
			items: rawItems is List
					? rawItems
							.whereType<Map<String, dynamic>>()
							.map(VratItem.fromJson)
							.toList()
					: const [],
		);
	}
}

class VratItem {
	final String date; // YYYY-MM-DD
	final String name;
	final String type;
	final String source;
	final String code;
	final String importance; // high | medium | low
	final int priority;
	final VratInfo? info;
	final VratDetails? details;
	final String? why;
	final Map<String, dynamic>? explain;

	const VratItem({
		required this.date,
		required this.name,
		required this.type,
		required this.source,
		required this.code,
		required this.importance,
		required this.priority,
		this.info,
		this.details,
		this.why,
		this.explain,
	});

	factory VratItem.fromJson(Map<String, dynamic> json) {
		return VratItem(
			date: (json['date'] ?? '').toString(),
			name: (json['name'] ?? '').toString(),
			type: (json['type'] ?? '').toString(),
			source: (json['source'] ?? '').toString(),
			code: (json['code'] ?? '').toString(),
			importance: (json['importance'] ?? 'medium').toString(),
			priority: (json['priority'] as num?)?.toInt() ?? 0,
			info: json['info'] is Map<String, dynamic>
					? VratInfo.fromJson(json['info'] as Map<String, dynamic>)
					: null,
			details: json['details'] is Map<String, dynamic>
					? VratDetails.fromJson(json['details'] as Map<String, dynamic>)
					: null,
			why: json['why']?.toString(),
			explain: json['explain'] is Map<String, dynamic>
					? (json['explain'] as Map<String, dynamic>)
					: null,
		);
	}

	DateTime get dateTime {
		try {
			return DateTime.parse(date);
		} catch (_) {
			return DateTime.now();
		}
	}

	String get importanceLower => importance.toLowerCase();
}

class VratInfo {
	final String description;
	final String? descriptionEn;
	final String? descriptionHi;
	final VratObservance? observance;
	final VratParanRules? paranRules;

	const VratInfo({
		required this.description,
		this.descriptionEn,
		this.descriptionHi,
		this.observance,
		this.paranRules,
	});

	factory VratInfo.fromJson(Map<String, dynamic> json) {
		return VratInfo(
			description: (json['description'] ?? '').toString(),
			descriptionEn: json['description_en']?.toString(),
			descriptionHi: json['description_hi']?.toString(),
			observance: json['observance'] is Map<String, dynamic>
					? VratObservance.fromJson(json['observance'] as Map<String, dynamic>)
					: null,
			paranRules: json['paran_rules'] is Map<String, dynamic>
					? VratParanRules.fromJson(json['paran_rules'] as Map<String, dynamic>)
					: null,
		);
	}
}

class VratObservance {
	final String? fasting;
	final List<String> avoidEn;
	final List<String> avoidHi;
	final List<String> allowedEn;
	final List<String> allowedHi;
	final String? notesEn;
	final String? notesHi;
	final String? howToDoEn;
	final String? howToDoHi;

	const VratObservance({
		this.fasting,
		required this.avoidEn,
		required this.avoidHi,
		required this.allowedEn,
		required this.allowedHi,
		this.notesEn,
		this.notesHi,
		this.howToDoEn,
		this.howToDoHi,
	});

	factory VratObservance.fromJson(Map<String, dynamic> json) {
		List<String> parseList(dynamic value) {
			if (value is List) return value.map((e) => e.toString()).toList();
			return const [];
		}

		return VratObservance(
			fasting: json['fasting']?.toString(),
			avoidEn: parseList(json['avoid_en']),
			avoidHi: parseList(json['avoid_hi']),
			allowedEn: parseList(json['allowed_en']),
			allowedHi: parseList(json['allowed_hi']),
			notesEn: json['notes_en']?.toString(),
			notesHi: json['notes_hi']?.toString(),
			howToDoEn: json['how_to_do_en']?.toString(),
			howToDoHi: json['how_to_do_hi']?.toString(),
		);
	}
}

class VratParanRules {
	final String? notesEn;
	final String? notesHi;

	const VratParanRules({
		this.notesEn,
		this.notesHi,
	});

	factory VratParanRules.fromJson(Map<String, dynamic> json) {
		return VratParanRules(
			notesEn: json['notes_en']?.toString(),
			notesHi: json['notes_hi']?.toString(),
		);
	}
}

class VratDetails {
	final String? tithi;
	final String? paksha;
	final String? masa;
	final DateTime? sunrise;
	final DateTime? sunset;

	const VratDetails({
		this.tithi,
		this.paksha,
		this.masa,
		this.sunrise,
		this.sunset,
	});

	factory VratDetails.fromJson(Map<String, dynamic> json) {
		return VratDetails(
			tithi: json['tithi']?.toString(),
			paksha: json['paksha']?.toString(),
			masa: json['masa']?.toString(),
			sunrise: _tryParseDateTime(json['sunrise']),
			sunset: _tryParseDateTime(json['sunset']),
		);
	}
}

DateTime? _tryParseDateTime(dynamic value) {
	if (value == null) return null;
	try {
		return DateTime.parse(value.toString());
	} catch (_) {
		return null;
	}
}

