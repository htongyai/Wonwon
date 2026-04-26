import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/services/advanced_search_service.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/services/analytics_service.dart';

class AdvancedSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(String) onSuggestionSelected;
  final AdvancedSearchService searchService;
  final List<RepairShop> shops;
  final String? hintText;
  final bool showSearchHistory;

  const AdvancedSearchBar({
    Key? key,
    required this.onSearch,
    required this.onSuggestionSelected,
    required this.searchService,
    required this.shops,
    this.hintText,
    this.showSearchHistory = true,
  }) : super(key: key);

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<String> _currentSuggestions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
      _showSuggestionsOverlay();
    } else {
      // Delay hiding to allow for suggestion selection
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          _hideSuggestionsOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _updateSuggestions();
      if (_focusNode.hasFocus) {
        _showSuggestionsOverlay();
      }
    });
  }

  void _updateSuggestions() {
    final suggestions = widget.searchService.generateSuggestions(
      _controller.text,
      widget.shops,
    );

    setState(() {
      _currentSuggestions = suggestions;
    });

    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showSuggestionsOverlay() {
    if (_overlayEntry != null || _currentSuggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildSuggestionsOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideSuggestionsOverlay() {
    if (_overlayEntry == null) return;

    _animationController.reverse().then((_) {
      if (!mounted) return;
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardHeight = viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;
    final isMobile = ResponsiveBreakpoints.isMobile(screenSize.width);

    // When keyboard is open on mobile, position overlay above the search bar
    final maxHeight = isMobile
        ? (screenSize.height - keyboardHeight - 120)
            .clamp(100.0, screenSize.height * 0.4)
            .toDouble()
        : 300.0;
    final positionAbove = isMobile && keyboardOpen;
    final verticalOffset = positionAbove ? -maxHeight : 60.0;

    return Stack(
      children: [
        // Invisible overlay to capture taps outside suggestions
        if (isMobile)
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideSuggestionsOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
        // Suggestions dropdown
        Positioned(
          width: isMobile ? screenSize.width - 16 : screenSize.width - 32,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(isMobile ? -8 : 0, verticalOffset),
            child: Material(
              elevation: isMobile ? 4 : 8,
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * _fadeAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: _buildSuggestionsList(maxHeight: maxHeight),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList({double? maxHeight}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = ResponsiveBreakpoints.isMobile(screenSize.width);
    final effectiveMaxHeight = maxHeight ??
        (isMobile ? screenSize.height * 0.4 : 300.0);

    return Container(
      constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: isDark ? 0.3 : (isMobile ? 0.05 : 0.1)),
            blurRadius: isMobile ? 4 : 8,
            offset: Offset(0, isMobile ? 2 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          if (_controller.text.isEmpty && widget.showSearchHistory)
            _buildSectionHeader('recent_searches'.tr(context), Icons.history),
          if (_controller.text.isNotEmpty)
            _buildSectionHeader('suggestions'.tr(context), Icons.search),

          // Suggestions list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _currentSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _currentSuggestions[index];
                final isHistory = widget.searchService.searchHistory.contains(
                  suggestion.toLowerCase(),
                );

                return _buildSuggestionItem(
                  suggestion,
                  isHistory,
                  index == _currentSuggestions.length - 1,
                );
              },
            ),
          ),

          // Clear history button
          if (_controller.text.isEmpty &&
              widget.showSearchHistory &&
              widget.searchService.searchHistory.isNotEmpty)
            _buildClearHistoryButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion, bool isHistory, bool isLast) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = ResponsiveBreakpoints.isMobile(screenSize.width);

    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 16 : 12, // Larger touch targets on mobile
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            Icon(
              isHistory ? Icons.history : Icons.search,
              size: isMobile ? 20 : 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: isMobile ? 16 : 12),
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 14,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isHistory)
              InkWell(
                onTap: () => _removeFromHistory(suggestion),
                child: Padding(
                  padding: EdgeInsets.all(
                    isMobile ? 8 : 4,
                  ), // Larger touch target
                  child: Icon(
                    Icons.close,
                    size: isMobile ? 18 : 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearHistoryButton() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _clearHistory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.clear_all,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'clear_search_history'.tr(context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _focusNode.unfocus();
    _hideSuggestionsOverlay();

    // Add to history and trigger search
    widget.searchService.addToHistory(suggestion);
    widget.onSuggestionSelected(suggestion);
    widget.onSearch(suggestion);
  }

  void _removeFromHistory(String suggestion) {
    widget.searchService.removeFromHistory(suggestion);
    _updateSuggestions();
  }

  void _clearHistory() {
    widget.searchService.clearHistory();
    _updateSuggestions();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      AnalyticsService.safeLog(() => AnalyticsService().logSearch(query));
      widget.searchService.addToHistory(query);
      widget.onSearch(query);
    }
    _focusNode.unfocus();
    _hideSuggestionsOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(Icons.search,
                color: theme.colorScheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'search_shops_services'.tr(context),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            if (_controller.text.isNotEmpty)
              SizedBox(
                width: 44,
                height: 44,
                child: InkWell(
                  onTap: () {
                    _controller.clear();
                    widget.onSearch('');
                  },
                  child: Center(
                    child: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
