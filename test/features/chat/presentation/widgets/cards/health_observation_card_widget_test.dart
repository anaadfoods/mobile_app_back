import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/chat/domain/entities/health_observation.dart';
import 'package:grocery_app/features/chat/domain/entities/chat_message.dart';
import 'package:grocery_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:grocery_app/features/chat/presentation/cubit/chat_state.dart';
import 'package:grocery_app/features/chat/presentation/widgets/cards/health_observation_card_widget.dart';

class MockChatCubit extends Mock implements ChatCubit {}

void main() {
  late MockChatCubit mockChatCubit;

  const testObservation = HealthObservation(
    type: 'health_observation',
    food: 'Kurkure',
    symptom: 'mild fever',
    causality: 'user_reported_unconfirmed',
    saveRequested: false,
    requiresConsent: true,
    message: 'User reported mild fever after consuming Kurkure',
  );

  setUp(() {
    mockChatCubit = MockChatCubit();
    when(() => mockChatCubit.state).thenReturn(
      const ChatState(
        messages: [
          ChatMessageEntity(
            role: ChatRole.user,
            content: 'I ate Kurkure and got mild fever',
          ),
          ChatMessageEntity(
            role: ChatRole.assistant,
            content: 'I noted your symptom',
          ),
        ],
      ),
    );
    when(() => mockChatCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockChatCubit.dismissHealthObservation(any())).thenAnswer((_) {});
    when(() => mockChatCubit.saveHealthObservation(
      originalMessage: any(named: 'originalMessage'),
    )).thenAnswer((_) async {});
  });

  Widget buildTestWidget({bool isSaved = false, int messageIndex = 1}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider<ChatCubit>.value(
            value: mockChatCubit,
            child: HealthObservationCardWidget(
              observation: testObservation,
              isSaved: isSaved,
              messageIndex: messageIndex,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders health observation details correctly', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Health observation'), findsOneWidget);
    expect(find.text('Kurkure'), findsOneWidget);
    expect(find.text('mild fever'), findsOneWidget);
    expect(find.text('User-reported, not medically confirmed'), findsOneWidget);
  });

  testWidgets('shows Save and Don\'t save buttons when not saved', (tester) async {
    await tester.pumpWidget(buildTestWidget(isSaved: false));

    expect(find.text('Save observation'), findsOneWidget);
    expect(find.text('Don\'t save'), findsOneWidget);
  });

  testWidgets('shows saved confirmation text when isSaved is true', (tester) async {
    await tester.pumpWidget(buildTestWidget(isSaved: true));

    expect(find.textContaining('Observation saved as user-reported and unconfirmed'), findsOneWidget);
    expect(find.text('Save observation'), findsNothing);
  });

  testWidgets('tapping Don\'t save calls dismissHealthObservation', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Don\'t save'));
    await tester.pumpAndSettle();

    verify(() => mockChatCubit.dismissHealthObservation(1)).called(1);
  });

  testWidgets('tapping Save observation calls saveHealthObservation with original message', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Save observation'));
    await tester.pumpAndSettle();

    verify(() => mockChatCubit.saveHealthObservation(
      originalMessage: 'I ate Kurkure and got mild fever',
    )).called(1);
  });
}
