import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wonwonw2/services/advanced_search_service.dart';
import 'package:wonwonw2/models/repair_shop.dart';

class AdvancedSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(String) onSuggestionSelected;
  final AdvancedSearchService searchService;
  final List<RepairShop> shops;
  final String hintText;
  final bool showSearchHistory;

  const AdvancedSearchBar({
    Key? key,
    required this.onSearch,
    required this.onSuggestionSelected,
    required this.searchService,
    required this.shops,
    this.hintText = 'Search shops, services, locations...',
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
        if (!_focusNode.hasFocus) {
          _hideSuggestionsOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
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
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

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
            offset: Offset(isMobile ? -8 : 0, 60), // Adjust for mobile
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
                child: _buildSuggestionsList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final maxHeight =
        isMobile ? screenSize.height * 0.4 : 300.0; // Limit height on mobile

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isMobile ? 0.05 : 0.1),
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
            _buildSectionHeader('Recent Searches', Icons.history),
          if (_controller.text.isNotEmpty)
            _buildSectionHeader('Suggestions', Icons.search),

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion, bool isHistory, bool isLast) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 16 : 12, // Larger touch targets on mobile
        ),
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Icon(
              isHistory ? Icons.history : Icons.search,
              size: isMobile ? 20 : 18,
              color: Colors.grey.shade500,
            ),
            SizedBox(width: isMobile ? 16 : 12),
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 14,
                  fontWeight: FontWeight.w400,
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
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearHistoryButton() {
    return InkWell(
      onTap: _clearHistory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.clear_all, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'Clear Search History',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
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
      widget.searchService.addToHistory(query);
      widget.onSearch(query);
    }
    _focusNode.unfocus();
    _hideSuggestionsOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(Icons.search, color: Colors.grey.shade500, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            if (_controller.text.isNotEmpty)
              InkWell(
                onTap: () {
                  _controller.clear();
                  widget.onSearch('');
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.clear,
                    color: Colors.grey.shade500,
                    size: 20,
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
