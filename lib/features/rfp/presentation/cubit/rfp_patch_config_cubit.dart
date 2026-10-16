import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_patch.dart';
import '../../domain/entities/rfp_patch_config.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class RfpPatchConfigState extends Equatable {
  final RfpPatch? patch;
  final Set<String> excludedVegetableIds;
  final double selectedWeight;
  final String deliveryFrequency;
  final bool isSaved;

  const RfpPatchConfigState({
    this.patch,
    this.excludedVegetableIds = const {},
    this.selectedWeight = 5.0,
    this.deliveryFrequency = 'twice_a_week',
    this.isSaved = false,
  });

  int get exclusionsUsed => excludedVegetableIds.length;
  int get maxExclusions => patch?.maxExclusions ?? 0;
  int get exclusionsRemaining => maxExclusions - exclusionsUsed;
  bool get canExcludeMore => exclusionsRemaining > 0;

  bool isExcluded(String vegId) => excludedVegetableIds.contains(vegId);

  RfpPatchConfig toConfig() => RfpPatchConfig(
    patchId: patch?.id ?? '',
    patchLabel: patch?.label ?? '',
    excludedVegetableIds: excludedVegetableIds.toList(),
    selectedWeight: selectedWeight,
    deliveryFrequency: deliveryFrequency,
  );

  RfpPatchConfigState copyWith({
    RfpPatch? patch,
    Set<String>? excludedVegetableIds,
    double? selectedWeight,
    String? deliveryFrequency,
    bool? isSaved,
  }) {
    return RfpPatchConfigState(
      patch: patch ?? this.patch,
      excludedVegetableIds: excludedVegetableIds ?? this.excludedVegetableIds,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      deliveryFrequency: deliveryFrequency ?? this.deliveryFrequency,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [
    patch,
    excludedVegetableIds,
    selectedWeight,
    deliveryFrequency,
    isSaved,
  ];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class RfpPatchConfigCubit extends Cubit<RfpPatchConfigState> {
  RfpPatchConfigCubit() : super(const RfpPatchConfigState());

  void loadPatch(RfpPatch patch, {RfpPatchConfig? existingConfig}) {
    if (existingConfig != null) {
      emit(
        RfpPatchConfigState(
          patch: patch,
          excludedVegetableIds: existingConfig.excludedVegetableIds.toSet(),
          selectedWeight: existingConfig.selectedWeight,
          deliveryFrequency: existingConfig.deliveryFrequency,
        ),
      );
    } else {
      emit(
        RfpPatchConfigState(
          patch: patch,
          selectedWeight:
              patch.availableWeights.length > 1
                  ? patch.availableWeights[1]
                  : patch.availableWeights.first,
        ),
      );
    }
  }

  void toggleVegetableExclusion(String vegetableId) {
    final excluded = Set<String>.from(state.excludedVegetableIds);
    if (excluded.contains(vegetableId)) {
      excluded.remove(vegetableId);
    } else {
      if (!state.canExcludeMore) return; // Validation: max exclusions
      excluded.add(vegetableId);
    }
    emit(state.copyWith(excludedVegetableIds: excluded, isSaved: false));
  }

  void selectWeight(double weight) {
    if (state.patch != null &&
        !state.patch!.availableWeights.contains(weight)) {
      return;
    }
    emit(state.copyWith(selectedWeight: weight, isSaved: false));
  }

  void selectFrequency(String frequency) {
    emit(state.copyWith(deliveryFrequency: frequency, isSaved: false));
  }

  void markSaved() {
    emit(state.copyWith(isSaved: true));
  }
}
