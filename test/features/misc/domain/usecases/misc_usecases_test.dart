import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/misc/domain/entities/address_entity.dart';
import 'package:grocery_app/features/misc/domain/repositories/address_repository.dart';
import 'package:grocery_app/features/misc/domain/repositories/help_repository.dart';
import 'package:grocery_app/features/misc/domain/repositories/profile_repository.dart';
import 'package:grocery_app/features/misc/domain/usecases/save_address_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/send_otp_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/update_user_profile_use_case.dart';
import 'package:grocery_app/models/user_model.dart';

class MockHelpRepository extends Mock implements HelpRepository {}
class MockAddressRepository extends Mock implements AddressRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('Help UseCases', () {
    late MockHelpRepository mockRepo;
    late SendOtpUseCase useCase;

    setUp(() {
      mockRepo = MockHelpRepository();
      useCase = SendOtpUseCase(mockRepo);
    });

    test('SendOtpUseCase calls repository sendOtp', () async {
      when(() => mockRepo.sendOtp(identifier: '1234567890', type: 'phone'))
          .thenAnswer((_) async => {'success': true, 'message': 'OTP sent'});

      final res = await useCase(identifier: '1234567890', type: 'phone');
      expect(res['success'], isTrue);
      verify(() => mockRepo.sendOtp(identifier: '1234567890', type: 'phone')).called(1);
    });
  });

  group('Address UseCases', () {
    late MockAddressRepository mockRepo;
    late SaveAddressUseCase useCase;

    setUp(() {
      mockRepo = MockAddressRepository();
      useCase = SaveAddressUseCase(mockRepo);
    });

    test('SaveAddressUseCase calls repository updateAddress', () async {
      const address = AddressEntity(
        name: 'John',
        address: '123 Main St',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
        phone: '9876543210',
      );

      when(() => mockRepo.updateAddress(address)).thenAnswer((_) async => true);

      final res = await useCase(address);
      expect(res, isTrue);
      verify(() => mockRepo.updateAddress(address)).called(1);
    });
  });

  group('Profile UseCases', () {
    late MockProfileRepository mockRepo;
    late UpdateUserProfileUseCase useCase;

    setUp(() {
      mockRepo = MockProfileRepository();
      useCase = UpdateUserProfileUseCase(mockRepo);
    });

    test('UpdateUserProfileUseCase calls repository updateProfile', () async {
      final user = UserModel(
        username: 'test',
        email: 'test@example.com',
        password: 'pass',
        confirmPassword: 'pass',
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: '1234567890',
        gender: 'Other',
      );

      when(() => mockRepo.updateProfile(user))
          .thenAnswer((_) async => {'success': true});

      final res = await useCase(user);
      expect(res['success'], isTrue);
      verify(() => mockRepo.updateProfile(user)).called(1);
    });
  });
}
