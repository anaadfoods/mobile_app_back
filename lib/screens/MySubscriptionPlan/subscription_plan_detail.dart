import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:intl/intl.dart';


class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  List<Subscription> allSubscriptions = [];
  List<Subscription> filteredSubscriptions = [];
  String currentFilter = "All";

  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<void> _fetchSubscriptions() async {
    try {
      final response = await _subscriptionService.getSubscriptions();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          allSubscriptions = data.map((item) => item as Subscription).toList();
          _filterSubscriptions(currentFilter);
        });
      } else {
        print('Error fetching subscriptions: ${response['message']}');
        SnackBarHelper.showError(
          context,
          response['message'] ?? 'Failed to fetch subscriptions',
        );
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      SnackBarHelper.showError(
        context,
        'An error occurred while fetching subscriptions',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch subscriptions immediately when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptions();
    });
  }

  void _filterSubscriptions(String status) {
    setState(() {
      currentFilter = status;
      if (status == "All") {
        filteredSubscriptions = allSubscriptions;
      } else {
        filteredSubscriptions =
            allSubscriptions
                .where((subscription) => subscription.status == status)
                .toList();
      }
    });
  }




  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Subscriptions"),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: _fetchSubscriptions,
              icon: Icon(Icons.refresh_sharp),
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              if (index == 0) _filterSubscriptions("ACTIVE");
              if (index == 1) _filterSubscriptions("PAUSED");
              if (index == 2) _filterSubscriptions("CANCELLED");
              if (index == 3) _filterSubscriptions("COMPLETED");
            },
            tabs: [
              Tab(text: "Active" , ),
              Tab(text: "Paused"),
              Tab(text: "Cancelled"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: _buildSubscriptionList(),
      ),
    );
  }

