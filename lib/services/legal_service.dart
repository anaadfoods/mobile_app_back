import '../models/legal_document_model.dart';
import 'api_config.dart';
import 'api_client.dart';

import 'package:grocery_app/service_locator.dart';

/// Service for fetching legal documents (Terms & Conditions, Privacy Policy)
class LegalService {
  factory LegalService() => getIt<LegalService>();
  LegalService.create();
  /// Fetches latest legal documents from the API
  /// This endpoint does not require authentication
  Future<List<LegalDocument>> fetchLegalDocuments() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.legalEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => LegalDocument.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load legal documents: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch legal documents: $e');
    }
  }

  /// Get Terms & Conditions from the list
  LegalDocument? getTermsAndConditions(List<LegalDocument> documents) {
    try {
      return documents.firstWhere((doc) => doc.isTermsAndConditions);
    } catch (_) {
      return null;
    }
  }

  /// Get Privacy Policy from the list
  LegalDocument? getPrivacyPolicy(List<LegalDocument> documents) {
    try {
      return documents.firstWhere((doc) => doc.isPrivacyPolicy);
    } catch (_) {
      return null;
    }
  }
}
