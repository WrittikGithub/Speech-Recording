import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/presentation/blocs/preview_score_bloc/preview_score_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_feedback_bloc/save_feedback_bloc.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';


class ScoreReportDialog extends StatefulWidget {
  final String taskTargetId;
  const ScoreReportDialog({super.key, required this.taskTargetId});

  @override
  State<ScoreReportDialog> createState() => _ScoreReportDialogState();
}

class _ScoreReportDialogState extends State<ScoreReportDialog> {
  final TextEditingController feedbacktext = TextEditingController();
  @override
  void dispose() {
    feedbacktext.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Score Report',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BlocBuilder<PreviewScoreBloc, PreviewScoreState>(
              builder: (context, state) {
                if (state is PreviewScoreLoadingState) {
                  return Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Appcolors.kpurplelightColor, size: 40),
                  );
                }
                if (state is PreviewScoreSuccessState) {
                  return Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Table(
                            border: TableBorder.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            defaultColumnWidth: const FixedColumnWidth(150.0),
                            columnWidths: const {
                              0: FixedColumnWidth(70),
                              1: FixedColumnWidth(100),
                              2: FixedColumnWidth(100.0),
                              3: FixedColumnWidth(100.0),
                            },
                            children: [
                              // Header Row
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                ),
                                children: const [
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'CID',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Error Type',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Error Score',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Comment',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Data Rows
                              ...state.previewScores
                                  .map((item) => TableRow(
                                        children: [
                                          TableCell(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(item.contentId),
                                            ),
                                          ),
                                          TableCell(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(item.errorType),
                                            ),
                                          ),
                                          TableCell(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(item.errorScore),
                                            ),
                                          ),
                                          TableCell(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(item.comment),
                                            ),
                                          ),
                                        ],
                                      ))
                                  ,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 65,
                child: TextField(
                  maxLines: 1,
                  maxLength: 5000,
                  controller: feedbacktext,
                  decoration: InputDecoration(
                    labelText: "Enter Feedback to Translator",
                    border: const OutlineInputBorder(),
                    fillColor: Appcolors.kskybluecolor.withOpacity(.5),
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Appcolors.kredColor),
                  ),
                ),
                const SizedBox(width: 8),
                BlocConsumer<SaveFeedbackBloc, SaveFeedbackState>(
                  listener: (context, state) {
                    if (state is SaveFeedbackSuccessState) {
                      CustomSnackBar.show(
                          context: context,
                          title: 'Success ',
                          message: 'Feedback Saved Successfully',
                          contentType: ContentType.success);
                      feedbacktext.clear();
                      Navigator.of(context).pop();
                    }
                  },
                  builder: (context, state) {
                    if (state is SaveFeedbackLoadingState) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusStyles.kradius10(),
                            ),
                            backgroundColor: Appcolors.kgreenColor),
                        onPressed: () {},
                        child: Center(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Appcolors.kwhiteColor, size: 30),
                        ),
                      );
                    }
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusStyles.kradius10(),
                          ),
                          backgroundColor: Appcolors.kgreenColor),
                      onPressed: () {
                        if (feedbacktext.text.length < 20) {
                          return CustomSnackBar.show(
                              context: context,
                              title: 'Error',
                              message: 'Feedback minimum 20 words',
                              contentType: ContentType.success);
                        }
                        context.read<SaveFeedbackBloc>().add(
                            SaveFeedbackButtonClickingEvent(
                                additionalinfo: feedbacktext.text,
                                taskTargetId: widget.taskTargetId));
                      },
                      child: TextStyles.body(
                          text: 'Approve',
                          weight: FontWeight.bold,
                          color: Appcolors.kwhiteColor),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
