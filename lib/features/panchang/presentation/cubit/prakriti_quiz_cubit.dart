import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/utils/app_logger.dart';

abstract class PrakritiQuizState {}

class PrakritiQuizInitial extends PrakritiQuizState {}

class PrakritiQuizLoading extends PrakritiQuizState {}

class PrakritiQuizQuestionsLoaded extends PrakritiQuizState {
  final List<Map<String, dynamic>> questions;
  final Map<String, String> answers; // questionCode -> optionId
  final int currentIndex;

  PrakritiQuizQuestionsLoaded({
    required this.questions,
    required this.answers,
    this.currentIndex = 0,
  });

  PrakritiQuizQuestionsLoaded copyWith({
    List<Map<String, dynamic>>? questions,
    Map<String, String>? answers,
    int? currentIndex,
  }) {
    return PrakritiQuizQuestionsLoaded(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class PrakritiQuizSubmitting extends PrakritiQuizState {}

class PrakritiQuizResult extends PrakritiQuizState {
  final Map<String, dynamic> result;

  PrakritiQuizResult({required this.result});
}

class PrakritiQuizError extends PrakritiQuizState {
  final String message;

  PrakritiQuizError({required this.message});
}

class PrakritiQuizCubit extends Cubit<PrakritiQuizState> {
  final ApiClient _apiClient;

  PrakritiQuizCubit({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance,
        super(PrakritiQuizInitial());

  Future<void> loadQuestions() async {
    emit(PrakritiQuizLoading());
    try {
      final response = await _apiClient.get(ApiConfig.ayurvedaQuestionsEndpoint);
      
      final resData = response.data;
      List<Map<String, dynamic>> questions = [];
      
      if (resData is List) {
        questions = List<Map<String, dynamic>>.from(resData);
      } else if (resData is Map<String, dynamic>) {
        if (resData.containsKey('data') && resData['data'] is List) {
          questions = List<Map<String, dynamic>>.from(resData['data']);
        } else if (resData.containsKey('questions') && resData['questions'] is List) {
          questions = List<Map<String, dynamic>>.from(resData['questions']);
        }
      }

      if (questions.isEmpty) {
        emit(PrakritiQuizError(message: 'No questions retrieved from server.'));
        return;
      }

      emit(PrakritiQuizQuestionsLoaded(
        questions: questions,
        answers: {},
        currentIndex: 0,
      ));
    } catch (e, stack) {
      AppLogger.error('Failed to load Ayurveda questions', e, stack);
      emit(PrakritiQuizError(message: 'Failed to load questions: ${e.toString()}'));
    }
  }

  void answerQuestion(String questionCode, String optionId) {
    final currentState = state;
    if (currentState is PrakritiQuizQuestionsLoaded) {
      final newAnswers = Map<String, String>.from(currentState.answers);
      newAnswers[questionCode] = optionId;
      emit(currentState.copyWith(answers: newAnswers));
    }
  }

  void goToQuestion(int index) {
    final currentState = state;
    if (currentState is PrakritiQuizQuestionsLoaded) {
      if (index >= 0 && index < currentState.questions.length) {
        emit(currentState.copyWith(currentIndex: index));
      }
    }
  }

  Future<void> submitQuiz() async {
    final currentState = state;
    if (currentState is PrakritiQuizQuestionsLoaded) {
      emit(PrakritiQuizSubmitting());
      try {
        final answersList = currentState.answers.entries
            .map((e) => {'question_code': e.key, 'selected_option_id': e.value, 'option_id': e.value})
            .toList();

        final response = await _apiClient.post(
          ApiConfig.ayurvedaSubmitQuizEndpoint,
          data: {'answers': answersList},
        );

        final resData = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)
            : <String, dynamic>{};

        emit(PrakritiQuizResult(result: resData));
      } catch (e, stack) {
        AppLogger.error('Failed to submit Ayurveda quiz', e, stack);
        emit(PrakritiQuizError(message: 'Failed to submit quiz: ${e.toString()}'));
      }
    }
  }

  Future<void> loadPreviousAnswers() async {
    emit(PrakritiQuizLoading());
    try {
      final response = await _apiClient.get(ApiConfig.ayurvedaAnswersEndpoint);
      final resData = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)
          : <String, dynamic>{};
      emit(PrakritiQuizResult(result: resData));
    } catch (e) {
      emit(PrakritiQuizError(message: 'Failed to load past answers: ${e.toString()}'));
    }
  }
}
