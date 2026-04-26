import 'package:flutter/material.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnimatedSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String? hintText;
  final bool showSearchSuggestions;
  final List<String>? searchSuggestions;

  const AnimatedSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
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
              color: theme.colorScheme.onSurfaceVariant,
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
                  hintText: widget.hintText ?? 'search_shops_services'.tr(context),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  widget.onSearch(value);
                  setState(() {});
                },
                onSubmitted: widget.onSearch,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
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
                color: theme.colorScheme.onSurfaceVariant,
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
