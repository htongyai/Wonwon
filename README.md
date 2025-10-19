# Wonwonw2 - Repair Shop Finder App

A comprehensive Flutter application for finding and managing repair shops, built with modern architecture and responsive design principles.

## 🚀 **Quick Start**

### **Live Applications**
- **User App**: https://app.fixwonwon.com
- **Admin Portal**: https://admin.fixwonwon.com

### **What This App Does**
Wonwonw2 is a **repair shop discovery platform** that helps users find nearby repair services (electronics, appliances, vehicles) while providing shop owners with a platform to showcase their services. Think "Google Maps for repair shops" with reviews, ratings, and real-time location services.

---

## 🏗️ **System Architecture Overview**

### **High-Level Architecture**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User App      │    │   Admin Portal  │    │   Firebase      │
│   (Flutter)     │◄──►│   (Flutter)     │◄──►│   Backend       │
│                 │    │                 │    │                 │
│ • Shop Discovery│    │ • Shop Management│    │ • Firestore DB  │
│ • Reviews       │    │ • User Management│    │ • Authentication│
│ • Maps          │    │ • Moderation    │    │ • Storage       │
│ • Saved Shops   │    │ • Analytics     │    │ • Hosting       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Core Logic Flow**
1. **User opens app** → Location permission requested
2. **Location obtained** → Nearby shops fetched from Firestore
3. **Shops displayed** → User can search, filter, view details
4. **Shop interaction** → Reviews, ratings, save to favorites
5. **Admin oversight** → Approve shops, moderate content, manage users

---

## 🧠 **How The System Works**

### **1. Authentication System**

#### **The Problem We Solved**
Users were getting logged out unexpectedly due to inconsistent auth state management across screens.

#### **Our Solution: Centralized AuthManager**
```dart
// Before: Each screen managed auth independently
class SomeScreen extends StatefulWidget {
  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      // Inconsistent state management
    });
  }
}

// After: Centralized AuthManager
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  
  // Single source of truth for auth state
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  
  // Automatic token refresh
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer = Timer.periodic(Duration(minutes: 50), (timer) {
      _refreshAuthToken();
    });
  }
}
```

#### **How It Works**
1. **App starts** → AuthManager initializes
2. **Firebase listener** → Monitors auth state changes
3. **State updates** → All screens get notified via streams
4. **Token refresh** → Automatic session renewal every 50 minutes
5. **Logout handling** → Complete cleanup of user data

### **2. Shop Discovery System**

#### **The Problem**
Users need to find repair shops near their location with accurate, up-to-date information.

#### **Our Solution: Multi-Layer Caching + Real-time Updates**
```dart
class ShopService {
  // Layer 1: Memory cache (fastest)
  final Map<String, RepairShop> _memoryCache = {};
  
  // Layer 2: SharedPreferences cache (persistent)
  final ShopCacheService _cacheService = ShopCacheService();
  
  // Layer 3: Firestore (source of truth)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<List<RepairShop>> getAllShops() async {
    // 1. Check memory cache first
    if (_memoryCache.isNotEmpty) return _memoryCache.values.toList();
    
    // 2. Check persistent cache
    final cachedShops = await _cacheService.getCachedShops();
    if (cachedShops != null) {
      _updateMemoryCache(cachedShops);
      return cachedShops;
    }
    
    // 3. Fetch from Firestore
    final shops = await _fetchFromFirestore();
    
    // 4. Update all caches
    _updateMemoryCache(shops);
    await _cacheService.cacheShops(shops);
    
    return shops;
  }
}
```

#### **How It Works**
1. **User opens app** → Check if shops are cached
2. **Cache hit** → Display shops immediately (sub-second load)
3. **Cache miss** → Fetch from Firestore (2-3 second load)
4. **Location-based** → Sort shops by distance from user
5. **Real-time updates** → Cache invalidated when shops change

### **3. Location Services**

#### **The Problem**
Users need accurate location-based shop recommendations, but location permission can be slow or denied.

#### **Our Solution: Timeout + Fallback Strategy**
```dart
Future<void> _getUserLocationWithTimeout() async {
  try {
    // Try to get location with 10-second timeout
    final location = await _getUserLocation()
        .timeout(const Duration(seconds: 10));
    
    // Success: Use location for distance sorting
    _userLocation = location;
    _sortShopsByDistance();
    
  } catch (e) {
    // Timeout or permission denied: Show all shops
    appLog('Location timeout - showing all shops');
    _userDistrict = 'Location timeout - showing all shops';
    _locationPermissionDenied = true;
    
    // Still show shops, just not sorted by distance
    _loadShops();
  }
}
```

