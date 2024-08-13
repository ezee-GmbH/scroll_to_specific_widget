import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_specific_widget/src/scroll_candidate.dart';
import 'package:scroll_to_specific_widget/src/scroll_candidate_selector_delegate.dart';
import 'package:scroll_to_specific_widget/src/scroll_coordinator.dart';

/// Responsible for connecting the presentation layer of the app
/// to a [ScrollCoordinator]. This involves creating a [ScrollCoordinator]
/// based on a [ScrollCandidateSelectorDelegate], providing that
/// [ScrollCoordinator] to the widget tree using a [Provider], and handling the
/// scroll events received from [ScrollCoordinator.listen] by calling
/// [ScrollController.animateTo], thereby performing the actual scrolling.
///
class ScrollCoordinatorConnector<K> extends StatefulWidget {
  const ScrollCoordinatorConnector({
    required this.scrollController,
    required this.candidateSelectorDelegate,
    required this.child,
    this.scrollAnimationCurve,
    this.scrollAnimationDuration,
    super.key,
  });

  final ScrollController scrollController;

  final ScrollCandidateSelectorDelegate<K> candidateSelectorDelegate;

  final Widget child;

  final Duration? scrollAnimationDuration;
  final Curve? scrollAnimationCurve;

  @override
  State<ScrollCoordinatorConnector<K>> createState() =>
      _ScrollCoordinatorConnectorState<K>();
}

class _ScrollCoordinatorConnectorState<K>
    extends State<ScrollCoordinatorConnector<K>> {
  static const _defaultScrollAnimationDuration = Duration(milliseconds: 500);
  static const _defaultScrollAnimationCurve = Curves.easeOutCubic;

  late final _scrollCoordinator = ScrollCoordinator<K>(
    candidateSelectorDelegate: widget.candidateSelectorDelegate,
  );

  ScrollController get _scrollController => widget.scrollController;

  @override
  void initState() {
    super.initState();
    _scrollCoordinator.listen(_scrollCoordinatorListener);
  }

  @override
  void dispose() {
    _scrollCoordinator.dispose();
    super.dispose();
  }

  Future<void> _scrollCoordinatorListener(
    ScrollCandidate scrollCandidate,
  ) async {
    var clampedOffset = clampDouble(
      scrollCandidate.scrollOffset,
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    if (clampedOffset > _scrollController.position.pixels) {
      clampedOffset = _scrollController.position.pixels;
    }

    await _scrollController.animateTo(
      scrollCandidate.scrollOffset,
      duration:
          widget.scrollAnimationDuration ?? _defaultScrollAnimationDuration,
      curve: widget.scrollAnimationCurve ?? _defaultScrollAnimationCurve,
    );
    scrollCandidate.onScrollToOffset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _scrollCoordinator,
      child: widget.child,
    );
  }
}
