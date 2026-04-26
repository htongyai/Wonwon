import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/models/review.dart';
import 'package:wonwon_client/screens/login_screen.dart';
import 'package:wonwon_client/screens/report_form_screen.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/review_service.dart';
import 'package:shared/services/report_service.dart';
import 'package:shared/services/saved_shop_service.dart';
import 'package:shared/utils/asset_helpers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonwon_client/screens/log_repair_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:shared/utils/hours_formatter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared/mixins/widget_disposal_mixin.dart';
import 'package:shared/services/optimized_image_cache_manager.dart';
import 'package:shared/services/unified_memory_manager.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:shared/services/shop_analytics_service.dart';
import 'package:wonwon_client/widgets/common/branded_snackbar.dart';
import 'package:wonwon_client/widgets/skeletons/shop_detail_skeleton.dart';
import 'package:wonwon_client/widgets/common/animated_bookmark.dart';
import 'package:wonwon_client/widgets/sustainability/eco_badges.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';

/// Shop detail screen with a clean, modern card-based layout.
/// Displays shop photos, info, services, hours, reviews, and a mini map.
class ShopDetailScreen extends StatefulWidget {
  final String shopId;
  final String? selectedCategory;

  const ShopDetailScreen({
    Key? key,
    required this.shopId,
    this.selectedCategory,
  }) : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen>
    with WidgetDisposalMixin<ShopDetailScreen> {
  // -- Constants --
  static const Color _starColor = Color(0xFFFFB800);
  static const double _photoHeight = 250;
  static const double _mapHeight = 200;
  static const double _sectionRadius = 16.0;

  // -- Services --
  final ReviewService _reviewService = ReviewService();
  final ReportService _reportService = ReportService();
  final SavedShopService _savedShopService = SavedShopService();
  final AuthService _authService = AuthService();

  // -- State --
  late ScrollController _scrollController;
  late PageController _photoPageController;
  RepairShop? _shop;
  bool _isLoadingShop = true;
  String? _error;
  late final Future<void> _loadingTimeoutFuture;
  List<Review> _reviews = [];
  List<ShopReport> _reports = [];
  bool _isLoadingReviews = true;
  bool _isLoadingReports = true;
  bool _isSaved = false;
  bool _isLoadingSavedState = true;
  bool _isLoggedIn = false;
  int _currentPhotoIndex = 0;
  GoogleMapController? _mapController;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInitState() {
    _scrollController = createScrollController();
    _photoPageController = PageController();
    _loadingTimeoutFuture = Future.delayed(AppConstants.loadingTimeout);
    _fetchShop();
    _checkLoginStatus();
    _loadReviews();
    _loadReports();

    listenToStream(FirebaseAuth.instance.authStateChanges(), (User? user) {
      if (!mounted) return;
      setState(() => _isLoggedIn = user != null);
      if (user != null) {
        _checkIfSaved();
      } else {
        setState(() {
          _isSaved = false;
          _isLoadingSavedState = false;
        });
      }
    });
  }

  @override
  void onDispose() {
    _mapController?.dispose();
    _photoPageController.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _fetchShop() async {
    setState(() {
      _isLoadingShop = true;
      _error = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .get();
      if (!doc.exists) {
        if (!mounted) return;
        setState(() {
          _error = 'shop_not_found';
          _isLoadingShop = false;
        });
        return;
      }
      if (!mounted) return;
      final data = {...(doc.data() ?? {}), 'id': doc.id};
      final shop = RepairShop.fromMap(data);
      AnalyticsService.safeLog(() => AnalyticsService().logViewShop(
            shopId: widget.shopId,
            shopName: shop.name,
          ));
      ShopAnalyticsService().recordView(widget.shopId);
      setState(() {
        _shop = shop;
        _isLoadingShop = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'error_loading_shop';
        _isLoadingShop = false;
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;
    setState(() => _isLoggedIn = isLoggedIn);
    // _checkIfSaved() is handled by the authStateChanges listener
    if (!isLoggedIn) {
      setState(() => _isLoadingSavedState = false);
    }
  }

  Future<void> _checkIfSaved() async {
    try {
      final isSaved = await _savedShopService.isShopSaved(widget.shopId);
      if (!mounted) return;
      setState(() {
        _isSaved = isSaved;
        _isLoadingSavedState = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSavedState = false);
    }
  }

  Future<void> _toggleSaved() async {
    if (_isLoadingSavedState) return;

    if (!_isLoggedIn) {
      final loginResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      if (loginResult == true) {
        if (!mounted) return;
        setState(() {
          _isLoggedIn = true;
          _isLoadingSavedState = true;
        });
        await _checkIfSaved();
      }
      return;
    }

    final shop = _shop;
    if (shop == null) return;
    final wasSaved = _isSaved;
    HapticFeedback.lightImpact();
    setState(() {
      _isSaved = !wasSaved;
      _isLoadingSavedState = true;
    });

    if (mounted) {
      BrandedSnackBar.success(
        context,
        wasSaved
            ? 'removed_from_saved'
                .tr(context)
                .replaceAll('{shop_name}', shop.name)
            : 'saved_to_locations'
                .tr(context)
                .replaceAll('{shop_name}', shop.name),
      );
    }

    try {
      final bool success;
      if (wasSaved) {
        AnalyticsService.safeLog(
            () => AnalyticsService().logUnsaveShop(widget.shopId));
        ShopAnalyticsService().recordUnsave(widget.shopId);
        success = await _savedShopService.removeShop(widget.shopId);
      } else {
        AnalyticsService.safeLog(
            () => AnalyticsService().logSaveShop(widget.shopId));
        ShopAnalyticsService().recordSave(widget.shopId);
        success = await _savedShopService.saveShop(widget.shopId);
      }

      if (!success && mounted) {
        setState(() => _isSaved = wasSaved);
        BrandedSnackBar.error(
            context, 'failed_to_update_saved'.tr(context));
      }
    } catch (e) {
      if (mounted) {
        appLog('Error toggling saved shop: $e');
        setState(() => _isSaved = wasSaved);
        BrandedSnackBar.error(
            context, 'failed_to_update_saved'.tr(context));
      }
    } finally {
      if (mounted) setState(() => _isLoadingSavedState = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.getReviewsForShop(widget.shopId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _reportService.getReportsByShopId(widget.shopId);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoadingReports = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingReports = false);
    }
  }

  // ---------------------------------------------------------------------------
  // URL / navigation helpers
  // ---------------------------------------------------------------------------

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // Allow the schemes we actually use: web links, phone, email, and the
      // social app deep links that are whitelisted in iOS Info.plist.
      const allowedSchemes = <String>{
        'https', 'http', 'tel', 'mailto', 'line', 'fb', 'instagram',
      };
      if (!allowedSchemes.contains(uri.scheme)) {
        appLog('Blocked URL launch: unsupported scheme ${uri.scheme}');
        return;
      }

      // Try to launch first — on mobile Safari a `tel:` link opens the dialer
      // natively, so we should not pre-empt it by copying to clipboard.
      // Fall back to clipboard only for `tel:` when launching fails (desktop
      // browsers typically cannot dial).
      final launched = await _tryLaunch(uri);
      if (launched) return;

      if (uri.scheme == 'tel') {
        final number = uri.path;
        await Clipboard.setData(ClipboardData(text: number));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'number_copied'.tr(context).replaceAll('{number}', number),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      appLog('Error launching URL: $e');
    }
  }

  /// Attempt to launch a URL via url_launcher, returning whether it succeeded.
  /// Centralises the try/catch so callers can cleanly implement fallbacks.
  ///
  /// On mobile Safari and some Android browsers `canLaunchUrl` returns false
  /// for `tel:`, `mailto:`, and even `https:` even though `launchUrl` would
  /// succeed — the browser just can't introspect external handlers. For these
  /// universally-handled schemes we skip the canLaunch probe and call
  /// launchUrl directly.
  Future<bool> _tryLaunch(Uri uri) async {
    const alwaysLaunchable = <String>{'tel', 'mailto', 'http', 'https'};
    try {
      if (alwaysLaunchable.contains(uri.scheme)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      appLog('launchUrl failed for ${uri.scheme}: $e');
    }
    return false;
  }

  /// Normalize a user-entered social handle into a launchable https URL.
  /// Accepts: full URLs, bare usernames, "@handle".
  /// Returns null if the input cannot be normalized.
  String? _normalizeSocialUrl(String raw, {required String baseUrl}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // Already a full URL — use as-is.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // Strip leading @ then prefix the platform base URL.
    final handle = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    if (handle.isEmpty) return null;
    return '$baseUrl$handle';
  }

  /// Normalize a LINE identifier. If the value is already a URL we use it
  /// directly; otherwise we wrap it with the standard line.me/ti/p path.
  String _normalizeLineUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('line://') || trimmed.startsWith('line:')) {
      return trimmed;
    }
    final handle =
        trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    return 'https://line.me/ti/p/$handle';
  }

  Future<void> _openDirections() async {
    if (_shop == null) return;
    AnalyticsService.safeLog(
        () => AnalyticsService().logGetDirections(widget.shopId));
    ShopAnalyticsService().recordDirections(widget.shopId);
    final lat = _shop!.latitude;
    final lng = _shop!.longitude;
    final name = Uri.encodeComponent(_shop!.name);
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name';
    await _launchUrl(url);
  }

  // ---------------------------------------------------------------------------
  // Day / date helpers
  // ---------------------------------------------------------------------------

  bool _isToday(String dayKey) {
    final now = DateTime.now();
    const shortKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return shortKeys[now.weekday - 1] == dayKey;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'today_label'.tr(context);
    } else if (difference.inDays == 1) {
      return 'yesterday_label'.tr(context);
    } else if (difference.inDays < 7) {
      return 'time_days_ago'
          .tr(context)
          .replaceAll('{count}', '${difference.inDays}');
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  // ---------------------------------------------------------------------------
  // Localization helpers
  // ---------------------------------------------------------------------------

  String _localizePayment(String method) {
    final key = 'payment_${method.toLowerCase()}';
    final localized = key.tr(context);
    return localized != key ? localized : method;
  }

  String _localizeFeature(String feature) {
    final key =
        'feature_${feature.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'_$'), '')}';
    final localized = key.tr(context);
    return localized != key ? localized : feature;
  }

  String _localizeAmenity(String amenity) {
    final key =
        'amenity_${amenity.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'_$'), '')}';
    final localized = key.tr(context);
    return localized != key ? localized : amenity;
  }

  // ---------------------------------------------------------------------------
  // Review dialog
  // ---------------------------------------------------------------------------

  void _showAddReviewDialog() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_login_to_review'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rating = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        int selectedRating = 0;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('add_review'.tr(context)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('select_rating'.tr(context)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: i < selectedRating
                              ? _starColor
                              : Theme.of(context).dividerColor,
                          size: 36,
                        ),
                        onPressed: () =>
                            setDialogState(() => selectedRating = i + 1),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr(context)),
                ),
                TextButton(
                  onPressed: selectedRating > 0
                      ? () => Navigator.pop(context, selectedRating)
                      : null,
                  child: Text('submit'.tr(context)),
                ),
              ],
            );
          },
        );
      },
    );

    if (rating == null) return;

    final result = await showDialog<({String comment, bool anonymous})>(
      context: context,
      builder: (context) {
        String draft = '';
        bool anonymous = false;
        String? validationError;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('add_comment'.tr(context)),
              // Scrollable so the anonymous checkbox stays reachable when the
              // iOS keyboard is up — tester reported the option appeared
              // "missing" because it was hidden below the keyboard.
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'enter_comment'.tr(context),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        errorText: validationError,
                      ),
                      maxLines: 3,
                      autofocus: true,
                      onChanged: (value) => setDialogState(() {
                        draft = value;
                        if (validationError != null &&
                            value.trim().isNotEmpty) {
                          validationError = null;
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () =>
                          setDialogState(() => anonymous = !anonymous),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: anonymous,
                              onChanged: (v) => setDialogState(
                                  () => anonymous = v ?? false),
                              activeColor: AppConstants.primaryColor,
                            ),
                            Expanded(
                              child: Text('post_anonymously'.tr(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr(context)),
                ),
                // Always enabled — show inline validation if empty so the
                // user understands why submission is rejected (tester
                // reported a disabled button looked like "nothing happens").
                TextButton(
                  onPressed: () {
                    final trimmed = draft.trim();
                    if (trimmed.isEmpty) {
                      setDialogState(() {
                        validationError = 'comment_required'.tr(context);
                      });
                      return;
                    }
                    Navigator.pop(
                      context,
                      (comment: trimmed, anonymous: anonymous),
                    );
                  },
                  child: Text('submit'.tr(context)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result.comment.isEmpty) return;
    final comment = result.comment;
    final isAnonymous = result.anonymous;

    // Defensive validation — the UI dialog only emits 1..5, but we
    // double-check here so that any future caller (or accidental
    // mutation) cannot push an out-of-range rating into the service
    // layer where it would surface as an ArgumentError caught by the
    // generic handler below. This produces a clear, actionable message
    // instead of "Error adding review".
    if (rating < 1 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invalid_rating_range'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final review = Review(
        id: '',
        shopId: widget.shopId,
        userId: user.uid,
        userName: user.displayName ?? 'anonymous'.tr(context),
        rating: rating.toDouble(),
        comment: comment,
        createdAt: DateTime.now(),
        replies: [],
        isAnonymous: isAnonymous,
      );

      await _reviewService.addReview(review);
      AnalyticsService.safeLog(() => AnalyticsService().logWriteReview(
            shopId: widget.shopId,
            rating: rating.toDouble(),
          ));
      if (!mounted) return;
      _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('review_added'.tr(context)),
          backgroundColor: Colors.green,
        ),
      );
    } on ArgumentError catch (e) {
      // ReviewService.addReview throws ArgumentError for invalid
      // rating / empty comment. Surface the specific reason rather
      // than the generic "error" message — these are user-correctable.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message?.toString() ?? 'invalid_rating_range'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_adding_review'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reply to review
  // ---------------------------------------------------------------------------

  Future<void> _showReplyDialog(Review review) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_login_to_review'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        String draft = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSubmit = draft.trim().isNotEmpty;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('add_reply'.tr(context)),
              content: TextField(
                decoration: InputDecoration(
                  hintText: 'reply_hint'.tr(context),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                autofocus: true,
                onChanged: (value) =>
                    setDialogState(() => draft = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr(context)),
                ),
                TextButton(
                  onPressed: canSubmit
                      ? () => Navigator.pop(context, draft.trim())
                      : null,
                  child: Text('submit'.tr(context)),
                ),
              ],
            );
          },
        );
      },
    );

    if (text == null || text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final reply = ReviewReply(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        userName: user.displayName ?? 'anonymous'.tr(context),
        comment: text,
        createdAt: DateTime.now(),
      );
      await _reviewService.addReplyToReview(
        shopId: widget.shopId,
        reviewId: review.id,
        reply: reply,
      );
      if (!mounted) return;
      _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reply_posted'.tr(context)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_posting_reply'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Delete own review
  // ---------------------------------------------------------------------------

  Future<void> _showDeleteReviewConfirmation(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('delete_review'.tr(ctx)),
        content: Text('confirm_delete_review'.tr(ctx)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr(ctx)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr(ctx)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _reviewService.deleteReview(
        widget.shopId,
        review.id,
        review.userId,
      );
      if (!mounted) return;
      if (success) {
        _loadReviews();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('review_deleted'.tr(context)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_deleting_review'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_deleting_review'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Report dialog
  // ---------------------------------------------------------------------------

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('report_shop'.tr(context)),
        content: Text('report_shop_message'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportFormScreen(shopId: widget.shopId),
                ),
              );
            },
            child: Text('report'.tr(context)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingShop) {
      return Scaffold(
        body: FutureBuilder(
          future: _loadingTimeoutFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'error_loading_shop'.tr(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchShop,
                      icon: const Icon(Icons.refresh),
                      label: Text('retry'.tr(context)),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: Text('back'.tr(context)),
                    ),
                  ],
                ),
              );
            }
            return const ShopDetailSkeleton();
          },
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!.tr(context),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchShop,
                icon: const Icon(Icons.refresh),
                label: Text('retry'.tr(context)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text('back'.tr(context)),
              ),
            ],
          ),
        ),
      );
    }
    if (_shop == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'shop_not_found'.tr(context),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text('back'.tr(context)),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= ResponsiveBreakpoints.desktop;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT
  // ===========================================================================

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // -- Photo gallery with overlaid back / action buttons --
              SliverToBoxAdapter(child: _buildPhotoGallery()),
              // -- Body content --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildShopHeader(),
                      const SizedBox(height: 20),
                      _buildActionButtonsRow(),
                      _buildDivider(),
                      _buildOpeningHoursSection(),
                      _buildDivider(),
                      _buildServicesSection(),
                      _buildDivider(),
                      _buildContactSection(),
                      _buildDivider(),
                      _buildBusinessInfoSection(),
                      _buildDivider(),
                      _buildPaymentMethodsSection(),
                      _buildDivider(),
                      _buildFeaturesSection(),
                      _buildDivider(),
                      _buildReviewsSection(),
                      _buildDivider(),
                      _buildLocationSection(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // -- Sticky bottom bar --
        _buildBottomBar(),
      ],
    );
  }

  // ===========================================================================
  // DESKTOP LAYOUT (two-column)
  // ===========================================================================

  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = ResponsiveBreakpoints.isLargeDesktop(screenWidth);

    return Column(
      children: [
        _buildDesktopTopBar(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: photos + info
              SizedBox(
                width: isLarge ? 520 : 440,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildPhotoGallery(isDesktop: true),
                      const SizedBox(height: 24),
                      _buildShopHeader(),
                      const SizedBox(height: 20),
                      _buildActionButtonsRow(),
                      _buildDivider(),
                      _buildOpeningHoursSection(),
                      _buildDivider(),
                      _buildServicesSection(),
                      _buildDivider(),
                      _buildContactSection(),
                      _buildDivider(),
                      _buildBusinessInfoSection(),
                      _buildDivider(),
                      _buildPaymentMethodsSection(),
                      _buildDivider(),
                      _buildFeaturesSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Right column: map + reviews
              Expanded(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildLocationSection(desktopMapHeight: 400),
                      const SizedBox(height: 24),
                      _buildReviewsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTopBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _shop!.name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          if (_isLoggedIn)
            _outlinedChip(
              icon: Icons.build_outlined,
              label: 'log_repair'.tr(context),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LogRepairScreen(shop: _shop!)),
              ),
            ),
          const SizedBox(width: 8),
          _outlinedChip(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: _isSaved ? 'saved'.tr(context) : 'save_shop'.tr(context),
            onTap: _toggleSaved,
            filled: _isSaved,
          ),
          const SizedBox(width: 8),
          _outlinedChip(
            icon: Icons.flag_outlined,
            label: 'report'.tr(context),
            onTap: _showReportDialog,
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PHOTO GALLERY
  // ===========================================================================

  Widget _buildPhotoGallery({bool isDesktop = false}) {
    final photos = _shop!.photos;
    final height = isDesktop ? 220.0 : _photoHeight;
    final radius = isDesktop ? _sectionRadius : 0.0;

    Widget gallery;
    if (photos.isEmpty) {
      gallery = AssetHelpers.getShopPlaceholder(
        _shop!.name,
        containerWidth: MediaQuery.of(context).size.width,
        containerHeight: height,
      );
    } else {
      gallery = Stack(
        children: [
          PageView.builder(
            controller: _photoPageController,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
            itemBuilder: (context, index) {
              return getCachedImage(
                imageUrl: photos[index],
                imageType: ImageType.shop,
                priority: MemoryPriority.high,
                fit: BoxFit.cover,
                errorWidget: AssetHelpers.getShopPlaceholder(
                  _shop!.name,
                  containerWidth: MediaQuery.of(context).size.width,
                  containerHeight: height,
                ),
              );
            },
          ),
          // Dot indicators
          if (photos.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (i) {
                  final isActive = i == _currentPhotoIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          // Photo count pill
          if (photos.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentPhotoIndex + 1} / ${photos.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // Wrap with back button and action overlays for mobile
    if (!isDesktop) {
      return SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: gallery,
            ),
            // Gradient scrim at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black38, Colors.transparent],
                  ),
                ),
              ),
            ),
            // Back button
            Positioned(
              top: 8,
              left: 8,
              child: _circleButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
                light: true,
              ),
            ),
            // Save + Report
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _circleButton(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    onTap: _toggleSaved,
                    light: true,
                    iconColor: _isSaved ? _starColor : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      _circleButton(
                        icon: Icons.flag_outlined,
                        onTap: _showReportDialog,
                        light: true,
                        iconColor: Colors.red.shade300,
                      ),
                      if (!_isLoadingReports && _reports.isNotEmpty)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Center(
                              child: Text(
                                _reports.length > 9
                                    ? '9+'
                                    : '${_reports.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(height: height, child: gallery),
    );
  }

  // ===========================================================================
  // SHOP HEADER (name, rating, address)
  // ===========================================================================

  Widget _buildShopHeader() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          _shop!.name,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        // Rating row
        Row(
          children: [
            const Icon(Icons.star_rounded, color: _starColor, size: 20),
            const SizedBox(width: 4),
            Text(
              _shop!.rating.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_shop!.reviewCount} ${'reviews_label'.tr(context)})',
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            if (HoursFormatter.isShopOpen(_shop!.hours)) ...[
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'open_now'.tr(context),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _buildFullAddress(),
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        // Eco-badges (if any)
        if (_shop!.ecoBadges.isNotEmpty) ...[
          const SizedBox(height: 12),
          EcoBadgesRow(badgeIds: _shop!.ecoBadges),
        ],
        // Description
        if (_shop!.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _shop!.description,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
        // Owner story (editorial pull-quote)
        if (_shop!.ownerStory != null && _shop!.ownerStory!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildOwnerStory(),
        ],
      ],
    );
  }

  Widget _buildOwnerStory() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EcoPalette.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EcoPalette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 1,
                color: EcoPalette.inkMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'shop_story_eyebrow'.tr(context),
                style: EditorialTypography.eyebrow,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"${_shop!.ownerStory!}"',
            style: EditorialTypography.displayQuote,
          ),
          const SizedBox(height: 10),
          Text(
            '— ${_shop!.name}',
            style: EditorialTypography.caption.copyWith(
              color: EcoPalette.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _buildFullAddress() {
    final parts = <String>[_shop!.address];
    if (_shop!.district != null && _shop!.district!.isNotEmpty) {
      parts.add(_shop!.district!);
    }
    if (_shop!.province != null && _shop!.province!.isNotEmpty) {
      parts.add(_shop!.province!);
    }
    if (_shop!.area.isNotEmpty && !parts.contains(_shop!.area)) {
      parts.add(_shop!.area);
    }
    return parts.join(', ');
  }

  // ===========================================================================
  // ACTION BUTTONS ROW (Call, Map, Line, Log Repair)
  // ===========================================================================

  Widget _buildActionButtonsRow() {
    final phone = _shop?.phoneNumber;
    final lineId = _shop?.lineId;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (phone != null && phone.isNotEmpty)
            _actionChip(
              icon: Icons.phone_outlined,
              label: 'phone_label'.tr(context),
              onTap: () {
                _launchUrl('tel:$phone');
                ShopAnalyticsService().recordContact(widget.shopId);
              },
            ),
          _actionChip(
            icon: Icons.directions_outlined,
            label: 'directions'.tr(context),
            onTap: _openDirections,
          ),
          if (lineId != null && lineId.isNotEmpty)
            _actionChip(
              icon: Icons.chat_outlined,
              label: 'line_contact'.tr(context),
              onTap: () {
                _launchUrl(_normalizeLineUrl(lineId));
                ShopAnalyticsService().recordContact(widget.shopId);
              },
            ),
          if (_isLoggedIn)
            _actionChip(
              icon: Icons.build_outlined,
              label: 'log_repair'.tr(context),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LogRepairScreen(shop: _shop!)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  // ===========================================================================
  // SERVICES SECTION
  // ===========================================================================

  Widget _buildServicesSection() {
    if (_shop!.categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('services'.tr(context)),
        const SizedBox(height: 12),
        ..._shop!.categories.map((category) {
          final subServices = _shop!.subServices[category] ?? [];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                InkWell(
                  onTap: () =>
                      Navigator.pop(context, {'filterCategory': category}),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            AppConstants.primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'category_$category'.tr(context),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ),
                // Sub-services list
                if (subServices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subServices.map((sub) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'subservice_${category}_$sub'.tr(context),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // OPENING HOURS
  // ===========================================================================

  Widget _buildOpeningHoursSection() {
    final dayNames = [
      'day_monday'.tr(context),
      'day_tuesday'.tr(context),
      'day_wednesday'.tr(context),
      'day_thursday'.tr(context),
      'day_friday'.tr(context),
      'day_saturday'.tr(context),
      'day_sunday'.tr(context),
    ];
    const shortKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final isOpen = HoursFormatter.isShopOpen(_shop!.hours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('hours_label'.tr(context))),
            if (isOpen)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'open_now'.tr(context),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_sectionRadius),
          ),
          child: Column(
            children: List.generate(dayNames.length, (i) {
              final dayKey = shortKeys[i];
              final hours = _shop!.hours[dayKey];
              final isToday = _isToday(dayKey);
              final theme = Theme.of(context);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        dayNames[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday
                              ? AppConstants.primaryColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              AppConstants.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'today_label'.tr(context),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      HoursFormatter.formatHours(hours, context),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.normal,
                        color: isToday
                            ? AppConstants.primaryColor
                            : (hours != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant),
                        fontStyle:
                            hours == null ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        if (_shop!.irregularHours) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.orange.shade600),
              const SizedBox(width: 6),
              Text(
                'irregular_hours'.tr(context),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // CONTACT SECTION
  // ===========================================================================

  Widget _buildContactSection() {
    final shop = _shop!;
    final phone = shop.phoneNumber;
    final hasContent = (phone != null && phone.isNotEmpty) ||
        (shop.facebookPage != null && shop.facebookPage!.isNotEmpty) ||
        (shop.instagramPage != null && shop.instagramPage!.isNotEmpty) ||
        (shop.lineId != null && shop.lineId!.isNotEmpty) ||
        (shop.otherContacts != null && shop.otherContacts!.isNotEmpty);

    if (!hasContent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('contact_label'.tr(context)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_sectionRadius),
          ),
          child: Column(
            children: [
              if (phone != null && phone.isNotEmpty)
                _contactRow(Icons.phone_outlined, phone,
                    onTap: () {
                  _launchUrl('tel:$phone');
                  ShopAnalyticsService().recordContact(widget.shopId);
                }),
              if (shop.facebookPage != null &&
                  shop.facebookPage!.isNotEmpty)
                _contactRow(Icons.facebook, shop.facebookPage!, onTap: () {
                  final url = _normalizeSocialUrl(shop.facebookPage!,
                      baseUrl: 'https://www.facebook.com/');
                  if (url != null) {
                    _launchUrl(url);
                    ShopAnalyticsService().recordContact(widget.shopId);
                  }
                }),
              if (shop.instagramPage != null &&
                  shop.instagramPage!.isNotEmpty)
                _contactRow(Icons.camera_alt_outlined, shop.instagramPage!,
                    onTap: () {
                  final url = _normalizeSocialUrl(shop.instagramPage!,
                      baseUrl: 'https://www.instagram.com/');
                  if (url != null) {
                    _launchUrl(url);
                    ShopAnalyticsService().recordContact(widget.shopId);
                  }
                }),
              if (shop.lineId != null && shop.lineId!.isNotEmpty)
                _contactRow(Icons.chat_outlined,
                    '${'line_id_label'.tr(context)}: ${shop.lineId}',
                    onTap: () {
                  _launchUrl(_normalizeLineUrl(shop.lineId!));
                  ShopAnalyticsService().recordContact(widget.shopId);
                }),
              if (shop.otherContacts != null &&
                  shop.otherContacts!.isNotEmpty)
                _contactRow(Icons.contact_phone_outlined,
                    shop.otherContacts!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use a softer link color in dark mode — Material blue is harsh
    // on a #1E1E1E surface and was the QA's "blue link still bright
    // in dark mode" complaint.
    final linkColor = onTap == null
        ? theme.colorScheme.onSurface
        : (isDark ? const Color(0xFF82B5FF) : Colors.blue.shade700);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: linkColor,
                  decoration:
                      onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUSINESS INFO
  // ===========================================================================

  Widget _buildBusinessInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('business_information'.tr(context)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_sectionRadius),
          ),
          child: Column(
            children: [
              _infoRow(
                  'price_range'.tr(context), _shop!.priceRange.toString()),
              _infoRow(
                'duration'.tr(context),
                _shop!.durationMinutes > 0
                    ? '${_shop!.durationMinutes} ${'minutes_label'.tr(context)}'
                    : 'no_information'.tr(context),
              ),
              _infoRow(
                'try_on_area'.tr(context),
                _shop!.tryOnAreaAvailable == true
                    ? 'available'.tr(context)
                    : (_shop!.tryOnAreaAvailable == false
                        ? 'not_available'.tr(context)
                        : 'no_information'.tr(context)),
              ),
              _infoRow(
                'purchase_required'.tr(context),
                _shop!.requiresPurchase == true
                    ? 'yes_label'.tr(context)
                    : (_shop!.requiresPurchase == false
                        ? 'no_label'.tr(context)
                        : 'no_information'.tr(context)),
              ),
              if (_shop!.landmark != null && _shop!.landmark!.isNotEmpty)
                _infoRow('landmark'.tr(context), _shop!.landmark!),
              if (_shop!.notesOrConditions != null &&
                  _shop!.notesOrConditions!.isNotEmpty)
                _infoRow('notes'.tr(context), _shop!.notesOrConditions!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    final isNoInfo = value == 'no_information'.tr(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isNoInfo ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                fontStyle: isNoInfo ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAYMENT METHODS
  // ===========================================================================

  Widget _buildPaymentMethodsSection() {
    final paymentMethods = _shop!.paymentMethods ?? [];
    if (paymentMethods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('payment_methods'.tr(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: paymentMethods.map((method) {
            IconData icon;
            switch (method.toLowerCase()) {
              case 'cash':
                icon = Icons.money;
                break;
              case 'card':
                icon = Icons.credit_card;
                break;
              case 'qr':
                icon = Icons.qr_code;
                break;
              case 'bank_transfer':
                icon = Icons.account_balance;
                break;
              default:
                icon = Icons.payment;
            }
            final isDark =
                Theme.of(context).brightness == Brightness.dark;
            final chipBg = isDark
                ? Colors.blue.withValues(alpha: 0.18)
                : Colors.blue.shade50;
            final chipBorder = isDark
                ? Colors.blue.withValues(alpha: 0.32)
                : Colors.blue.shade100;
            final chipFg = isDark
                ? const Color(0xFF82B5FF)
                : Colors.blue.shade700;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: chipBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: chipFg),
                  const SizedBox(width: 6),
                  Text(
                    _localizePayment(method),
                    style: TextStyle(
                      fontSize: 12,
                      color: chipFg,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // FEATURES / AMENITIES
  // ===========================================================================

  Widget _buildFeaturesSection() {
    final features = _shop!.features;
    final amenities = _shop!.amenities;

    if (features.isEmpty && amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('features_amenities'.tr(context)),
        const SizedBox(height: 12),
        if (amenities.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: amenities.map((amenity) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _localizeAmenity(amenity),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (features.isNotEmpty) const SizedBox(height: 16),
        ],
        if (features.isNotEmpty)
          ...features.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    entry.value ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: entry.value ? Colors.green : Colors.red.shade300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localizeFeature(entry.key),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        decoration:
                            entry.value ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // REVIEWS SECTION
  // ===========================================================================

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                '${'reviews_label'.tr(context)} (${_shop!.reviewCount})',
              ),
            ),
            if (_isLoggedIn)
              TextButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text('write_review'.tr(context),
                    style: const TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingReviews)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(_sectionRadius),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    size: 24,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'no_reviews_yet'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'be_first_to_review'.tr(context),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _isLoggedIn
                        ? _showAddReviewDialog
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      _isLoggedIn
                          ? 'write_first_review'.tr(context)
                          : 'login_to_review'.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ..._reviews
                  .take(5)
                  .map((review) => KeyedSubtree(
                        key: ValueKey(review.id),
                        child: _buildReviewCard(review),
                      )),
              if (_reviews.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => _showAllReviewsDialog(),
                    child: Text(
                      'show_all_reviews'.tr(context),
                      style: TextStyle(color: AppConstants.primaryColor),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnReview =
        currentUser != null && review.userId == currentUser.uid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar, name, date
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName
                      : 'anonymous'.tr(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style:
                    TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stars
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 16,
                color: i < review.rating ? _starColor : theme.dividerColor,
              );
            }),
          ),
          const SizedBox(height: 8),
          // Comment
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          // Action row: Reply (always) + Delete (own reviews only).
          // Buttons use full default tap targets with a top divider so they
          // are visually obvious — tester reported the previous compact
          // buttons appeared as "nothing happens when clicking the review".
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showReplyDialog(review),
                    icon: Icon(
                      Icons.reply_rounded,
                      size: 18,
                      color: AppConstants.primaryColor,
                    ),
                    label: Text(
                      'reply'.tr(context),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (isOwnReview) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          _showDeleteReviewConfirmation(review),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade400,
                      ),
                      label: Text(
                        'delete'.tr(context),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Replies
          if (review.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: review.replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          child: Text(
                            reply.userName.isNotEmpty
                                ? reply.userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reply.userName.isNotEmpty
                                    ? reply.userName
                                    : 'anonymous'.tr(context),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              Text(
                                reply.comment,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllReviewsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('reviews_label'.tr(context)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _reviews.length,
            itemBuilder: (context, index) =>
                _buildReviewCard(_reviews[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr(context)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOCATION / MAP SECTION
  // ===========================================================================

  Widget _buildLocationSection({double desktopMapHeight = _mapHeight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('location_label'.tr(context)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(_sectionRadius),
          child: SizedBox(
            height: desktopMapHeight,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_shop!.latitude, _shop!.longitude),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: {
                Marker(
                  markerId: MarkerId(_shop!.id),
                  position: LatLng(_shop!.latitude, _shop!.longitude),
                  infoWindow: InfoWindow(
                    title: _shop!.name,
                    snippet: _shop!.address,
                  ),
                ),
              },
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openDirections,
            icon: Icon(Icons.directions_outlined,
                size: 18, color: AppConstants.primaryColor),
            label: Text(
              'directions'.tr(context),
              style: TextStyle(color: AppConstants.primaryColor),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM BAR (mobile only)
  // ===========================================================================

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Directions button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openDirections,
                icon: Icon(Icons.directions_outlined,
                    color: AppConstants.primaryColor, size: 20),
                label: Text(
                  'directions'.tr(context),
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppConstants.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_shop?.phoneNumber != null &&
                _shop!.phoneNumber!.isNotEmpty) ...[
              const SizedBox(width: 8),
              _bottomBarIcon(
                icon: Icons.phone_outlined,
                onTap: () {
                  _launchUrl('tel:${_shop!.phoneNumber}');
                  ShopAnalyticsService().recordContact(widget.shopId);
                },
              ),
            ],
            const SizedBox(width: 8),
            // Save button with bounce animation on toggle
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                tooltip: _isSaved
                    ? 'saved'.tr(context)
                    : 'save_shop'.tr(context),
                onPressed: _toggleSaved,
                icon: AnimatedBookmark(
                  isActive: _isSaved,
                  activeColor: _starColor,
                  inactiveColor: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
            if (_isLoggedIn) ...[
              const SizedBox(width: 8),
              _bottomBarIcon(
                icon: Icons.build_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LogRepairScreen(shop: _shop!)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomBarIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon,
            color: color ?? theme.colorScheme.onSurfaceVariant, size: 22),
      ),
    );
  }

  // ===========================================================================
  // SHARED UI HELPERS
  // ===========================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool light = false,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: light
          ? Colors.black.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: iconColor ??
                (light ? Colors.white : theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _outlinedChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
    Color? color,
  }) {
    final chipColor = color ?? AppConstants.primaryColor;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: filled ? Colors.white : chipColor,
        backgroundColor: filled ? chipColor : null,
        side: BorderSide(color: chipColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