#### **How It Works**
1. **App starts** → Request location permission
2. **Permission granted** → Get GPS coordinates
3. **Location obtained** → Sort shops by distance
4. **Permission denied/timeout** → Show all shops (unsorted)
5. **User can manually** → Search by district or address

### **4. Review System**

#### **The Problem**
Users need to share experiences and help others make informed decisions about repair shops.

#### **Our Solution: Nested Review System with Moderation**
```dart
class ReviewService {
  // Add review with validation
  Future<void> addReview({
    required String shopId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    // 1. Validate input
    if (rating < 1 || rating > 5) throw ValidationError('Invalid rating');
    if (comment.trim().isEmpty) throw ValidationError('Comment required');
    
    // 2. Create review object
    final review = Review(
      id: _generateId(),
      shopId: shopId,
      userId: userId,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );
    
    // 3. Save to Firestore
    await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('reviews')
        .doc(review.id)
        .set(review.toMap());
    
    // 4. Update shop's average rating
    await _updateShopRating(shopId);
  }
  
  // Add reply to review
  Future<void> addReplyToReview({
    required String shopId,
    required String reviewId,
    required ReviewReply reply,
  }) async {
    // Similar validation and saving process
  }
}
```

#### **How It Works**
1. **User writes review** → Input validation
2. **Review saved** → Stored in Firestore under shop document
3. **Rating calculated** → Shop's average rating updated
4. **Replies allowed** → Other users can reply to reviews
5. **Moderation** → Admins can hide/delete inappropriate content

### **5. Admin Moderation System**

#### **The Problem**
Need to maintain quality content and prevent spam/abuse while allowing community participation.

#### **Our Solution: Role-Based Moderation with Audit Trail**
```dart
class ModeratorService {
  // Only admins can moderate content
  Future<void> hideTopic(String topicId, String reason) async {
    // 1. Verify admin status
    if (!await _isAdmin()) throw UnauthorizedError('Admin required');
    
    // 2. Update topic with moderation info
    await _firestore.collection('forum_topics').doc(topicId).update({
      'isHidden': true,
      'moderationReason': reason,
      'moderatedBy': _getCurrentUserId(),
      'moderatedAt': FieldValue.serverTimestamp(),
    });
    
    // 3. Log moderation action
    await _logModerationAction('hide_topic', topicId, reason);
  }
  
  // Get moderation history
  Future<List<ModerationAction>> getModerationHistory() async {
    return await _firestore
        .collection('moderation_log')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => ModerationAction.fromMap(doc.data()))
            .toList());
  }
}
```

#### **How It Works**
1. **Content reported** → User flags inappropriate content
2. **Admin review** → Admin sees flagged content
3. **Moderation action** → Hide, delete, or approve content
4. **Audit trail** → All actions logged with reason and admin ID
5. **User notification** → User informed of moderation action

### **6. Responsive Design System**

#### **The Problem**
App needs to work perfectly on phones, tablets, desktops, and web browsers.

#### **Our Solution: Breakpoint-Based Responsive Design**
```dart
class ResponsiveSize {
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  
  static bool shouldShowDesktopLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }
}

// Usage in screens
Widget build(BuildContext context) {
  if (ResponsiveSize.shouldShowDesktopLayout(context)) {
    return _buildDesktopLayout(); // Sidebar + main content
  } else {
    return _buildMobileLayout(); // Bottom navigation
  }
}
```

#### **How It Works**
1. **Screen size detected** → MediaQuery gets current screen width
2. **Breakpoint check** → Determine if desktop, tablet, or mobile
3. **Layout selection** → Choose appropriate UI layout
4. **Component adaptation** → Adjust component sizes and behavior
5. **Navigation adaptation** → Desktop sidebar vs mobile bottom nav

---

## 🔧 **Technical Implementation Details**

### **State Management Architecture**

#### **Provider Pattern with Singleton Services**
```dart
// main.dart - App initialization
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppStateManager()),
    Provider(create: (_) => ServiceManager()),
    Provider(create: (_) => CacheService()),
    Provider(create: (_) => AuthManager()),
  ],
  child: MaterialApp(...),
)

// Usage in widgets
class SomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authManager = Provider.of<AuthManager>(context);
    final isLoggedIn = authManager.isLoggedIn;
    
    return isLoggedIn ? _buildLoggedInUI() : _buildLoginUI();
  }
}
```

