class SaveReviewModel {
  final String reviewStatus;
  final String taskTargetId;
  final String? comment;
  final String? selectedOption;
  final String tContentId;
  final String contentId;

  SaveReviewModel({
    required this.reviewStatus,
    required this.taskTargetId,
    this.comment,
    this.selectedOption,
    required this.tContentId,
    required this.contentId,
  });

  String getQueryParameters() {
    // URL encode the parameters to handle special characters
    return 'reviewStatus=${Uri.encodeComponent(reviewStatus)}'
        '&taskTargetId=${Uri.encodeComponent(taskTargetId)}'
        '&comment=${comment != null ? Uri.encodeComponent(comment!) : ''}'
        '&selectedOption=${selectedOption != null ? Uri.encodeComponent(selectedOption!) : ''}'
        '&tContentId=${Uri.encodeComponent(tContentId)}'
        '&contentId=${Uri.encodeComponent(contentId)}';
  }
}