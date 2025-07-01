import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/data/savereview_model.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_rview_bloc/save_review_bloc.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';

class RejectAlertDialog extends StatefulWidget {
  final String taskTargetId;
  final String contentId;
  final String tcontentId;

  const RejectAlertDialog({
    super.key,
    required this.taskTargetId,
    required this.contentId,
    required this.tcontentId,
  });

  @override
  State<RejectAlertDialog> createState() => _RejectAlertDialogState();
}

class _RejectAlertDialogState extends State<RejectAlertDialog> {
  String? selectedErrorType;
  final TextEditingController _reasonController = TextEditingController();

  final List<String> errorTypes = [
    'Mispronunciation',
    'Audio Distortion',
    'Extraneous Noise',
    'Unwanted silence'
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: TextStyles.headline(
        text: 'Do you want to reject?',
        color: Appcolors.kredColor,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please enter reason to reject'),
            const SizedBox(height: 16),
            Text(
              'Select error type',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedErrorType,
                  isExpanded: true,
                  hint: const Text('Select error type'),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: errorTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedErrorType = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Write text',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter your reason here',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        Row(children: [
           TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: TextStyles.body(
            text: 'Cancel',
            weight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        BlocConsumer<SaveReviewBloc, SaveReviewState>(
          listener: (context, state) {
            if (state is SaveReviewSuccessState) {
              context.read<ReviewContentBloc>().add(
                    ReviewContentFetchingInitialEvent(
                      taskTargetId: widget.taskTargetId,
                    ),
                  );
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            if (state is SaveReviewLoadingSate) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusStyles.kradius10(),
                    ),
                    backgroundColor: Appcolors.kredColor),
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
                backgroundColor: Appcolors.kredColor,
              ),
              onPressed: () {
                if (selectedErrorType != null &&
                    _reasonController.text.isNotEmpty &&
                    widget.tcontentId.isNotEmpty) {
                  context.read<SaveReviewBloc>().add(
                        SaveRviewButtonclickEvent(
                          reviews: SaveReviewModel(
                            reviewStatus: 'REJECTED',
                            taskTargetId: widget.taskTargetId,
                            contentId: widget.contentId,
                            tContentId: widget.tcontentId,
                            selectedOption: selectedErrorType,
                            comment: _reasonController.text,
                          ),
                        ),
                      );
                } else {
                  CustomSnackBar.show(
                      context: context,
                      title: 'Error!!',
                      message: 'Fill all fields',
                      contentType: ContentType.failure);
                }
              },
              child: TextStyles.body(
                text: 'Reject',
                weight: FontWeight.bold,
                color: Appcolors.kwhiteColor,
              ),
            );
          },
        ),
        ],)
       
      ],
    );
  }
}
