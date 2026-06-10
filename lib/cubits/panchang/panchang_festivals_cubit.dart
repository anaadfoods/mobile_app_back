import 'package:grocery_app/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helpers/app_error_helper.dart';
import '../../models/panchang/panchang_festival_models.dart';
import '../../repositories/panchang_repository.dart';
import 'panchang_festivals_state.dart';

class PanchangFestivalsCubit extends Cubit<PanchangFestivalsState> {
  final PanchangRepository _repository;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String? _filterType;
  String _searchQuery = '';

  PanchangFestivalsCubit({required PanchangRepository repository})
      : _repository = repository,
        super(const PanchangFestivalsInitial());

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String? get filterType => _filterType;
  String get searchQuery => _searchQuery;

  /// Load festivals for current month
  Future<void> loadCurrentMonth() async {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // Last day of month
    await _loadFestivals();
  }

  /// Load festivals for a specific month
  Future<void> loadMonth(int year, int month) async {
    _startDate = DateTime(year, month, 1);
    _endDate = DateTime(year, month + 1, 0);
    await _loadFestivals();
  }

  /// Load festivals for next 60 days (upcoming)
  Future<void> loadUpcoming() async {
    final now = DateTime.now();
    _startDate = now;
    // API has max 62 days limit, so fetch next 60 days
    _endDate = now.add(const Duration(days: 60));
    await _loadFestivals();
  }

