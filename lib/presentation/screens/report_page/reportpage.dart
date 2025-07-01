import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/report_bloc/report_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/report_page/widgets/customcontainer.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';

class ReportPageScreen extends StatefulWidget {
  const ReportPageScreen({super.key});

  @override
  State<ReportPageScreen> createState() => _DateRangeScreenState();
}

class _DateRangeScreenState extends State<ReportPageScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }

        // Single call outside if/else
        context.read<ReportBloc>().add(ReportFetchingButtonclickingEvent(
            fromdate:
                DateFormat('yyyy-MM-dd').format(fromDate ?? DateTime.now()),
            toDate: DateFormat('yyyy-MM-dd').format(toDate ?? DateTime.now())));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    fromDate = now;
    toDate = now;
    context.read<ReportBloc>().add(ReportFetchingButtonclickingEvent(
        fromdate: DateFormat('yyyy-MM-dd').format(now),
        toDate: DateFormat('yyyy-MM-dd').format(now)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    Icons.report,
                    color: Appcolors.kwhiteColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Work Report',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'From Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'To Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // From Date Container
                GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                        border: Border.all(color: Appcolors.kpurplelightColor),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromARGB(255, 211, 230, 246)),
                    child: Text(
                      fromDate != null
                          ? DateFormat('dd/MM/yyyy').format(fromDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: fromDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                // To Date Container
                GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 211, 230, 246),
                      border: Border.all(color: Appcolors.kpurplelightColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      toDate != null
                          ? DateFormat('dd/MM/yyyy').format(toDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: toDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ResponsiveSizedBox.height50,
            Expanded(
              child: BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  if (state is ReportFetchingLoadingState) {
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Appcolors.kpurplelightColor, size: 40),
                    );
                  }
                  if (state is ReportFetchingErorrState) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is ReportFetchingSuccessState) {
                    final report = state.report;
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          CustomContainer(
                              icon: Icons.person,
                              heading: 'User Name',
                              subheading: report.userName),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.task,
                              heading: 'Total Task Assigned',
                              subheading: report.totalTaskAssigned),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.check_circle,
                              heading: 'Tasks Completed',
                              subheading: report.tasksCompleted),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.text_fields,
                              heading: 'Task Word Count',
                              subheading: report.taskWordCount),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.rate_review,
                              heading: 'Total Review Assigned',
                              subheading: report.totalReviewAssigned),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.done_all,
                              heading: 'Review Completed',
                              subheading: report.reviewCompleted),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.text_format,
                              heading: 'Review Word Count',
                              subheading: report.reviewWordCount),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.calendar_month,
                              heading: 'From',
                              subheading: DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(report.fromDate.toString()))),
                          ResponsiveSizedBox.height20,
                          CustomContainer(
                              icon: Icons.calendar_month,
                              heading: 'To',
                              subheading: DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(report.toDate.toString()))),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
