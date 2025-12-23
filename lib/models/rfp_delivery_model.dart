
class Delivery {
  final int id;
  final DateTime deliveryDate;
  final int isoWeekYear;
  final int isoWeek;
  final int deliverySeqInWeek;
  final String status;
  final String displayLabel;
  final int itemsCount;

  Delivery({
    required this.id,
    required this.deliveryDate,
    required this.isoWeekYear,
    required this.isoWeek,
    required this.deliverySeqInWeek,
    required this.status,
    required this.displayLabel,
    required this.itemsCount,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      deliveryDate: DateTime.parse(json['delivery_date']),
      isoWeekYear: json['iso_week_year'],
      isoWeek: json['iso_week'],
      deliverySeqInWeek: json['delivery_seq_in_week'],
      status: json['status'],
      displayLabel: json['display_label'],
      itemsCount: json['items_count'],
    );
  }
}

class DeliveryDetail {
    DeliveryDetail({
        required this.id,
        required this.deliveryDate,
        required this.isoWeekYear,
        required this.isoWeek,
        required this.deliverySeqInWeek,
        required this.status,
        required this.notes,
        required this.displayLabel,
        required this.items,
    });

    final int? id;
    final DateTime? deliveryDate;
    final int? isoWeekYear;
    final int? isoWeek;
    final int? deliverySeqInWeek;
    final String? status;
    final String? notes;
    final String? displayLabel;
    final Items? items;

    DeliveryDetail copyWith({
        int? id,
        DateTime? deliveryDate,
        int? isoWeekYear,
        int? isoWeek,
        int? deliverySeqInWeek,
        String? status,
        String? notes,
        String? displayLabel,
        Items? items,
    }) {
        return DeliveryDetail(
            id: id ?? this.id,
            deliveryDate: deliveryDate ?? this.deliveryDate,
            isoWeekYear: isoWeekYear ?? this.isoWeekYear,
            isoWeek: isoWeek ?? this.isoWeek,
            deliverySeqInWeek: deliverySeqInWeek ?? this.deliverySeqInWeek,
            status: status ?? this.status,
            notes: notes ?? this.notes,
            displayLabel: displayLabel ?? this.displayLabel,
            items: items ?? this.items,
        );
    }

    factory DeliveryDetail.fromJson(Map<String, dynamic> json){ 
        return DeliveryDetail(
            id: json["id"],
            deliveryDate: DateTime.tryParse(json["delivery_date"] ?? ""),
            isoWeekYear: json["iso_week_year"],
            isoWeek: json["iso_week"],
            deliverySeqInWeek: json["delivery_seq_in_week"],
            status: json["status"],
            notes: json["notes"],
            displayLabel: json["display_label"],
            items: json["items"] == null ? null : Items.fromJson(json["items"]),
        );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "delivery_date": "${deliveryDate?.year.toString().padLeft(4 ,'0')}-${deliveryDate?.month.toString().padLeft(2,'0')}-${deliveryDate?.day.toString().padLeft(2,'0')}",
        "iso_week_year": isoWeekYear,
        "iso_week": isoWeek,
        "delivery_seq_in_week": deliverySeqInWeek,
        "status": status,
        "notes": notes,
        "display_label": displayLabel,
        "items": items?.toJson(),
    };

}

class Items {
    Items({
        required this.planDelivered,
        required this.veggieAddons,
        required this.productAddons,
    });

    final List<PlanDelivered> planDelivered;
    final List<PlanDelivered> veggieAddons;
    final List<dynamic> productAddons;

    Items copyWith({
        List<PlanDelivered>? planDelivered,
        List<PlanDelivered>? veggieAddons,
        List<dynamic>? productAddons,
    }) {
        return Items(
            planDelivered: planDelivered ?? this.planDelivered,
            veggieAddons: veggieAddons ?? this.veggieAddons,
            productAddons: productAddons ?? this.productAddons,
        );
    }

    factory Items.fromJson(Map<String, dynamic> json){ 
        return Items(
            planDelivered: json["plan_delivered"] == null ? [] : List<PlanDelivered>.from(json["plan_delivered"]!.map((x) => PlanDelivered.fromJson(x))),
            veggieAddons: json["veggie_addons"] == null ? [] : List<PlanDelivered>.from(json["veggie_addons"]!.map((x) => PlanDelivered.fromJson(x))),
            productAddons: json["product_addons"] == null ? [] : List<dynamic>.from(json["product_addons"]!.map((x) => x)),
        );
    }

    Map<String, dynamic> toJson() => {
        "plan_delivered": planDelivered.map((x) => x.toJson()).toList(),
        "veggie_addons": veggieAddons.map((x) => x.toJson()).toList(),
        "product_addons": productAddons.map((x) => x).toList(),
    };

}

class PlanDelivered {
    PlanDelivered({
        required this.id,
        required this.veg,
        required this.quantity,
        required this.notes,
        required this.itemType,
    });

    final int? id;
    final Veg? veg;
    final String? quantity;
    final String? notes;
    final String? itemType;

    PlanDelivered copyWith({
        int? id,
        Veg? veg,
        String? quantity,
        String? notes,
        String? itemType,
    }) {
        return PlanDelivered(
            id: id ?? this.id,
            veg: veg ?? this.veg,
            quantity: quantity ?? this.quantity,
            notes: notes ?? this.notes,
            itemType: itemType ?? this.itemType,
        );
    }

    factory PlanDelivered.fromJson(Map<String, dynamic> json){ 
        return PlanDelivered(
            id: json["id"],
            veg: json["veg"] == null ? null : Veg.fromJson(json["veg"]),
            quantity: json["quantity"],
            notes: json["notes"],
            itemType: json["item_type"],
        );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "veg": veg?.toJson(),
        "quantity": quantity,
        "notes": notes,
        "item_type": itemType,
    };

}

class Veg {
    Veg({
        required this.id,
        required this.name,
        required this.season,
    });

    final int? id;
    final String? name;
    final String? season;

    Veg copyWith({
        int? id,
        String? name,
        String? season,
    }) {
        return Veg(
            id: id ?? this.id,
            name: name ?? this.name,
            season: season ?? this.season,
        );
    }

    factory Veg.fromJson(Map<String, dynamic> json){ 
        return Veg(
            id: json["id"],
            name: json["name"],
            season: json["season"],
        );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "season": season,
    };

}


// --- New Models for Detailed View ---

