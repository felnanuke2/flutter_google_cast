import 'package:flutter/material.dart';

/// A widget that scrolls text horizontally when it overflows its container.
/// If the text fits within the container, it displays statically centered.
class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration scrollDuration;
  final Duration pauseDuration;
  final double scrollSpeed;
  final int maxLines;
  final TextAlign textAlign;

  const ScrollingText({
    super.key,
    required this.text,
    this.style,
    this.scrollDuration = const Duration(milliseconds: 8000),
    this.pauseDuration = const Duration(milliseconds: 2000),
    this.scrollSpeed = 50.0,
    this.maxLines = 1,
    this.textAlign = TextAlign.center,
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;
  bool _needsScrolling = false;
  double _textWidth = 0;
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: widget.scrollDuration,
      vsync: this,
    );

    _scrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollController,
      curve: Curves.linear,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollingNeeded();
    });
  }

  @override
  void didUpdateWidget(ScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.scrollDuration != widget.scrollDuration) {
      // Reset and recalculate when text or style changes
      _scrollController.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfScrollingNeeded();
      });
    }
  }

  void _checkIfScrollingNeeded() {
    if (!mounted) return;

    // Use a post-frame callback to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final newContainerWidth = renderBox.size.width;

        // Don't proceed if container width is invalid
        if (newContainerWidth <= 0) return;

        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        );
        textPainter.layout();
        final newTextWidth = textPainter.size.width;

        final shouldScroll = newTextWidth > newContainerWidth;

        // Only update if something actually changed
        if (shouldScroll != _needsScrolling ||
            newTextWidth != _textWidth ||
            newContainerWidth != _containerWidth) {
          setState(() {
            _needsScrolling = shouldScroll;
            _textWidth = newTextWidth;
            _containerWidth = newContainerWidth;
          });

          if (_needsScrolling) {
            _startScrolling();
          } else {
            _scrollController.reset();
          }
        }
      }
    });
  }

  void _startScrolling() async {
    if (!mounted || !_needsScrolling) return;

    // Initial pause to let user read the beginning
    await Future.delayed(widget.pauseDuration);
    if (!mounted || !_needsScrolling) return;

    // Scroll to show the rest of the text
    await _scrollController.forward();
    if (!mounted || !_needsScrolling) return;

    // Pause at the end to let user read the end
    await Future.delayed(widget.pauseDuration);
    if (!mounted || !_needsScrolling) return;

    // Reset and repeat
    _scrollController.reset();

    // Small delay before starting again
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_needsScrolling) return;

    _startScrolling(); // Repeat the cycle
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Handle case where constraints are not available yet or invalid
        if (constraints.maxWidth <= 0 ||
            constraints.maxWidth == double.infinity) {
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
          );
        }

        // Update dimensions if container width changed
        if (_containerWidth != constraints.maxWidth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkIfScrollingNeeded();
          });
        }

        if (!_needsScrolling) {
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
          );
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _scrollAnimation,
            builder: (context, child) {
              // Calculate the exact distance needed to show the complete text
              // We want to scroll from showing the beginning to showing the end
              final scrollDistance = _textWidth - constraints.maxWidth;
              final offset = _scrollAnimation.value * scrollDistance;

              return Transform.translate(
                offset: Offset(-offset, 0),
                child: SizedBox(
                  width: _textWidth,
                  child: Text(
                    widget.text,
                    style: widget.style,
                    maxLines: widget.maxLines,
                    overflow: TextOverflow.visible,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
