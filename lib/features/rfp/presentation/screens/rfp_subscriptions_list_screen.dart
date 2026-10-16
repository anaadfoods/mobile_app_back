import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common_widgets/modern_back_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../service_locator.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/usecases/get_my_subscriptions_use_case.dart';
import '../widgets/rfp_subscription_card.dart';
import '../widgets/rfp_subscriptions_empty_view.dart';
import 'rfp_dashboard_screen.dart';

/// Screen listing customer's Remote Farming Program subscriptions.
/// Conforms to Section 18 of RFP Customer Flow Specification.
class RfpSubscriptionsListScreen extends StatefulWidget {
  final GetMySubscriptionsUseCase? getMySubscriptions;

  const RfpSubscriptionsListScreen({super.key, this.getMySubscriptions});

  @override
  State<RfpSubscriptionsListScreen> createState() =>
      _RfpSubscriptionsListScreenState();
}

class _RfpSubscriptionsListScreenState
    extends State<RfpSubscriptionsListScreen> {
  late final GetMySubscriptionsUseCase _getMySubscriptions;

  List<RfpBooking> _subscriptions = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0; // 0: All, 1: Active, 2: Upcoming, 3: History

  List<RfpBooking> get _filteredSubscriptions {
    switch (_selectedTab) {
      case 1:
        return _subscriptions
            .where((s) => s.status.toLowerCase() == 'active')
            .toList();
      case 2:
        return _subscriptions.where((s) {
          final st = s.status.toLowerCase();
          return st == 'pending' ||
              st == 'upcoming' ||
              st == 'prebooked' ||
              !s.bookingPaid;
        }).toList();
      case 3:
        return _subscriptions.where((s) {
          final st = s.status.toLowerCase();
          return st == 'completed' || st == 'cancelled';
        }).toList();
      default:
        return _subscriptions;
    }
  }

  @override
  void initState() {
    super.initState();
    _getMySubscriptions =
        widget.getMySubscriptions ?? getIt<GetMySubscriptionsUseCase>();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subs = await _getMySubscriptions();
      if (mounted) {
        setState(() {
          _subscriptions = subs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: ModernBackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'MY SUBSCRIPTIONS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.parchment,
        backgroundColor: AppColors.deepSoilGreen,
        onRefresh: _fetchSubscriptions,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.amberWarn,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load subscriptions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchSubscriptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepSoilGreen,
                      foregroundColor: AppColors.parchment,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_subscriptions.isEmpty) {
      return const RfpSubscriptionsEmptyView();
    }

    final filtered = _filteredSubscriptions;

    return Column(
      children: [
        _buildFilterTabs(context),
        Expanded(
          child:
              filtered.isEmpty
                  ? _buildTabEmptyState(context)
                  : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder:
                        (context, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final booking = filtered[index];
                      return RfpSubscriptionCard(
                        booking: booking,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => RfpDashboardScreen(
                                    initialBooking: booking,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final activeCount =
        _subscriptions.where((s) => s.status.toLowerCase() == 'active').length;
    final upcomingCount =
        _subscriptions.where((s) {
          final st = s.status.toLowerCase();
          return st == 'pending' ||
              st == 'upcoming' ||
              st == 'prebooked' ||
              !s.bookingPaid;
        }).length;
    final historyCount =
        _subscriptions.where((s) {
          final st = s.status.toLowerCase();
          return st == 'completed' || st == 'cancelled';
        }).length;

    final tabs = [
      'All (${_subscriptions.length})',
      'Active ($activeCount)',
      'Upcoming ($upcomingCount)',
      'History ($historyCount)',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected
                          ? AppColors.parchment
                          : AppColors.deepSoilGreen,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.deepSoilGreen,
              backgroundColor: AppColors.deepSoilGreen.withValues(alpha: 0.08),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.deepSoilGreen : Colors.transparent,
                ),
              ),
              onSelected: (_) => setState(() => _selectedTab = index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabEmptyState(BuildContext context) {
    final titles = [
      'No Subscriptions',
      'No Active Subscriptions',
      'No Upcoming Subscriptions',
      'No Subscription History',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 12),
            Text(
              titles[_selectedTab],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No items found under this category.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 3,
      separatorBuilder: (context, _) => const SizedBox(height: 16),
      itemBuilder: (context, _) {
        return Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
