import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// This is a placeholder file to satisfy imports
// Implement the actual widget as needed

class AnimatedSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String hintText;
  final bool showSearchSuggestions;
  final List<String>? searchSuggestions;

  const AnimatedSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText = 'Search shops, services, locations...',
    this.showSearchSuggestions = false,
    this.searchSuggestions,
  }) : super(key: key);

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Animation setup
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool isFocused) {
    if (isFocused) {
      _animationController.forward();
    } else if (_controller.text.isEmpty) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(width: 16),
          // Search icon
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              color: Colors.grey[400],
              size: 18,
            ),
          ),
          // TextField
          Expanded(
            child: Focus(
              onFocusChange: _onFocusChange,
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  widget.onSearch(value);
                  setState(() {});
                },
                onSubmitted: widget.onSearch,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 16),
                cursorColor: AppConstants.primaryColor,
              ),
            ),
          ),
          // Clear button if text is entered
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.xmark,
                size: 16,
                color: Colors.grey[400],
              ),
              onPressed: () {
                _controller.clear();
                widget.onSearch('');
                setState(() {});
              },
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              iconSize: 16,
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
