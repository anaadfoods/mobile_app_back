import 'package:equatable/equatable.dart';
import 'body_type_entity.dart';

/// Domain entity representing the holistic 360-degree health dossier
/// and its S3-persisted summary document link.
class SummaryDossierEntity extends Equatable {
  final int healthScore;
  final String summaryMarkdown;
  final String documentUrl;
  final String generatedAt;
  final String? lastSyncTimestamp;
  final int syncedChatsCount;
  final int newInsightsCount;
  final List<String> recentChatLearnings;
  final List<String> keyFindings;
  final int totalThalis;
  final int totalReports;
  final int totalMemories;
  final BodyTypeEntity? bodyType;

  const SummaryDossierEntity({
    required this.healthScore,
    required this.summaryMarkdown,
    required this.documentUrl,
    required this.generatedAt,
    this.lastSyncTimestamp,
    this.syncedChatsCount = 0,
    this.newInsightsCount = 0,
    this.recentChatLearnings = const [],
    required this.keyFindings,
    required this.totalThalis,
    required this.totalReports,
    required this.totalMemories,
    this.bodyType,
  });

  factory SummaryDossierEntity.fromJson(Map<String, dynamic> json) {
    return SummaryDossierEntity(
      healthScore: (json['health_score'] as num?)?.toInt() ?? 85,
      summaryMarkdown: json['summary_markdown'] as String? ?? '',
      documentUrl: json['document_url'] as String? ?? '',
      generatedAt: json['generated_at'] as String? ?? '',
      lastSyncTimestamp: json['last_sync_timestamp'] as String?,
      syncedChatsCount: (json['synced_chats_count'] as num?)?.toInt() ?? 0,
      newInsightsCount: (json['new_insights_count'] as num?)?.toInt() ?? 0,
      recentChatLearnings: (json['recent_chat_learnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      keyFindings: (json['key_findings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalThalis: (json['total_thalis'] as num?)?.toInt() ?? 0,
      totalReports: (json['total_reports'] as num?)?.toInt() ?? 0,
      totalMemories: (json['total_memories'] as num?)?.toInt() ?? 0,
      bodyType: json['body_type'] != null ? BodyTypeEntity.fromJson(json['body_type'] as Map<String, dynamic>) : null,
    );
  }

  @override
  List<Object?> get props => [
        healthScore,
        summaryMarkdown,
        documentUrl,
        generatedAt,
        lastSyncTimestamp,
        syncedChatsCount,
        newInsightsCount,
        recentChatLearnings,
        keyFindings,
        totalThalis,
        totalReports,
        totalMemories,
        bodyType,
      ];
}
