// lib/features/panchang/presentation/screens/kundli_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';
import 'package:grocery_app/common_widgets/location_search_widget.dart';
import 'package:grocery_app/models/location_models.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/token_service.dart';
import '../cubit/kundli_cubit.dart';
import '../cubit/kundli_state.dart';

class KundliInputScreen extends StatefulWidget {
  const KundliInputScreen({super.key});

  @override
  State<KundliInputScreen> createState() => _KundliInputScreenState();
}

class _KundliInputScreenState extends State<KundliInputScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'New Delhi');
  final _stateController = TextEditingController(text: 'Delhi');

  late AnimationController _headerController;
  bool _saveToProfile = true;
  bool _isSubmitting = false;

  DateTime _selectedDate = DateTime(1995, 8, 15);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 30);
  double _lat = 28.6139;
  double _lon = 77.2090;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });

    try {
      final tokenUser = TokenService().currentUser;
      if (tokenUser != null) {
        final fn = tokenUser.firstName.trim();
        final ln = tokenUser.lastName.trim();
        if (fn.isNotEmpty || ln.isNotEmpty) {
          _nameController.text = '$fn $ln'.trim();
        } else if (tokenUser.username.isNotEmpty &&
            !tokenUser.username.startsWith('+') &&
            !tokenUser.username.contains('@')) {
          _nameController.text = tokenUser.username;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _headerController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final dobStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final tobStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    context.read<KundliCubit>().generateAndSaveKundli(
          name: _nameController.text.trim(),
          dateOfBirth: dobStr,
          timeOfBirth: tobStr,
          birthCity: _cityController.text.trim(),
          birthState: _stateController.text.trim(),
          latitude: _lat,
          longitude: _lon,
          saveToProfile: _saveToProfile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<KundliCubit, KundliState>(
        listener: (context, state) {
          if (_isSubmitting && state is KundliLoaded) {
            _isSubmitting = false;
            context.pushReplacement(
              '/kundli-details',
              extra: {
                'kundli': state.kundli,
                'isTemporary': state.isTemporary,
              },
            );
          } else if (state is KundliError) {
            _isSubmitting = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.softRed,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is KundliLoading && _isSubmitting;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AnimatedScreenHeader(
                  title: 'Janam Kundli',
                  subtitle: 'Enter birth details for accurate Vedic analysis',
                  showBack: true,
                  hasParticles: true,
                  animationController: _headerController,
                  actions: const [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.harvestAmber,
                      size: 26,
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.deepSoilGreen,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.white12 : AppColors.parchment),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    Icons.stars_rounded,
                                    color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Birth Details',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.charcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'For Lagna, Nakshatra & Ayurvedic Body Type',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white70 : AppColors.charcoal70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: "Person's Name (Optional)",
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.deepSoilGreen),
                              filled: true,
                              fillColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Date Picker Card
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                            ),
                            tileColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                            leading: const Icon(Icons.cake_outlined, color: AppColors.deepSoilGreen),
                            title: const Text('Date of Birth', style: TextStyle(fontSize: 14)),
                            subtitle: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            trailing: const Icon(Icons.arrow_drop_down),
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 12),
                          // Time Picker Card
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                            ),
                            tileColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                            leading: const Icon(Icons.access_time_rounded, color: AppColors.deepSoilGreen),
                            title: const Text('Time of Birth', style: TextStyle(fontSize: 14)),
                            subtitle: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            trailing: const Icon(Icons.arrow_drop_down),
                            onTap: _pickTime,
                          ),
                          const SizedBox(height: 8),

                          // Quick Time-of-Day Slots (from HTML v2.0 prototype)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildTimeSlotChip('🌅 Dawn (5 AM)', const TimeOfDay(hour: 5, minute: 0), isDark),
                              _buildTimeSlotChip('☀️ Morning (9:30 AM)', const TimeOfDay(hour: 9, minute: 30), isDark),
                              _buildTimeSlotChip('🌤 Afternoon (1 PM)', const TimeOfDay(hour: 13, minute: 0), isDark),
                              _buildTimeSlotChip('🌇 Evening (5:30 PM)', const TimeOfDay(hour: 17, minute: 30), isDark),
                              _buildTimeSlotChip('🌙 Night (8:30 PM)', const TimeOfDay(hour: 20, minute: 30), isDark),
                              _buildTimeSlotChip('🤷 Not sure (12 PM)', const TimeOfDay(hour: 12, minute: 0), isDark),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // City / Location Autocomplete Search
                          LocationSearchWidget(
                            controller: _cityController,
                            labelText: 'Birth City / Place',
                            hintText: 'Search city or birth place...',
                            prefixIcon: Icons.location_city_rounded,
                            onLocationSelected: (LocationSuggestion loc) {
                              setState(() {
                                _cityController.text = loc.city.isNotEmpty ? loc.city : loc.mainText;
                                if (loc.state.isNotEmpty) {
                                  _stateController.text = loc.state;
                                }
                                if (loc.latitude != null && loc.longitude != null) {
                                  _lat = loc.latitude!;
                                  _lon = loc.longitude!;
                                }
                              });
                            },
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter city' : null,
                          ),
                          const SizedBox(height: 12),
                          // State
                          TextFormField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              labelText: 'Birth State',
                              prefixIcon: const Icon(Icons.map_rounded, color: AppColors.deepSoilGreen),
                              filled: true,
                              fillColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Please enter state' : null,
                          ),
                          const SizedBox(height: 16),
                          // Save to Profile Toggle Card
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _saveToProfile
                                    ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen)
                                    : (isDark ? Colors.white12 : Colors.black12),
                                width: _saveToProfile ? 1.5 : 1.0,
                              ),
                            ),
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              value: _saveToProfile,
                              activeThumbColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                              title: Text(
                                'Save as Primary Kundli',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.charcoal,
                                ),
                              ),
                              subtitle: Text(
                                _saveToProfile
                                    ? 'Saves these birth details to your profile as default.'
                                    : 'Temporary check — will not overwrite your saved profile.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : AppColors.charcoal60,
                                ),
                              ),
                              onChanged: (val) => setState(() => _saveToProfile = val),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: isDark ? Colors.black : Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _saveToProfile ? 'Save & Generate Kundli' : 'View Kundli (Temporary)',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotChip(String label, TimeOfDay time, bool isDark) {
    final isSelected = _selectedTime.hour == time.hour && _selectedTime.minute == time.minute;
    return InkWell(
      onTap: () => setState(() => _selectedTime = time),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen)
              : (isDark ? AppColors.darkSurface : const Color(0xFFF5EFE0)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen)
                : (isDark ? Colors.white12 : Colors.black12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : AppColors.charcoal),
          ),
        ),
      ),
    );
  }
}