Widget _buildSubscriptionList() {
  if (filteredSubscriptions.isEmpty) {
    return Center(child: Text("No matching subscriptions found"));
  }





  return RefreshIndicator(
    onRefresh: _fetchSubscriptions,
    child: ListView.builder(
      itemCount: filteredSubscriptions.length,
      itemBuilder: (context, index) {
        final subscription = filteredSubscriptions[index];
bool _isLoading = true;

 Future<void> _togglePauseSubscription(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    setState(() => _isLoading = true);
    try {
      final response = await _subscriptionService.togglePauseSubscription(
        subscription.id,
      startDate,
        endDate,
      );

      if (response['success'] == true) {
        SnackBarHelper.showSuccess(
          context,
          response['details'] ?? 'Subscription status updated successfully',
        );
        // Refresh the subscription data
        Navigator.pop(context, true);
      } else {
        SnackBarHelper.showError(
          context,
          response['details'] ?? 'Failed to update subscription status',
        );
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Replace your old _showToggleConfirmation with this new one
void _showToggleConfirmation(Subscription subscription) {
  final isCurrentlyPaused = subscription.status == 'PAUSED';
  final maxPausesLeft = subscription.remainingPauseTimes;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  DateTime? selectedNextDeliveryDate; // For the UI element, not used in current logic

  // For resuming, we can keep the simpler dialog.
  if (isCurrentlyPaused) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Subscription?'),
        content: const Text('Are you sure you want to resume this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Call with null dates to resume
              _togglePauseSubscription( null, null);
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return;
  }

  // For pausing, show the new styled dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final Color primaryColor = const Color(0xFF9F814F);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Title and Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Pause From",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                           decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black54)
                           ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // From & To Date Pickers
                  Row(
                    children: [
                      _buildStyledDateField(
                        context: context,
                        label: "From",
                        selectedDate: selectedStartDate,
                        isSelected: true, // This one has the border
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedStartDate = date);
                          }
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("To"),
                      ),
                      _buildStyledDateField(
                        context: context,
                        label: "To",
                        selectedDate: selectedEndDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate ?? DateTime.now(),
                            firstDate: selectedStartDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedEndDate = date);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Set Next Delivery Date
                  const Text(
                    "Set Next Delivery To",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       _buildStyledDateField(
                         context: context,
                         label: "Select Date",
                         selectedDate: selectedNextDeliveryDate,
                         onTap: () async {
                           final date = await showDatePicker(
                             context: context,
                             initialDate: DateTime.now(),
                             firstDate: DateTime.now(),
                             lastDate: DateTime.now().add(const Duration(days: 365)),
                           );
                           if (date != null) {
                              setState(() => selectedNextDeliveryDate = date);
                           }
                         },
                       ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // --- PRESERVED LOGIC ---
                        if (selectedStartDate == null || selectedEndDate == null) {
                          SnackBarHelper.showError(context, 'Please select both start and end dates');
                          return;
                        }
                        if (selectedEndDate!.isBefore(selectedStartDate!)) {
                          SnackBarHelper.showError(context, 'End date must be after start date');
                          return;
                        }
                        if (maxPausesLeft <= 0) {
                          SnackBarHelper.showError(context, 'No pauses remaining for this subscription');
                          return;
                        }
                        _togglePauseSubscription( selectedStartDate, selectedEndDate);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}




  //       void _showToggleConfirmation() {
  //   final isCurrentlyPaused = subscription.status == 'PAUSED';
  //   final maxPausesLeft = subscription.remainingPauseTimes;
  //   DateTime? selectedStartDate;
  //   DateTime? selectedEndDate;

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: Text(
  //               isCurrentlyPaused
  //                   ? 'Resume Now?'
  //                   : 'Pause From?',
  //                   style: TextStyle(
  //                     fontSize: 18,

  //                     fontWeight: FontWeight.bold
  //                   ),
  //             ),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   isCurrentlyPaused
  //                       ? 'Are you sure you want to resume this subscription?'
  //                       : 'Are you sure you want to pause this subscription?',
  //                 ),
  //                 SizedBox(height: 16),
  //                 if (!isCurrentlyPaused) ...[
  //                   Text(
  //                     'Pauses remaining: $maxPausesLeft',
  //                     style: TextStyle(
  //                       color:
  //                           maxPausesLeft > 0
  //                               ? Colors.green[700]
  //                               : Colors.red[700],
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   // SizedBox(height: 16),
  //                   // Text(
  //                   //   'Select Pause Period:',
  //                   //   style: TextStyle(
  //                   //     fontWeight: FontWeight.bold,
  //                   //     fontSize: 16,
  //                   //   ),
  //                   // ),
  //                   SizedBox(height: 8),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             TextButton(
  //                               onPressed: () async {
  //                                 final date = await showDatePicker(
  //                                   context: context,
  //                                   initialDate: DateTime.now(),
  //                                   firstDate: DateTime.now(),
  //                                   lastDate: DateTime.now().add(
  //                                     Duration(days: 365),
  //                                   ),
  //                                 );
  //                                 if (date != null) {
  //                                   setState(() {
  //                                     selectedStartDate = date;
  //                                   });
  //                                 }
  //                               },
  //                               child: Text(
  //                                 selectedStartDate != null
  //                                     ? '${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year}'
  //                                     : 'From',
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                       SizedBox(width: 8),
  //                       Expanded(
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             TextButton(
  //                               onPressed: () async {
  //                                 final date = await showDatePicker(
  //                                   context: context,
  //                                   initialDate:
  //                                       selectedStartDate ?? DateTime.now(),
  //                                   firstDate:
  //                                       selectedStartDate ?? DateTime.now(),
  //                                   lastDate: DateTime.now().add(
  //                                     Duration(days: 365),
  //                                   ),
  //                                 );
  //                                 if (date != null) {
  //                                   setState(() {
  //                                     selectedEndDate = date;
  //                                   });
  //                                 }
  //                               },
  //                               child: Text(
  //                                 selectedEndDate != null
  //                                     ? '${selectedEndDate!.day}/${selectedEndDate!.month}/${selectedEndDate!.year}'
  //                                     : 'To',
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.of(context).pop(),
  //                 child: Text('Cancel'),
  //               ),
  //               TextButton(
  //                 onPressed: () {
  //                   if (!isCurrentlyPaused) {
  //                     if (selectedStartDate == null ||
  //                         selectedEndDate == null) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(
  //                           content: Text(
  //                             'Please select both start and end dates',
  //                           ),
  //                           backgroundColor: Colors.red,
  //                         ),
  //                       );
  //                       return;
  //                     }
  //                     if (selectedEndDate!.isBefore(selectedStartDate!)) {
  //                       SnackBarHelper.showError(
  //                         context,
  //                         'End date must be after start date',
  //                       );
  //                       return;
  //                     }
  //                   }

  //                   if (!isCurrentlyPaused && maxPausesLeft <= 0) {
  //                     Navigator.of(context).pop();
  //                     SnackBarHelper.showError(
  //                       context,
  //                       'No pauses remaining for this subscription',
  //                     );
  //                     return;
  //                   }

  //                   _togglePauseSubscription(
  //                     isCurrentlyPaused ? null : selectedStartDate,
  //                     isCurrentlyPaused ? null : selectedEndDate,
  //                   );
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: Text('Confirm'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionPlanDetailScreen(
                  subscription: subscription,
                ),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder for product image
                      Column(
                        children: [ Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Subscription - ${subscription.planName}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                             ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (subscription.items.isNotEmpty &&
                        subscription.items[0].imageUrl != null &&
                        subscription.items[0].imageUrl!.isNotEmpty)
                    // If the image list is NOT empty, show the first image
                    ? CachedNetworkImage(
                        imageUrl: subscription.items[0].imageUrl!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        // Show a loading spinner while the image loads
                        placeholder: (context, url) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        // Show an error icon if the image fails to load
                        errorWidget: (context, url, error) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      )
                    // If the image list IS empty, show a fallback icon
                    : Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
              ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tag + Next Delivery + Payment Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                               
                                Text(
                                  'Next Delivery: ${subscription.nextDeliveryDate.toString().split(' ')[0]}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  subscription.installmentPaymentStatus == "PENDING"
                                      ? "Pending"
                                      : "Paid",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subscription.installmentPaymentStatus == "PENDING"
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Product info
                            Text(
                              subscription.items[0].productName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            // Price line
                            Row(
                              children: [
                                Text(
                                  subscription.items[0].discountedPrice.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  subscription.items[0].price.toString(),
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                           
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Pause/Resume Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                      
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bottonBackgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: Icon(
                            subscription.status == "PAUSED"
                                ? Icons.play_arrow
                                : Icons.pause,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            subscription.status == "PAUSED" ? "Resume" : "Pause",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            _showToggleConfirmation(subscription);
                      // showPauseDialog(context);
                            // Optional: Implement pause/resume here or redirect
                          },
                        ),
                      ),
                    ),
                     Container(
                      width: 150,
                       child: Text(
                              '${(subscription.totalDeliveries)-(subscription.completedDeliveries)} /${subscription.totalDeliveries} Deliveries Left'  ,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:AppColors.bottonBackgroundColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                     ),
                       Container(
                      width: 100,
                       child: Text(
                              ""  ,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:AppColors.bottonBackgroundColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                     ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}


    }





void showPauseDialog(BuildContext context) {
  DateTime? fromDate;
  DateTime? toDate;
  DateTime? nextDeliveryDate;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, size: 24),
                    ),
                  ),

                  SizedBox(height: 4),

                  /// Title
                  Text(
                    "Pause From",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 16),

                  /// From & To Date Pickers
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          context,
                          label: "From",
                          selectedDate: fromDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => fromDate = picked);
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("To"),
                      ),
                      Expanded(
                        child: _buildDateField(
                          context,
                          label: "To",
                          selectedDate: toDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fromDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => toDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  /// Set Next Delivery To
                  Text(
                    "Set Next Delivery To",
                    style: TextStyle(
                      color: Colors.brown[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  _buildDateField(
                    context,
                    label: "Select Date",
                    selectedDate: nextDeliveryDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => nextDeliveryDate = picked);
                      }
                    },
                  ),

                  SizedBox(height: 24),

                  /// Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {



                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[400],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// Add this helper method inside your _SubscriptionScreenState class
Widget _buildStyledDateField({
  required BuildContext context,
  required String label,
  required DateTime? selectedDate,
  required VoidCallback onTap,
  bool isSelected = false,
}) {
  final Color primaryColor = const Color(0xFF9F814F); // Gold/Brown color
  final Color fillColor = const Color(0xFFFAF6ED); // Light beige fill color
  final DateFormat formatter = DateFormat('dd MMM yyyy');

  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : fillColor,
          border: isSelected ? Border.all(color: primaryColor, width: 1.5) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              selectedDate != null ? formatter.format(selectedDate) : label,
              style: TextStyle(
                color: primaryColor,
                fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDateField(
  BuildContext context, {
  required String label,
  required DateTime? selectedDate,
  required VoidCallback onTap,
}) {
  final hasDate = selectedDate != null;
  final text = hasDate
      ? DateFormat('dd MMM yyyy').format(selectedDate!)
      : label;

  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: hasDate ? Colors.brown[50] : Colors.transparent,
        border: Border.all(color: Colors.brown, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.brown),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: hasDate ? Colors.black : Colors.brown,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
