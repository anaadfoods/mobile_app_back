import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/features/misc/domain/entities/address_entity.dart';
import 'package:grocery_app/features/misc/domain/usecases/save_address_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/address_state.dart';

class AddressCubit extends Cubit<AddressState> {
  final SaveAddressUseCase _saveAddressUseCase;

  AddressCubit({required SaveAddressUseCase saveAddressUseCase})
      : _saveAddressUseCase = saveAddressUseCase,
        super(const AddressInitial());

  Future<bool> saveAddress(AddressEntity address) async {
    emit(const AddressLoading());
    try {
      final success = await _saveAddressUseCase(address);
      if (success) {
        emit(const AddressSavedSuccess());
        return true;
      } else {
        emit(const AddressError('Failed to save address'));
        return false;
      }
    } catch (e) {
      emit(AddressError(e.toString()));
      return false;
    }
  }
}
