import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/cubits/chats/chat_cubit.dart';
import 'package:grocery_app/cubits/chats/chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    context.read<ChatCubit>().sendMessage(text);
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
        title: Text(
          "Anaad Assistant",
          style: theme.textTheme.titleLarge?.copyWith(
            color: color.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: color.primary),
              child: Text(
                'Menu',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat, color: color.onSurface),
              title: Text(
                'chat1',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color.onSurface,
                ),
              ),
              onTap: () {
                // Navigate to home
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: color.onSurface),
              title: Text(
                'chat2',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color.onSurface,
                ),
              ),
              onTap: () {
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state.status == ChatStatus.failure) {
                  SnackBarHelper.showSomethingWrong(context);
                }
              },
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  if (state.status == ChatStatus.loading) {
                    return Center(
                      child: CircularProgressIndicator(color: color.primary),
                    );
                  }
                  return _buildEmptyState(theme);
                }

                return Column(
                  children: [
                    if (state.status == ChatStatus.loading)
                      LinearProgressIndicator(
                        color: color.primary,
                        backgroundColor: color.secondary.withValues(alpha: 0.3),
                      ),

                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final isUser = msg.isUser;

                          return Align(
                            alignment:
                                isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isUser
                                        ? color.primary
                                        : color.surface.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      isUser
                                          ? const Radius.circular(16)
                                          : const Radius.circular(0),
                                  bottomRight:
                                      isUser
                                          ? const Radius.circular(0)
                                          : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.charcoal.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                msg.text,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      isUser
                                          ? color.onPrimary
                                          : color.onSurface,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ---------------- Input Area ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: 0.06),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: "Ask about organic wheat...",
                      filled: true,
                      fillColor: color.secondary.withValues(alpha: 0.25),
                      hintStyle: theme.textTheme.bodyMedium,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: color.primary,
                          width: 0.4,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),

                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: color.primary,
                  elevation: 1,
                  mini: true,
                  child: Icon(Icons.send, size: 18, color: color.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Empty State ----------------

  Widget _buildEmptyState(ThemeData theme) {
    final color = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco, size: 60, color: color.primary),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "Pure Food. Pure Answers.",
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Ask me anything about our organic products.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
