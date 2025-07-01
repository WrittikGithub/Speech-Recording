import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sdcp_rebuild/presentation/blocs/notification_bloc/notification_bloc.dart';

class Notification {
  final String title;
  final String content;
  final DateTime date;

  Notification(
      {required this.title, required this.content, required this.date});
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
 


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<NotificationBloc>().add(NotificationFetchingInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Appcolors.kyellowColor,
      appBar: AppBar(
        backgroundColor: Appcolors.kwhiteColor,
        title: ListenableBuilder(
          listenable: GlobalState(),
          builder: (context, _) {
            return TextStyles.body(text: 'Hello.. ${GlobalState().username}');
          },
        ),
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_back,
            size: 32,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(1)),
            child: Container(
              decoration: BoxDecoration(
                color: Appcolors.kpurpleColor,
                borderRadius: BorderRadiusStyles.kradius20(),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.wp(8),
                vertical: ResponsiveUtils.hp(1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications,
                    color: Appcolors.kwhiteColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 15,
                      color: Appcolors.kwhiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ResponsiveSizedBox.width20
        ],
      ),

      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationFetchingLoadingState) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Appcolors.kpurplelightColor, size: 40),
            );
          }
          if (state is NotificationFetchingErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<NotificationBloc>()
                          .add(NotificationFetchingInitialEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is NotificationFetchingSuccessState) {
            return Container(
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  color: Appcolors.kwhiteColor),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 15),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color.fromARGB(255, 215, 224, 236),
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: TextStyles.body(
                          text: 'System Notification', weight: FontWeight.bold),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextStyles.caption(
                              text: state.notifications[index].notification,
                              color: Appcolors.kblackColor),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Spacer(),
                              TextStyles.caption(
                                  text: timeago.format(
                                      state.notifications[index].createdDate))
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
