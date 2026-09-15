import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:grocery_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:grocery_app/features/chat/presentation/cubit/chat_state.dart';
import 'package:grocery_app/features/chat/domain/usecases/send_message_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/stream_message_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/create_session_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/list_sessions_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/get_session_detail_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/rename_session_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/delete_session_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/confirm_action_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/save_health_observation_use_case.dart';
import 'package:grocery_app/features/chat/domain/usecases/delete_memory_use_case.dart';
import 'package:grocery_app/features/chat/domain/entities/chat_response.dart';
import 'package:grocery_app/features/chat/domain/entities/chat_message.dart';
import 'package:grocery_app/features/chat/domain/entities/health_observation.dart';

class MockSendMessageUseCase extends Mock implements SendMessageUseCase {}
class MockStreamMessageUseCase extends Mock implements StreamMessageUseCase {}
class MockCreateSessionUseCase extends Mock implements CreateSessionUseCase {}
class MockListSessionsUseCase extends Mock implements ListSessionsUseCase {}
class MockGetSessionDetailUseCase extends Mock implements GetSessionDetailUseCase {}
class MockRenameSessionUseCase extends Mock implements RenameSessionUseCase {}
class MockDeleteSessionUseCase extends Mock implements DeleteSessionUseCase {}
class MockConfirmActionUseCase extends Mock implements ConfirmActionUseCase {}
class MockSaveHealthObservationUseCase extends Mock implements SaveHealthObservationUseCase {}
class MockDeleteMemoryUseCase extends Mock implements DeleteMemoryUseCase {}

void main() {
  late MockSendMessageUseCase mockSendMessageUseCase;
  late MockStreamMessageUseCase mockStreamMessageUseCase;
  late MockCreateSessionUseCase mockCreateSessionUseCase;
  late MockListSessionsUseCase mockListSessionsUseCase;
  late MockGetSessionDetailUseCase mockGetSessionDetailUseCase;
  late MockRenameSessionUseCase mockRenameSessionUseCase;
  late MockDeleteSessionUseCase mockDeleteSessionUseCase;
  late MockConfirmActionUseCase mockConfirmActionUseCase;
  late MockSaveHealthObservationUseCase mockSaveHealthObservationUseCase;
  late MockDeleteMemoryUseCase mockDeleteMemoryUseCase;

  setUp(() {
    mockSendMessageUseCase = MockSendMessageUseCase();
    mockStreamMessageUseCase = MockStreamMessageUseCase();
    mockCreateSessionUseCase = MockCreateSessionUseCase();
    mockListSessionsUseCase = MockListSessionsUseCase();
    mockGetSessionDetailUseCase = MockGetSessionDetailUseCase();
    mockRenameSessionUseCase = MockRenameSessionUseCase();
    mockDeleteSessionUseCase = MockDeleteSessionUseCase();
    mockConfirmActionUseCase = MockConfirmActionUseCase();
    mockSaveHealthObservationUseCase = MockSaveHealthObservationUseCase();
    mockDeleteMemoryUseCase = MockDeleteMemoryUseCase();
  });

  ChatCubit buildCubit() {
    return ChatCubit(
      sendMessageUseCase: mockSendMessageUseCase,
      streamMessageUseCase: mockStreamMessageUseCase,
      createSessionUseCase: mockCreateSessionUseCase,
      listSessionsUseCase: mockListSessionsUseCase,
      getSessionDetailUseCase: mockGetSessionDetailUseCase,
      renameSessionUseCase: mockRenameSessionUseCase,
      deleteSessionUseCase: mockDeleteSessionUseCase,
      confirmActionUseCase: mockConfirmActionUseCase,
      saveHealthObservationUseCase: mockSaveHealthObservationUseCase,
      deleteMemoryUseCase: mockDeleteMemoryUseCase,
    );
  }

  group('ChatCubit - Confirm Action', () {
    const testResponse = ChatResponseEntity(
      response: 'Items added to cart successfully.',
      sessionId: 'sess_1',
      responseType: 'general_text',
    );

    blocTest<ChatCubit, ChatState>(
      'confirmAction emits isConfirming true then false with updated messages',
      build: () {
        when(() => mockConfirmActionUseCase(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
          confirmationId: any(named: 'confirmationId'),
        )).thenAnswer((_) async => testResponse);
        return buildCubit();
      },
      seed: () => const ChatState(activeSessionId: 'sess_1'),
      act: (cubit) => cubit.confirmAction(
        confirmationId: 'nonce_99',
        message: 'Add items',
      ),
      expect: () => [
        const ChatState(activeSessionId: 'sess_1', isConfirming: true),
        isA<ChatState>()
            .having((s) => s.isConfirming, 'isConfirming', false)
            .having((s) => s.messages.length, 'messages count', 1)
            .having((s) => s.messages.first.content, 'message content', 'Items added to cart successfully.'),
      ],
      verify: (_) {
        verify(() => mockConfirmActionUseCase(
          message: 'Add items',
          sessionId: 'sess_1',
          confirmationId: 'nonce_99',
        )).called(1);
      },
    );
  });

  group('ChatCubit - Save & Dismiss Health Observation', () {
    const obsMessage = ChatMessageEntity(
      role: ChatRole.assistant,
      content: 'Observation response',
      healthObservation: HealthObservation(
        type: 'health_observation',
        food: 'Kurkure',
        symptom: 'Fever',
        causality: 'user_reported_unconfirmed',
        saveRequested: false,
        requiresConsent: true,
        message: 'Reported fever after Kurkure',
      ),
    );

    const confirmResponse = ChatResponseEntity(
      response: 'Health observation saved.',
      sessionId: 'sess_1',
      responseType: 'general_text',
    );

    blocTest<ChatCubit, ChatState>(
      'saveHealthObservation calls usecase and updates message observationSaved to true',
      build: () {
        when(() => mockSaveHealthObservationUseCase(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
        )).thenAnswer((_) async => confirmResponse);
        return buildCubit();
      },
      seed: () => const ChatState(
        activeSessionId: 'sess_1',
        messages: [obsMessage],
      ),
      act: (cubit) => cubit.saveHealthObservation(originalMessage: 'Ate Kurkure'),
      expect: () => [
        isA<ChatState>().having((s) => s.isSavingObservation, 'isSavingObservation', true),
        isA<ChatState>()
            .having((s) => s.isSavingObservation, 'isSavingObservation', false)
            .having((s) => s.messages.first.observationSaved, 'observationSaved', true),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'dismissHealthObservation locally sets observationSaved to true without API call',
      build: () => buildCubit(),
      seed: () => const ChatState(
        activeSessionId: 'sess_1',
        messages: [obsMessage],
      ),
      act: (cubit) => cubit.dismissHealthObservation(0),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.messages.first.observationSaved, 'observationSaved', true),
      ],
      verify: (_) {
        verifyNever(() => mockSaveHealthObservationUseCase(
          message: any(named: 'message'),
          sessionId: any(named: 'sessionId'),
        ));
      },
    );
  });

  group('ChatCubit - Delete Memory', () {
    blocTest<ChatCubit, ChatState>(
      'deleteMemory updates status to deleting then success',
      build: () {
        when(() => mockDeleteMemoryUseCase()).thenAnswer((_) async => true);
        return buildCubit();
      },
      act: (cubit) => cubit.deleteMemory(),
      expect: () => [
        const ChatState(
          isDeletingMemory: true,
          memoryDeleteStatus: MemoryDeleteStatus.deleting,
        ),
        const ChatState(
          isDeletingMemory: false,
          memoryDeleteStatus: MemoryDeleteStatus.success,
        ),
      ],
    );
  });
}
