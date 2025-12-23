// widgets/select_state.dart
import 'package:flutter/material.dart';
import '../models/location_models.dart';
import '../services/location_service.dart';

typedef StringCallback = void Function(String? value);

class SelectState extends StatefulWidget {
  final StringCallback? onCountryChanged; // kept for compatibility
  final StringCallback? onStateChanged;
  final StringCallback? onCityChanged;
  final TextStyle? style;

  const SelectState({
    Key? key,
    this.onCountryChanged,
    this.onStateChanged,
    this.onCityChanged,
    this.style,
  }) : super(key: key);

  @override
  State<SelectState> createState() => _SelectStateState();
}

class _SelectStateState extends State<SelectState> {
  final LocationService _locationService = LocationService();

  List<StateModel> _states = [];
  List<CityModel> _cities = [];

  StateModel? _selectedStateModel;
  CityModel? _selectedCityModel;

  bool _loadingStates = false;
  bool _loadingCities = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStates();
    // maintain backward compatibility: call onCountryChanged with null
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCountryChanged?.call(null);
    });
  }

  Future<void> _loadStates() async {
    setState(() {
      _loadingStates = true;
      _error = null;
    });
    try {
      final states = await _locationService.fetchStates();
      setState(() {
        _states = states;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _loadCitiesForState(StateModel stateModel) async {
    setState(() {
      _loadingCities = true;
      _error = null;
      _cities = [];
      _selectedCityModel = null;
    });
    try {
      final cities = await _locationService.fetchCities(stateId: stateModel.id);
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingCities = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // State label + dropdown
        Text('State', style: widget.style ?? theme.textTheme.labelLarge),
        const SizedBox(height: 8),

        _loadingStates
            ? SizedBox(
                height: 56,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Loading states...'),
                    ],
                  ),
                ),
              )
            : DropdownButtonFormField<String>(
                value: _selectedStateModel?.name,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select state',
                ),
                items: _states
                    .map((s) => DropdownMenuItem<String>(
                          value: s.name,
                          child: Text(s.name, style: widget.style),
                        ))
                    .toList(),
                onChanged: (String? stateName) {
                  if (stateName == null) {
                    setState(() {
                      _selectedStateModel = null;
                      _cities = [];
                      _selectedCityModel = null;
                    });
                    widget.onStateChanged?.call(null);
                    widget.onCityChanged?.call(null);
                    return;
                  }

                  final found = _states.firstWhere((s) => s.name == stateName, orElse: () => _states.first);
                  setState(() {
                    _selectedStateModel = found;
                    _selectedCityModel = null;
                    _cities = [];
                  });

                  // inform parent with state name (so your AddressSelectionScreen sets _stateController)
                  widget.onStateChanged?.call(found.name);

                  // load cities for the selected state
                  _loadCitiesForState(found);
                },
              ),

        const SizedBox(height: 16),

        // City label + dropdown
        Text('City', style: widget.style ?? theme.textTheme.labelLarge),
        const SizedBox(height: 8),

        _loadingCities
            ? SizedBox(
                height: 56,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Loading cities...'),
                    ],
                  ),
                ),
              )
            : DropdownButtonFormField<String>(
                value: _selectedCityModel?.name,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: _selectedStateModel == null ? 'Select a state first' : (_cities.isEmpty ? 'No cities available' : 'Select city'),
                ),
                items: _cities
                    .map((c) => DropdownMenuItem<String>(
                          value: c.name,
                          child: Text(c.name, style: widget.style),
                        ))
                    .toList(),
                onChanged: (_cities.isEmpty)
                    ? null
                    : (String? cityName) {
                        if (cityName == null) {
                          setState(() => _selectedCityModel = null);
                          widget.onCityChanged?.call(null);
                          return;
                        }
                        final found = _cities.firstWhere((c) => c.name == cityName, orElse: () => _cities.first);
                        setState(() => _selectedCityModel = found);

                        // inform parent with city name (so your AddressSelectionScreen sets _cityController)
                        widget.onCityChanged?.call(found.name);
                      },
              ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text('Error: $_error', style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}
