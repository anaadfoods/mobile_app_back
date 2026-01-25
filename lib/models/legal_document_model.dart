/// Model representing a legal document (Terms & Conditions or Privacy Policy)
class LegalDocument {
  final String typeDisplay;
  final String version;
  final String content;
  final bool isActive;
  final String createdAt;

  LegalDocument({
    required this.typeDisplay,
    required this.version,
    required this.content,
    required this.isActive,
    required this.createdAt,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      typeDisplay: json['type_display'] ?? '',
      version: json['version'] ?? '',
      content: json['content'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Check if this is Terms & Conditions
  bool get isTermsAndConditions => typeDisplay == 'Terms & Conditions';

  /// Check if this is Privacy Policy
  bool get isPrivacyPolicy => typeDisplay == 'Privacy Policy';
}