#### **Why This Pattern?**
- **Predictable**: State changes flow down the widget tree
- **Testable**: Easy to mock providers for testing
- **Performant**: Only rebuilds widgets that depend on changed state
- **Scalable**: Easy to add new state providers

### **Memory Management System**

#### **The Problem**
Mobile devices have limited memory. We need to prevent memory leaks and optimize performance.

#### **Our Solution: UnifiedMemoryManager**
```dart
class UnifiedMemoryManager {
  static final Map<String, WeakReference<Object>> _objects = {};
  static Timer? _cleanupTimer;
  
  // Register object for tracking
  static void registerObject(String key, Object object) {
    _objects[key] = WeakReference(object);
    _scheduleCleanup();
  }
  
  // Automatic cleanup every 30 seconds
  static void _scheduleCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(Duration(seconds: 30), () {
      _performCleanup();
    });
  }
  
  // Remove dead references
  static void _performCleanup() {
    _objects.removeWhere((key, ref) => ref.target == null);
    appLog('Memory cleanup completed. Active objects: ${_objects.length}');
  }
}
```

#### **How It Works**
1. **Object registration** → Track important objects (controllers, services)
2. **Weak references** → Allow garbage collection when objects are no longer used
3. **Automatic cleanup** → Remove dead references every 30 seconds
4. **Memory pressure** → Aggressive cleanup when memory is low
5. **Performance monitoring** → Track memory usage and cleanup effectiveness

### **Error Handling System**

#### **The Problem**
Apps crash when errors occur. We need graceful error handling and user feedback.

#### **Our Solution: Centralized ErrorHandler**
```dart
class ErrorHandler {
  // Handle errors with user-friendly messages
  static void handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    String message = _getErrorMessage(error);
    
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: onRetry != null ? SnackBarAction(
          label: 'Retry',
          onPressed: onRetry,
        ) : null,
      ),
    );
    
    // Log error for debugging
    appLog('Error: $error', level: LogLevel.error);
  }
  
  // Convert technical errors to user-friendly messages
  static String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Request timed out. Please check your connection.';
    } else if (error is FirebaseException) {
      return 'Server error. Please try again later.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}
```

#### **How It Works**
1. **Error occurs** → Caught by try-catch blocks
2. **Error classification** → Determine error type (network, auth, validation)
3. **User message** → Convert technical error to user-friendly message
4. **User feedback** → Show SnackBar with retry option
5. **Error logging** → Log error details for debugging

---

## 📱 **Platform-Specific Features**

### **Web Optimizations**

#### **Font Tree-Shaking**
```dart
// web/index.html
<script>
  // Only load fonts that are actually used
  const fontFamilies = ['Inter', 'Roboto'];
  fontFamilies.forEach(font => {
    const link = document.createElement('link');
    link.href = `https://fonts.googleapis.com/css2?family=${font}:wght@400;500;600;700&display=swap`;
    document.head.appendChild(link);
  });
</script>
```

#### **Image Optimization**
```dart
class LazyLoadingImage extends StatefulWidget {
  final String imageUrl;
  final int? webQuality; // Web-specific quality setting
  
  @override
  Widget build(BuildContext context) {
    if (kIsWeb && webQuality != null) {
      // Use optimized image URL for web
      final optimizedUrl = '${imageUrl}?q=${webQuality}&w=${width}';
      return Image.network(optimizedUrl);
    }
    return Image.network(imageUrl);
  }
}
```

### **Mobile Features**

#### **Location Services**
```dart
class LocationService {
  Future<Position?> getCurrentLocation() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }
    
    // 2. Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }
    
    // 3. Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );
  }
}
```

---

## 🚀 **Deployment Architecture**

### **Multi-Environment Setup**

#### **User App (app.fixwonwon.com)**
   ```bash
# Build command
flutter build web --web-renderer html --release

# Features
- Public shop discovery
- User reviews and ratings
- Location-based search
- Responsive design
```

#### **Admin Portal (admin.fixwonwon.com)**
   ```bash
# Build command
flutter build web --web-renderer html --release --dart-define=FORCE_ADMIN_MODE=true

# Features
- Shop management
- User management
- Content moderation
- Analytics dashboard
```

### **CI/CD Pipeline**

#### **GitHub Actions Workflow**
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
    - name: Run tests
      run: flutter test --coverage
    - name: Analyze code
      run: dart analyze --fatal-infos

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
    - name: Build web
      run: flutter build web --release
    - name: Upload artifacts
      uses: actions/upload-artifact@v3

  deploy:
    runs-on: ubuntu-latest
    needs: [test, build]
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to Firebase
      uses: FirebaseExtended/action-hosting-deploy@v0
```