  /// Load festivals for a custom date range
  Future<void> loadDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    await _loadFestivals();
  }

  /// Load festivals for next 60 days (API limit is 62)
  Future<void> loadYear(int year) async {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now.add(const Duration(days: 60));
    await _loadFestivals();
  }

  /// Load festivals for entire year (makes multiple API calls)
  Future<void> loadFullYear(int year) async {
    try {
      if (isClosed) return;
      emit(const PanchangFestivalsLoading());

      AppLogger.instance.log('🔥 Starting loadFullYear for year: $year');
      
      final startOfPeriod = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31);
      
      AppLogger.instance.log('🔥 Date range: $startOfPeriod to $endOfYear');
      
      // Split into 60-day chunks
      final List<DateTime> chunkStarts = [];
      DateTime currentStart = startOfPeriod;

      while (currentStart.isBefore(endOfYear)) {
        chunkStarts.add(currentStart);
        currentStart = currentStart.add(const Duration(days: 60));
      }

      // Fetch chunks in parallel batches (2 at a time to avoid overwhelming the server)
      final Map<String, FestivalDateGroup> festivalsByDate = {};
      int totalFestivals = 0;

      for (int i = 0; i < chunkStarts.length; i += 2) {
        if (isClosed) return;
        
        AppLogger.instance.log('🔥 Processing batch ${(i ~/ 2) + 1} of ${(chunkStarts.length / 2).ceil()}');
        
        final futures = <Future<PanchangFestivalsResponse>>[];
        
        for (int j = i; j < i + 2 && j < chunkStarts.length; j++) {
          final chunkStart = chunkStarts[j];
          DateTime chunkEnd = chunkStart.add(const Duration(days: 59));
          if (chunkEnd.isAfter(endOfYear)) {
            chunkEnd = endOfYear;
          }
          
          AppLogger.instance.log('🔥 Adding chunk: $chunkStart to $chunkEnd');
          
          futures.add(_repository.getFestivals(
            startDate: chunkStart,
            endDate: chunkEnd,
            type: _filterType,
          ));
        }

        // Wait for batch to complete - allow individual failures
        AppLogger.instance.log('🔥 Waiting for ${futures.length} API calls...');
        final results = await Future.wait(
          futures,
          eagerError: false,
        );
        
        int successCount = 0;
        for (int k = 0; k < results.length; k++) {
          try {
            final response = results[k];
            successCount++;
            
            // Merge festivals by date to avoid duplicates
            for (final dateGroup in response.festivals) {
              if (festivalsByDate.containsKey(dateGroup.date)) {
                // Merge festivals for same date
                final existing = festivalsByDate[dateGroup.date]!;
                final allFestivals = [...existing.festivals, ...dateGroup.festivals];
                festivalsByDate[dateGroup.date] = FestivalDateGroup(
                  date: dateGroup.date,
                  dayOfWeek: dateGroup.dayOfWeek,
                  tithi: dateGroup.tithi,
                  masa: dateGroup.masa,
                  paksha: dateGroup.paksha,
                  festivals: allFestivals,
                );
              } else {
                festivalsByDate[dateGroup.date] = dateGroup;
              }
            }
            totalFestivals += response.metadata.totalFestivals;
          } catch (e) {
            AppLogger.instance.log('🔥 Warning: Failed to process chunk ${k + 1}: $e');
            // Continue with other successful chunks
          }
        }
        AppLogger.instance.log('🔥 Batch completed: $successCount/${results.length} chunks successful');
      }

      if (isClosed) return;
      
      AppLogger.instance.log('🔥 Merging complete. Total unique dates: ${festivalsByDate.length}');
      AppLogger.instance.log('🔥 Total festivals: $totalFestivals');
      
      // Sort by date and create list
      final sortedDates = festivalsByDate.keys.toList()..sort();
      final allFestivals = sortedDates.map((date) => festivalsByDate[date]!).toList();
      
      AppLogger.instance.log('🔥 Creating combined response with ${allFestivals.length} date groups');
      
      // Create combined response
      final combinedResponse = PanchangFestivalsResponse(
        festivals: allFestivals,
        metadata: FestivalsMetadata(
          startDate: startOfPeriod.toString().split(' ')[0],
          endDate: endOfYear.toString().split(' ')[0],
          totalFestivals: totalFestivals,
          totalDays: allFestivals.length,
        ),
      );

      _startDate = startOfPeriod;
      _endDate = endOfYear;

      AppLogger.instance.log('🔥 Emitting success state');
      
      emit(PanchangFestivalsSuccess(
        response: combinedResponse,
        startDate: startOfPeriod,
        endDate: endOfYear,
        filterType: _filterType,
      ));
      
      AppLogger.instance.log('🔥 loadFullYear completed successfully');
    } catch (e, stackTrace) {
      AppLogger.instance.log('🔥 ERROR in loadFullYear: $e');
      AppLogger.instance.log('🔥 Stack trace: $stackTrace');
      if (isClosed) return;
      emit(PanchangFestivalsError(AppErrorHelper.getErrorMessage(e)));
    }
  }

  /// Apply filter by festival type
  Future<void> applyFilter(String? type) async {
    _filterType = type;
    await _loadFestivals();
  }

  /// Search festivals
  Future<void> searchFestivals(String query, {int? year}) async {
    if (query.trim().isEmpty) {
      await _loadFestivals();
      return;
    }

    try {
      if (isClosed) return;
      _searchQuery = query;
      emit(const PanchangFestivalsSearching());

      final response = await _repository.searchFestivals(
        query: query,
        type: _filterType,
        year: year,
      );

      if (isClosed) return;
      emit(PanchangFestivalsSearchSuccess(
        response: response,
        query: query,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(PanchangFestivalsError(AppErrorHelper.getErrorMessage(e)));
    }
  }

  /// Clear search and return to list view
  Future<void> clearSearch() async {
    _searchQuery = '';
    await _loadFestivals();
  }

  /// Navigate to previous period
  Future<void> previousPeriod() async {
    final duration = _endDate.difference(_startDate);
    _endDate = _startDate.subtract(const Duration(days: 1));
    _startDate = _endDate.subtract(duration);
    await _loadFestivals();
  }

  /// Navigate to next period
  Future<void> nextPeriod() async {
    final duration = _endDate.difference(_startDate);
    _startDate = _endDate.add(const Duration(days: 1));
    _endDate = _startDate.add(duration);
    await _loadFestivals();
  }

  Future<void> _loadFestivals() async {
    try {
      if (isClosed) return;
      emit(const PanchangFestivalsLoading());

      final response = await _repository.getFestivals(
        startDate: _startDate,
        endDate: _endDate,
        type: _filterType,
      );

      if (isClosed) return;
      emit(PanchangFestivalsSuccess(
        response: response,
        startDate: _startDate,
        endDate: _endDate,
        filterType: _filterType,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(PanchangFestivalsError(AppErrorHelper.getErrorMessage(e)));
    }
  }

  /// Reload current data
  Future<void> refresh() async {
    if (_searchQuery.isNotEmpty) {
      await searchFestivals(_searchQuery);
    } else {
      await _loadFestivals();
    }
  }
}
