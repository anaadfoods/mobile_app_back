class ProductImage {
  final String image;
  final String altText;

  ProductImage({required this.image, required this.altText});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      image: json['image'] ?? '',
      altText: json['alt_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'image': image, 'alt_text': altText};
  }
}
