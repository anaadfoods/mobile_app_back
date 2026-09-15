import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/content_config_service.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/service_locator.dart';

/// Professional Chat Input Bar with Active Tool Badges & Floating / Trigger Overlay.
class ChatInputBar extends StatefulWidget {
  final Function(String message, {File? file}) onSend;
  final bool isLoading;

  const ChatInputBar({Key? key, required this.onSend, this.isLoading = false})
    : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  File? _selectedFile;
  Map<String, dynamic>? _selectedTool;
  bool _showToolMenu = false;

  List<Map<String, dynamic>> _apiTools = [
    {
      "trigger": "/products",
      "alias": "@products",
      "name": "Products & Organic Catalog",
      "icon": Icons.shopping_bag_rounded,
      "color": AppColors.deepSoilGreen,
      "query": "Show available organic food products and thalis",
    },
    {
      "trigger": "/orders",
      "alias": "@orders",
      "name": "Track Active Orders",
      "icon": Icons.local_shipping_rounded,
      "color": AppColors.harvestAmber,
      "query": "Check status of my active orders",
    },
    {
      "trigger": "/subscriptions",
      "alias": "@subscriptions",
      "name": "Monthly Subscriptions",
      "icon": Icons.calendar_month_rounded,
      "color": AppColors.infoTeal,
      "query": "View monthly organic thali subscription plans",
    },
    {
      "trigger": "/health_report",
      "alias": "@health_report",
      "name": "Analyze Health Report",
      "icon": Icons.document_scanner_rounded,
      "color": AppColors.rawEarth,
      "query":
          "Analyze my uploaded health report for Ayurvedic recommendations",
    },
    {
      "trigger": "/ayurveda",
      "alias": "@ayurveda",
      "name": "Ayurvedic Health & Diet Tips",
      "icon": Icons.spa_rounded,
      "color": AppColors.deepSoilGreen,
      "query":
          "Give me Ayurvedic health and dietary guidance for daily wellness",
    },
    {
      "trigger": "/diet",
      "alias": "@diet",
      "name": "Personalized Diet Recommendations",
      "icon": Icons.restaurant_rounded,
      "color": AppColors.harvestAmber,
      "query": "Suggest personalized Ayurvedic meals for my dosha",
    },
    {
      "trigger": "/panchang",
      "alias": "@panchang",
      "name": "Today's Vedic Panchang",
      "icon": Icons.wb_sunny_rounded,
      "color": AppColors.softGold,
      "query": "What are today's auspicious timings, tithi, and muhurat?",
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _loadToolsFromApi();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadToolsFromApi() async {
    try {
      final tokenService = getIt<TokenService>();
      final token = await tokenService.getAccessToken();
      if (token == null) return;
      final apiTools = await ContentConfigService().fetchAgentTools(token: token);
      if (apiTools.isNotEmpty && mounted) {
        setState(() {
          _apiTools = apiTools.map((t) => {
            'trigger': t['trigger'] ?? '',
            'alias': t['alias'] ?? '',
            'name': t['name_en'] ?? t['trigger'] ?? '',
            'icon': _resolveToolIcon(t['trigger'] as String? ?? ''),
            'color': AppColors.deepSoilGreen,
            'query': t['default_query_en'] ?? '',
          }).toList();
        });
      }
    } catch (_) {
      // Keep hardcoded fallback
    }
  }

  IconData _resolveToolIcon(String trigger) {
    const iconMap = {
      '/products': Icons.shopping_bag_rounded,
      '/orders': Icons.local_shipping_rounded,
      '/subscriptions': Icons.calendar_month_rounded,
      '/health_report': Icons.document_scanner_rounded,
      '/ayurveda': Icons.spa_rounded,
      '/diet': Icons.restaurant_rounded,
      '/panchang': Icons.wb_sunny_rounded,
    };
    return iconMap[trigger] ?? Icons.auto_awesome_rounded;
  }

  void _onTextChanged() {
    final text = _controller.text;
    final lastWord = text.split(' ').last;
    if (lastWord.startsWith('/') || lastWord.startsWith('@')) {
      if (!_showToolMenu) {
        setState(() {
          _showToolMenu = true;
        });
      }
    } else if (_showToolMenu && !text.contains('/') && !text.contains('@')) {
      setState(() {
        _showToolMenu = false;
      });
    }
  }

  void _selectTool(Map<String, dynamic> tool) {
    setState(() {
      _selectedTool = tool;
      _showToolMenu = false;
      _controller.clear(); // Keep input field clean for user's query
    });
  }

  void _handleSend() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty && _selectedFile == null && _selectedTool == null)
      return;

    // Behind-the-scenes tool prompt composition
    String finalPayload = rawText;
    if (_selectedTool != null) {
      final trigger = _selectedTool!['trigger'] as String;
      final defaultQuery = _selectedTool!['query'] as String;
      if (rawText.isNotEmpty) {
        finalPayload = "$trigger: $rawText";
      } else {
        finalPayload = defaultQuery;
      }
    }

    widget.onSend(finalPayload, file: _selectedFile);
    _controller.clear();
    setState(() {
      _selectedFile = null;
      _selectedTool = null;
      _showToolMenu = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'docx', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend =
        _controller.text.trim().isNotEmpty ||
        _selectedFile != null ||
        _selectedTool != null;

    final lastWord = _controller.text.split(' ').last.toLowerCase();
    final isAtMode = lastWord.startsWith('@');
    final filterText = lastWord.replaceAll('/', '').replaceAll('@', '');

    final filteredTools =
        _apiTools.where((t) {
          if (filterText.isEmpty) return true;
          final trigger = (t["trigger"] as String).toLowerCase();
          final alias = (t["alias"] as String).toLowerCase();
          final name = (t["name"] as String).toLowerCase();
          return trigger.contains(filterText) ||
              alias.contains(filterText) ||
              name.contains(filterText);
        }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Floating Tool Selection Menu (/ or @ trigger) ──
        if (_showToolMenu && filteredTools.isNotEmpty)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  itemCount: filteredTools.length,
                  separatorBuilder:
                      (_, __) => const Divider(height: 1, thickness: 0.4),
                  itemBuilder: (context, index) {
                    final tool = filteredTools[index];
                    final IconData icon = tool["icon"] as IconData;
                    final Color iconColor = tool["color"] as Color;
                    final String trigger = isAtMode
                        ? (tool["alias"] as String)
                        : (tool["trigger"] as String);
                    final String name = tool["name"] as String;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 2.0,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 18, color: iconColor),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.charcoal,
                        ),
                      ),
                      subtitle: Text(
                        trigger,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _selectTool(tool),
                    );
                  },
                ),
              ),
            ),
          ),

        // ── Main Input Bar ──
        Container(
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 8.0,
            bottom: MediaQuery.of(context).padding.bottom + 8.0,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Selected Tool Tile Badge & File Chip
              Row(
                children: [
                  if (_selectedTool != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: (_selectedTool!['color'] as Color).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTool!['color'] as Color,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedTool!['icon'] as IconData,
                            size: 14,
                            color: _selectedTool!['color'] as Color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Tool: ${_selectedTool!['name']}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTool = null;
                              });
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Chip(
                        label: Text(
                          _selectedFile!.path.split('/').last,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ),
                ],
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment / Image Upload Icon on Left Hand
                  IconButton(
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      size: 22,
                    ),
                    onPressed: _pickFile,
                    tooltip: 'Attach Image / Document',
                  ),

                  // Input Text Area
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _controller,
                        maxLines: 5,
                        minLines: 1,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.charcoal,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              _selectedTool != null
                                  ? "Type query for ${_selectedTool!['name']}..."
                                  : "Ask anything about diet, health, orders...",
                          hintStyle: TextStyle(
                            fontSize: 12.8,
                            color: isDark ? Colors.white38 : AppColors.charcoal40,
                          ),
                          fillColor:
                              isDark
                                  ? AppColors.darkCanvas
                                  : AppColors.parchment,
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: CircleAvatar(
                      backgroundColor:
                          canSend && !widget.isLoading
                              ? AppColors.harvestAmber
                              : (isDark ? Colors.white12 : Colors.grey.shade300),
                      radius: 17,
                      child:
                          widget.isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: canSend ? Colors.white : (isDark ? Colors.white30 : Colors.black26),
                                  size: 18,
                                ),
                                onPressed:
                                    canSend && !widget.isLoading
                                        ? _handleSend
                                        : null,
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
