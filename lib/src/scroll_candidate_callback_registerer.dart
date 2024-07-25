import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:outcome_types/outcome_types.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_specific_widget/src/scroll_candidate.dart';
import 'package:scroll_to_specific_widget/src/scroll_coordinator.dart';

/// Responsible for registering a scroll candidate callback to the nearest
/// ancestor [ScrollCoordinator]<K> in the widget tree.
///
/// Once called, the scroll candidate callback will try to obtain the
/// current scroll offset of this widget in the nearest ancestor
/// [RenderAbstractViewport].
class ScrollCandidateCallbackRegisterer<K> extends StatefulWidget {
  const ScrollCandidateCallbackRegisterer({
    required this.child,
    required this.scrollCandidateKey,
    this.onScrollToCandidate,
    super.key,
  });

  final Widget child;
  final K scrollCandidateKey;
  final VoidCallback? onScrollToCandidate;

  @override
  State<ScrollCandidateCallbackRegisterer<K>> createState() =>
      _ScrollCandidateCallbackRegistererState<K>();
}

class _ScrollCandidateCallbackRegistererState<K>
    extends State<ScrollCandidateCallbackRegisterer<K>>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey();
  final _registrationKey = UniqueKey();

  ScrollCoordinator<K>? _scrollMaster;

  @override
  void initState() {
    super.initState();
    _registerScrollEventCallback(widget.scrollCandidateKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unregisterScrollEventCallback(widget.scrollCandidateKey);
    _scrollMaster = context.read<ScrollCoordinator<K>>();
    _registerScrollEventCallback(widget.scrollCandidateKey);
  }

  @override
  void didUpdateWidget(
    covariant ScrollCandidateCallbackRegisterer<K> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollCandidateKey != widget.scrollCandidateKey) {
      _unregisterScrollEventCallback(oldWidget.scrollCandidateKey);
      _scrollMaster = context.read<ScrollCoordinator<K>>();
      _registerScrollEventCallback(widget.scrollCandidateKey);
    }
  }

  @override
  void dispose() {
    _unregisterScrollEventCallback(widget.scrollCandidateKey);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Option<ScrollCandidate> _createScrollCandidate() {
    if (_key.currentContext case final currentContext?) {
      final renderBox = currentContext.findRenderObject();
      final viewport = RenderAbstractViewport.maybeOf(renderBox);
      if ((viewport, renderBox) case (final viewport?, final renderBox?)) {
        final offset = viewport
            .getOffsetToReveal(
              renderBox,
              0, // scroll until top of target is visible
            )
            .offset;

        return Some(
          ScrollCandidate(
            scrollOffset: offset,
            onScrollToOffset: widget.onScrollToCandidate,
          ),
        );
      }
    }

    assert(false, 'Could not create scroll candidate');
    return const None();
  }

  void _registerScrollEventCallback(K candidateKey) {
    _scrollMaster?.registerScrollCandidateCallback(
      candidateKey: candidateKey,
      candidateCallback: _createScrollCandidate,
      registrationKey: _registrationKey,
    );
  }

  void _unregisterScrollEventCallback(K candidateKey) =>
      _scrollMaster?.unregisterScrollCandidateCallback(
        candidateKey: candidateKey,
        registrationKey: _registrationKey,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      key: _key,
      child: widget.child,
    );
  }
}
