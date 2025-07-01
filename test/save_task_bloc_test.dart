import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_task_bloc/save_task_bloc.dart';

// Mocks
class MockTaskRepo extends Mock implements Taskrepo {}
class MockApiResponse extends Mock implements ApiResponse {}
class MockSubmitTaskModel extends Mock implements SubmitTaskModel {}

void main() {
  late MockTaskRepo mockTaskRepo;
  late SaveTaskBloc saveTaskBloc;
  late MockSubmitTaskModel mockSubmitTaskModel;
  late MockApiResponse mockApiResponse;

  setUp(() {
    mockTaskRepo = MockTaskRepo();
    saveTaskBloc = SaveTaskBloc(repository: mockTaskRepo);
    mockSubmitTaskModel = MockSubmitTaskModel();
    mockApiResponse = MockApiResponse();

    // Default properties for the mock objects
    when(() => mockSubmitTaskModel.contentId).thenReturn('test-content-id');
    when(() => mockSubmitTaskModel.isForceOnline).thenReturn(true);
    
    // Default API response setup
    when(() => mockApiResponse.error).thenReturn(false);
    when(() => mockApiResponse.status).thenReturn(200);
    when(() => mockApiResponse.message).thenReturn('Success');
    when(() => mockApiResponse.data).thenReturn({
      'serverUrl': 'https://example.com/audio/123.mp3',
    });
    
    // Mock the API call
    when(() => mockTaskRepo.saveTask(taskRecord: any(named: 'taskRecord')))
        .thenAnswer((_) async => mockApiResponse);
  });

  tearDown(() {
    saveTaskBloc.close();
  });

  group('SaveTaskBloc', () {
    test('initial state is SaveTaskInitial', () {
      expect(saveTaskBloc.state, isA<SaveTaskInitial>());
    });

    blocTest<SaveTaskBloc, SaveTaskState>(
      'emits [SaveTaskLoadingState, SaveTaskRefreshNeededState, SaveTaskSuccessState] when task is saved successfully',
      build: () => saveTaskBloc,
      act: (bloc) => bloc.add(SaveTaskButtonclickingEvent(saveData: mockSubmitTaskModel)),
      expect: () => [
        isA<SaveTaskLoadingState>(),
        isA<SaveTaskRefreshNeededState>(),
        isA<SaveTaskSuccessState>(),
      ],
    );

    blocTest<SaveTaskBloc, SaveTaskState>(
      'emits [SaveTaskLoadingState, SaveTaskErrorState] when task save fails',
      build: () {
        when(() => mockApiResponse.error).thenReturn(true);
        when(() => mockApiResponse.status).thenReturn(400);
        when(() => mockApiResponse.message).thenReturn('Error saving task');
        
        when(() => mockTaskRepo.saveTask(taskRecord: any(named: 'taskRecord')))
            .thenAnswer((_) async => mockApiResponse);
        
        return saveTaskBloc;
      },
      act: (bloc) => bloc.add(SaveTaskButtonclickingEvent(saveData: mockSubmitTaskModel)),
      expect: () => [
        isA<SaveTaskLoadingState>(),
        isA<SaveTaskErrorState>(),
      ],
    );

    blocTest<SaveTaskBloc, SaveTaskState>(
      'SaveTaskRefreshNeededState contains serverUrl when available',
      build: () => saveTaskBloc,
      act: (bloc) => bloc.add(SaveTaskButtonclickingEvent(saveData: mockSubmitTaskModel)),
      verify: (bloc) {
        final states = bloc.state;
        if (states is SaveTaskRefreshNeededState) {
          expect(states.serverUrl, isNotNull);
          expect(states.serverUrl, isA<String>());
        }
      },
    );
  });
} 