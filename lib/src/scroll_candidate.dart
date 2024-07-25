// imported for docs
import 'package:scroll_to_specific_widget/src/scroll_candidate_callback_registerer.dart';

/// Created by [ScrollCandidateCallbackRegisterer].
/// Contains the target scroll offset as well as an optional void callback
/// [onScrollToOffset].
class ScrollCandidate {
  ScrollCandidate({
    required this.scrollOffset,
    required this.onScrollToOffset,
  });

  final double scrollOffset;
  final void Function()? onScrollToOffset;
}
