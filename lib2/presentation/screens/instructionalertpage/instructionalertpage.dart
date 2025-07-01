import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_instructionsbloc/fetch_instructions_bloc.dart';


class InstructionAlertDialog extends StatefulWidget {
  final String contentId;
  const InstructionAlertDialog({
    super.key,
    required this.contentId,
  });

  @override
  InstructionAlertDialogState createState() => InstructionAlertDialogState();
}

class InstructionAlertDialogState extends State<InstructionAlertDialog> {
  @override
  void initState() {
    super.initState();
    context
        .read<FetchInstructionsBloc>()
        .add(FetchingInstructionsInitialEvent(contentId: widget.contentId));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: TextStyles.headline(
          text: 'Instructions', color: Appcolors.korangeColor),
      content: BlocBuilder<FetchInstructionsBloc, FetchInstructionsState>(
        builder: (context, state) {
          if (state is FetchInstructionsLoadingState) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Appcolors.kpurpledoublelightColor, size: 40),
            );
          }
          if (state is FetchInstructionsSuccessState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextStyles.subheadline(
                    text: 'Content Reference:', color: Appcolors.kgreenColor),
                ResponsiveSizedBox.height5,
                Text(state.instructions[0].contentReference ?? ''),
                ResponsiveSizedBox.height10,
                const Divider(
                  thickness: 1,
                  color: Appcolors.kgreyColor,
                ),
                ResponsiveSizedBox.height10,
                TextStyles.subheadline(
                    text: 'Content Reference:', color: Appcolors.kgreenColor),
                ResponsiveSizedBox.height5,
                Text(state.instructions[0].additionalNotes ?? ''),
              ],
            );
          }
          if (state is FetchInstructionsErrorState) {
            return Center(
              child: Text(state.message),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: TextStyles.body(
              text: 'Close',
              weight: FontWeight.bold,
              color: Appcolors.kredColor),
        ),
      ],
    );
  }
}
