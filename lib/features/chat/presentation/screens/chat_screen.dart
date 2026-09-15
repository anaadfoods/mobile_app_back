import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/content_config_service.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/service_locator.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_header_widget.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_sessions_drawer.dart';
import '../widgets/chat_stage_indicator.dart';
import '../widgets/suggested_chips_row.dart';
import '../widgets/aahar_vigyan_welcome_sheet.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<double> _headerScale;
  Map<String, dynamic>? _userHealthProfile;
  List<Map<String, dynamic>>? _suggestedPrompts;

  @override
  void initState() {
    super.initState();
    _initHeaderAnimation();
    context.read<ChatCubit>().loadSessions();
    _loadSuggestedPrompts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrakritiOnboarding();
    });
  }

  Future<void> _loadSuggestedPrompts() async {
    try {
      final tokenService = getIt<TokenService>();
      final token = await tokenService.getAccessToken();
      if (token == null) return;
      final prompts = await ContentConfigService().fetchSuggestedPrompts(token: token);
      if (prompts.isNotEmpty && mounted) {
        setState(() => _suggestedPrompts = prompts);
      }
    } catch (_) {
      // Keep hardcoded fallback
    }
  }

  void _initHeaderAnimation() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPrakritiOnboarding() async {
    try {
      final resp = await ApiClient.instance.get(ApiConfig.healthProfileEndpoint);
      if (resp.data != null && mounted) {
        final d = resp.data;
        final profile = d is Map<String, dynamic> ? (d['data'] as Map<String, dynamic>? ?? d) : null;
        setState(() {
          _userHealthProfile = profile;
        });
        final status = profile?['onboarding_status'];
        final dosha = profile?['primary_dosha'] ?? profile?['prakriti_dosha'];
        final hasPrakriti = dosha != null && dosha.toString().trim().isNotEmpty;
        final hasSessions = context.read<ChatCubit>().state.sessions.isNotEmpty;

        if (!hasPrakriti && !hasSessions && (status == null || status == 'NOT_STARTED')) {
          _showPrakritiOnboardingModal();
        }
      }
    } catch (_) {}
  }

  void _showPrakritiOnboardingModal() {
    AaharVigyanWelcomeSheet.show(context);
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset <= 150;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _isNearBottom()) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _confirmDeleteSession(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Delete Conversation?"),
            content: const Text(
              "Are you sure you want to delete this chat session? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<ChatCubit>().deleteSession(sessionId);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.softRed),
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen:
          (previous, current) =>
              previous.messages.length != current.messages.length ||
              previous.streamingText != current.streamingText,
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        ChatSession? activeSession;
        try {
          activeSession = state.sessions.firstWhere(
            (s) => s.sessionId == state.activeSessionId,
          );
        } catch (_) {
          activeSession = null;
        }

        final bool isGenerating =
            state.status == ChatStatus.sending ||
            state.status == ChatStatus.streaming;
        final bool showStageIndicator =
            isGenerating && state.streamingText.isEmpty;

        return Scaffold(
          key: _scaffoldKey,
          drawer: ChatSessionsDrawer(
            sessions: state.sessions,
            activeSessionId: state.activeSessionId,
            onSelect: (id) => context.read<ChatCubit>().selectSession(id),
            onDelete: (id) => context.read<ChatCubit>().deleteSession(id),
            onRename:
                (id, title) =>
                    context.read<ChatCubit>().renameSession(id, title),
            onNewChat: () => context.read<ChatCubit>().clearChat(),
          ),
          body: Column(
            children: [
              // ── Animated Header matching Home Screen ──
              FadeTransition(
                opacity: _headerFade,
                child: ScaleTransition(
                  scale: _headerScale,
                  child: ChatHeaderWidget(
                    title: activeSession?.title ?? 'ANAAD AI',
                    isGenerating: isGenerating,
                    stageLabel: state.stageLabel,
                    quotaInfo: state.quotaInfo,
                    activeSessionId: state.activeSessionId,
                    onBack: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    onOpenDrawer: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    onNewChat: () {
                      context.read<ChatCubit>().clearChat();
                    },
                    onHealthProfile: () {
                      context.push('/health-profile');
                    },
                    onDeleteSession: () {
                      if (state.activeSessionId != null) {
                        _confirmDeleteSession(context, state.activeSessionId!);
                      }
                    },
                  ),
                ),
              ),
              // ── Quota Limit Warning Banner ──
              if (state.quotaInfo != null &&
                  state.quotaInfo!.tokensRemaining == 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppColors.softRed.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.softRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Daily limit reached (${state.quotaInfo!.dailyLimit}/${state.quotaInfo!.dailyLimit} queries for ${state.quotaInfo!.tierName}). Order or subscribe to upgrade!",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.softRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child:
                    state.messages.isEmpty && state.streamingText.isEmpty
                        ? _buildGeminiEmptyState(context)
                        : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount:
                              state.messages.length +
                              (state.status == ChatStatus.streaming ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (state.status == ChatStatus.streaming &&
                                index == 0) {
                              return RepaintBoundary(
                                child: ChatMessageBubble(
                                  message: ChatMessageEntity(
                                    role: ChatRole.assistant,
                                    content: state.streamingText,
                                    timestamp: DateTime.now(),
                                  ),
                                  isStreaming: true,
                                ),
                              );
                            }

                            final messageIndex =
                                state.status == ChatStatus.streaming
                                    ? index - 1
                                    : index;
                            final message =
                                state.messages[state.messages.length -
                                    1 -
                                    messageIndex];

                            return RepaintBoundary(
                              child: ChatMessageBubble(
                                message: message,
                                isStreaming: false,
                                messageIndex:
                                    state.messages.length - 1 - messageIndex,
                              ),
                            );
                          },
                        ),
              ),

              // Stage Indicator: only visible during initial formulation, hides when writing starts
              ChatStageIndicator(isVisible: showStageIndicator),

              // Gemini-style Boxed Suggested Chips Row
              SuggestedChipsRow(
                chips: state.suggestedChips,
                isEnabled: !isGenerating,
                onChipTap: (chipText) {
                  context.read<ChatCubit>().sendMessage(chipText);
                },
              ),

              // Chat Input Bar
              ChatInputBar(
                isLoading: isGenerating,
                onSend: (message, {File? file}) {
                  context.read<ChatCubit>().sendMessage(message, file: file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Memory-Driven Empty State (No hardcoded static details)
  Widget _buildGeminiEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryDosha = _userHealthProfile?['primary_dosha'] ?? _userHealthProfile?['prakriti_dosha'];
    final hasMemory = primaryDosha != null && primaryDosha.toString().trim().isNotEmpty;

    final List<Map<String, dynamic>> dynamicMemoryCards = [];
    if (hasMemory) {
      if (_suggestedPrompts != null && _suggestedPrompts!.isNotEmpty) {
        // Use API-driven suggestions with template variable substitution
        for (final prompt in _suggestedPrompts!) {
          final contextRequired = prompt['context_required'] ?? 'none';
          final requiresProfile = prompt['requires_health_profile'] == true;
          if ((requiresProfile || contextRequired == 'dosha') && !hasMemory) {
            continue;
          }
          
          String title = (prompt['title_template_en'] ?? '').toString();
          String query = (prompt['query_template_en'] ?? '').toString();
          // Substitute template variables
          title = title.replaceAll('{dosha}', primaryDosha?.toString() ?? '');
          query = query.replaceAll('{dosha}', primaryDosha?.toString() ?? '');
          
          dynamicMemoryCards.add({
            "icon": Icons.auto_awesome_rounded,
            "color": AppColors.forest,
            "title": title,
            "query": query,
          });
        }
      } else {
        // Fallback to hardcoded suggestions
        dynamicMemoryCards.addAll([
          {
            "icon": Icons.spa_rounded,
            "color": AppColors.forest,
            "title": "$primaryDosha Dietary Guidance",
            "query": "What foods pacify my $primaryDosha constitution today?",
          },
          {
            "icon": Icons.wb_sunny_rounded,
            "color": AppColors.gold,
            "title": "Panchang & Dosha Harmony",
            "query": "Harmonize today's Panchang with my $primaryDosha Prakriti.",
          },
          {
            "icon": Icons.restaurant_rounded,
            "color": AppColors.jyotish,
            "title": "Personalized Ahara Plan",
            "query": "Suggest optimal meal timings and healing foods for my body type.",
          },
        ]);
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (hasMemory ? AppColors.forest : AppColors.gold).withValues(alpha: 0.15),
              ),
              child: Icon(
                hasMemory ? Icons.spa_rounded : Icons.auto_awesome_rounded,
                size: 40,
                color: hasMemory ? AppColors.forest : AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasMemory ? "Welcome back to Aahar Vigyan" : "Welcome to Aahar Vigyan",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasMemory
                  ? "Your AI memory is active for $primaryDosha Prakriti. Ask any personalized food or health question below."
                  : "Your personalized food intelligence agent. Start your Prakriti journey or ask any health question below.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: isDark ? Colors.white70 : AppColors.charcoal70,
              ),
            ),
            const SizedBox(height: 20),

            if (!hasMemory) ...[
              // Action button to open Welcome Journey / Prakriti Assessment
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _showPrakritiOnboardingModal(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.spa_rounded, size: 18),
                  label: const Text(
                    'Discover My Prakriti →',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Memory-Driven Suggestion Tiles
              Column(
                children: dynamicMemoryCards.map((card) {
                  final IconData icon = card["icon"] as IconData;
                  final Color iconColor = card["color"] as Color;
                  final String title = card["title"] as String;
                  final String query = card["query"] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          context.read<ChatCubit>().sendMessage(query);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: iconColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, size: 20, color: iconColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.charcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      query,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? Colors.white60
                                            : AppColors.charcoal60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.charcoal38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