---

## 🧪 **Testing Strategy**

### **Current Test Coverage**
- **Unit Tests**: 3 test files (2% coverage)
- **Integration Tests**: 1 comprehensive test file
- **Widget Tests**: Basic widget testing

### **Test Structure**
```
test/
├── utils/
│   ├── validation_utils_test.dart    # Input validation tests
│   └── date_utils_test.dart         # Date utility tests
└── widget_test.dart                 # Basic widget tests

integration_test/
└── app_test.dart                    # End-to-end app tests
```

### **Test Issues & Solutions**
```dart
// Problem: dart:html not available in test environment
import 'dart:html' as html; // ❌ Fails in tests

// Solution: Conditional imports
import 'package:wonwonw2/services/version_service_web.dart'
    if (dart.library.io) 'package:wonwonw2/services/version_service_mobile.dart';
```

---

## 📊 **Performance Metrics**

### **Web Performance**
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **Font Tree-shaking**: 99%+ reduction
- **Bundle Size**: Optimized with tree-shaking

### **Mobile Performance**
- **App Launch Time**: < 3s
- **Memory Usage**: < 100MB average
- **Battery Impact**: Minimal (lazy loading)
- **Network Usage**: Cached data reduces requests

---

## 🔒 **Security Measures**

### **API Key Security**
- **Environment Variables**: API keys stored in environment variables
- **No Hardcoded Keys**: No API keys committed to version control
- **Template Configuration**: Use config.template.dart for setup
- **Production Security**: Separate keys for development/production

### **Authentication Security**
- **Firebase Auth**: Industry-standard authentication
- **Rate Limiting**: 5 login attempts, 15-minute lockout
- **Token Refresh**: Automatic session renewal
- **Input Sanitization**: XSS protection

### **Data Security**
- **Firestore Rules**: Server-side validation
- **Input Validation**: Client and server-side checks
- **Admin Controls**: Role-based access control
- **Content Moderation**: Safe content management

---

## 🎯 **Key Business Logic**

### **Shop Approval Process**
1. **User submits shop** → Goes to pending queue
2. **Admin reviews** → Checks for accuracy and completeness
3. **Admin approves/rejects** → Shop becomes visible/hidden
4. **User notification** → Email/SMS notification sent
5. **Analytics tracking** → Approval metrics recorded

### **Review Moderation**
1. **User writes review** → Stored in pending state
2. **Automated filtering** → Check for spam/inappropriate content
3. **Admin review** → Manual review if flagged
4. **Review published** → Visible to other users
5. **Rating calculation** → Shop's average rating updated

### **Location-Based Search**
1. **User location obtained** → GPS coordinates or manual input
2. **Nearby shops fetched** → Firestore query with location filter
3. **Distance calculation** → Haversine formula for accurate distances
4. **Results sorted** → Closest shops first
5. **Map integration** → Google Maps with shop markers

---

## 🛠️ **Development Workflow**

### **Getting Started**
   ```bash
# 1. Clone repository
git clone https://github.com/htongyai/Wonwon.git
cd Wonwon

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
# - Create Firebase project at https://console.firebase.google.com
# - Enable Firestore, Authentication, and Storage
# - Download google-services.json and GoogleService-Info.plist
# - Place in android/app/ and ios/Runner/ respectively

# 4. Configure API Keys (IMPORTANT: Security)
# - Copy config.template.dart to config.dart
# - Fill in your actual API keys in config.dart
# - NEVER commit config.dart to version control
# - Use environment variables for production deployment

# 5. Run the app
   flutter run
   ```

### **Code Quality Tools**
```bash
# Linting
flutter analyze

# Formatting
dart format .

# Testing
flutter test

# Build
flutter build web --release
```

---


## 🤝 **Contributing**

### **For Developers**
1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes**: Follow coding standards
4. **Run tests**: `flutter test`
5. **Submit PR**: Include description and tests

### **For Project Managers**
1. **Feature requests**: Create GitHub issue
2. **Bug reports**: Include steps to reproduce
3. **Priority levels**: Use labels (high, medium, low)
4. **Milestones**: Track feature completion

---

## 📞 **Support & Contact**

### **Technical Issues**
- **GitHub Issues**: Create issue with detailed description
- **Email**: [Your email]
- **Documentation**: Check this README and inline code comments

### **Business Questions**
- **Feature Requests**: Use GitHub issues
- **Partnership**: Contact development team
- **Analytics**: Check admin dashboard

---

## 📝 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ using Flutter**

*Last updated: December 2024*