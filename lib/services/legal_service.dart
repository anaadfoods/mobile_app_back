import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/legal_document_model.dart';
import 'api_config.dart';

/// Service for fetching legal documents (Terms & Conditions, Privacy Policy)
class LegalService {
  /// Fetches latest legal documents from the API
  /// This endpoint does not require authentication
  Future<List<LegalDocument>> fetchLegalDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.legalEndpoint}'),
        headers: ApiConfig.getBaseHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
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
