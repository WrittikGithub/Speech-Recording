import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/domain/controllers/pushnotification.dart';
import 'package:sdcp_rebuild/domain/repositories/bankrepo.dart';
import 'package:sdcp_rebuild/domain/repositories/commentrepo.dart';
import 'package:sdcp_rebuild/domain/repositories/dashboardrepo.dart';
import 'package:sdcp_rebuild/domain/repositories/languagerepo.dart';
import 'package:sdcp_rebuild/domain/repositories/loginrepo.dart';
import 'package:sdcp_rebuild/domain/repositories/profilerepo.dart';
import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';
import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';
import 'package:sdcp_rebuild/firebase_options.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_record_bloc/audio_record_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/completed_task_bloc/completed_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/cubit/toggle_password_cubit.dart';
import 'package:sdcp_rebuild/presentation/blocs/dashboard_data/dashboard_data_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/dashboard_tasklist/dashboard_tasklist_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_bankdetails/fetch_bankdetails_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_comment_bloc/fetch_comment_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_instructionsbloc/fetch_instructions_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_profile_bloc/fetch_profile_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/image_picker_bloc/image_picker_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/login_bloc/login_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/notification_bloc/notification_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/post_bankdetails.bloc/post_bankdetails_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/preview_score_bloc/preview_score_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/report_bloc/report_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_comment_bloc/review_comment_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/reviewassignments_bloc/reviews_assignmentsinterview_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_commentbloc/save_comment_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_feedback_bloc/save_feedback_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_review_comment/save_reviewcomment_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_rview_bloc/save_review_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_task_bloc/save_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/submit_review/submit_review_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/submit_task_bloc/submit_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/task_bloc/task_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/update_profilebloc/updat_profile_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/userlanguage_bloc/user_language_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/splashpage/splash_page.dart';
import 'package:sdcp_rebuild/data/repositories/signup_repository.dart';
import 'package:sdcp_rebuild/presentation/blocs/signup_bloc/signup_bloc.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/presentation/screens/additional_info_page.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use try-catch to handle Firebase initialization errors
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print('Firebase initialization error handled: $e');
    // Continue execution as Firebase may already be initialized by native code
  }
  
  final pushNotifications = PushNotifications();
  await pushNotifications.init();

  // Request notification permission for iOS
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(PushNotifications.backgroundMessageHandler);

  // Initialize database and ensure columns exist
  final dbHelper = ContentDatabaseHelper();
  await dbHelper.ensureAudioColumnsExist();

  // Initialize awesome notifications
  await AwesomeNotifications().initialize(
    null, // no icon for now, will use app icon
    [
      NotificationChannel(
        channelKey: 'recording_channel',
        channelName: 'Recording',
        channelDescription: 'Shows recording status',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        importance: NotificationImportance.High,
        playSound: false,
        enableVibration: false,
        locked: true,
      )
    ],
  );

  // Request notification permissions
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  runApp(MyApp(pushNotifications: pushNotifications));

  Connectivity().onConnectivityChanged.listen((results) {
    if (results == ConnectivityResult.mobile ||
        results == ConnectivityResult.wifi) {
      Taskrepo().syncPendingTasks();
      Reviewsrepo().syncPendingReviews();
    }
  });
}

class MyApp extends StatelessWidget {
  final PushNotifications pushNotifications;

