class ShippingDetails {
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;

  ShippingDetails({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
  });

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    return ShippingDetails(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
    };
  }
}
