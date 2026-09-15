import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../../domain/entities/chat_session.dart';

class ChatSessionsDrawer extends StatelessWidget {
  final List<ChatSession> sessions;
  final String? activeSessionId;
  final Function(String) onSelect;
  final Function(String) onDelete;
  final Function(String, String) onRename;
  final VoidCallback onNewChat;

  const ChatSessionsDrawer({
    Key? key,
    required this.sessions,
    this.activeSessionId,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
    required this.onNewChat,
  }) : super(key: key);

  void _showRenameDialog(BuildContext context, ChatSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Conversation'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter new title'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final newTitle = controller.text.trim();
                  if (newTitle.isNotEmpty) {
                    onRename(session.sessionId, newTitle);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Conversations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.harvestAmber,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Chat'),
                    onPressed: () {
                      onNewChat();
                      Navigator.pop(context); // Close drawer
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  sessions.isEmpty
                      ? const Center(
                        child: Text(
                          'No conversations yet.\nStart chatting!',
                          textAlign: TextAlign.center,
                        ),
                      )
                      : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final isActive = session.sessionId == activeSessionId;

                          return Dismissible(
                            key: Key(session.sessionId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: AppColors.softRed,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16.0),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) {
                              onDelete(session.sessionId);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border:
                                    isActive
                                        ? const Border(
                                          left: BorderSide(
                                            color: AppColors.deepSoilGreen,
                                            width: 4.0,
                                          ),
                                        )
                                        : null,
                                color:
                                    isActive
                                        ? AppColors.deepSoilGreen.withOpacity(
                                          0.05,
                                        )
                                        : null,
                              ),
                              child: ListTile(
                                title: Text(
                                  session.title.isNotEmpty
                                      ? session.title
                                      : 'New Chat',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight:
                                        isActive
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  'Messages: ${session.messageCount}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () {
                                  onSelect(session.sessionId);
                                  Navigator.pop(context);
                                },
                                onLongPress:
                                    () => _showRenameDialog(context, session),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