  const MyApp({Key? key, required this.pushNotifications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);
    final dashboardRepo = Dashbordrepo();
    final loginrepo = Loginrepo();
    final taskrepo = Taskrepo();
    final languagerepo = Languagerepo();
    final reviewsrepo = Reviewsrepo();
    final profilerepo = Profilerepo();
    final bankrepo = Bankrepo();
    final commentrepo = Commentrepo();

    return MultiBlocProvider(
      providers: [
        BlocProvider<BottomNavigationbarBloc>(
          create: (context) => BottomNavigationbarBloc(),
        ),
        BlocProvider<DashboardDataBloc>(
          create: (context) => DashboardDataBloc(repository: dashboardRepo),
        ),
        BlocProvider<DashboardTasklistBloc>(
          create: (context) => DashboardTasklistBloc(repository: dashboardRepo),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(repository: loginrepo),
        ),
        BlocProvider<TaskBloc>(
          create: (context) => TaskBloc(repository: taskrepo),
        ),
        BlocProvider<UserLanguageBloc>(
          create: (context) => UserLanguageBloc(repository: languagerepo),
        ),
        BlocProvider<ReviewsAssignmentsinterviewBloc>(
          create: (context) =>
              ReviewsAssignmentsinterviewBloc(repository: reviewsrepo),
        ),
        BlocProvider<ImagePickerBloc>(
          create: (context) => ImagePickerBloc(),
        ),
        BlocProvider<FetchProfileBloc>(
          create: (context) => FetchProfileBloc(repository: profilerepo),
        ),
        BlocProvider<FetchBankdetailsBloc>(
          create: (context) => FetchBankdetailsBloc(repository: bankrepo),
        ),
        BlocProvider<PostBankdetailsBloc>(
          create: (context) => PostBankdetailsBloc(repository: bankrepo),
        ),
        BlocProvider<ContentTaskTargetIdBloc>(
          create: (context) => ContentTaskTargetIdBloc(repository: taskrepo),
        ),
        BlocProvider<FetchCommentBloc>(
          create: (context) => FetchCommentBloc(repository: commentrepo),
        ),
        BlocProvider<SaveCommentBloc>(
          create: (context) => SaveCommentBloc(repository: commentrepo),
        ),
        BlocProvider<FetchInstructionsBloc>(
          create: (context) => FetchInstructionsBloc(repository: reviewsrepo),
        ),
        BlocProvider<SaveReviewBloc>(
          create: (context) => SaveReviewBloc(repository: reviewsrepo),
        ),
        BlocProvider<ReviewContentBloc>(
          create: (context) => ReviewContentBloc(repository: reviewsrepo),
        ),
        BlocProvider<PreviewScoreBloc>(
          create: (context) => PreviewScoreBloc(repository: reviewsrepo),
        ),
        BlocProvider<SaveFeedbackBloc>(
          create: (context) => SaveFeedbackBloc(repository: reviewsrepo),
        ),
        BlocProvider<AudioRecordBloc>(
          create: (context) => AudioRecordBloc(),
        ),
        BlocProvider<SaveTaskBloc>(
          create: (context) => SaveTaskBloc(repository: taskrepo),
        ),
        BlocProvider<CompletedTaskBloc>(
          create: (context) => CompletedTaskBloc(repository: taskrepo),
        ),
        BlocProvider<ReviewCommentBloc>(
          create: (context) => ReviewCommentBloc(repository: commentrepo),
        ),
        BlocProvider<SaveReviewcommentBloc>(
          create: (context) => SaveReviewcommentBloc(repository: commentrepo),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(repository: dashboardRepo),
        ),
        BlocProvider<ReportBloc>(
          create: (context) => ReportBloc(repository: dashboardRepo),
        ),
        BlocProvider<SubmitReviewBloc>(
          create: (context) => SubmitReviewBloc(repository: reviewsrepo),
        ),
        BlocProvider<SubmitTaskBloc>(
          create: (context) => SubmitTaskBloc(repository: taskrepo),
        ),
        BlocProvider<UpdatProfileBloc>(
          create: (context) => UpdatProfileBloc(repository: profilerepo),
        ),
        BlocProvider<TogglepasswordCubit>(
          create: (context) => TogglepasswordCubit(),
        ),
        BlocProvider<SignupBloc>(
          create: (context) => SignupBloc(repository: SignupRepository()),
        ),
      ],
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          print('[MyApp BlocListener (wrapping MaterialApp)] Raw state received: $state');
          if (state is GoogleSignInNeedsMoreInfoState) {
            print("[MyApp BlocListener (wrapping MaterialApp)] Detected GoogleSignInNeedsMoreInfoState, navigating...");
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: BlocProvider.of<LoginBloc>(context),
                  child: AdditionalInfoPage(
                    googleUserId: state.googleUserId,
                    email: state.email,
                    displayName: state.displayName,
                    existingUserId: state.existingUserId,
                  ),
                ),
              ),
            );
          } else if (state is LoginSuccessState || state is LoginSuccessAppOneState) {
            print("[MyApp BlocListener (wrapping MaterialApp)] Detected LoginSuccess/AppOneState, navigating...");
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/main_page', (route) => false);
          } else if (state is LoggedOutState) {
            print("[MyApp BlocListener (wrapping MaterialApp)] Detected LoggedOutState, navigating...");
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Vacha',
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Appcolors.kwhiteColor,
            ),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: GoogleFonts.montserrat().fontFamily,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black),
            ),
            useMaterial3: true,
          ),
          home: Builder(
            builder: (context) {
              pushNotifications.setContext(context);
              return const AdvancedSplashScreen();
            },
          ),
          routes: {
            '/login': (context) => const ScreenLoginPage(),
            '/main_page': (context) => const ScreenMainPage(),
          },
        ),
      ),
    );
  }
}
