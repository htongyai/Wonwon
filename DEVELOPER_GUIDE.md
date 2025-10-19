# 👨‍💻 Wonwonw2 Developer Guide

## **Table of Contents**
1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Development Environment](#development-environment)
4. [Code Standards](#code-standards)
5. [Common Patterns](#common-patterns)
6. [Debugging Guide](#debugging-guide)
7. [Testing Guide](#testing-guide)
8. [Performance Optimization](#performance-optimization)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)

---

## **Getting Started**

### **Prerequisites**
- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **IDE**: VS Code or Android Studio
- **Firebase Account**: For backend services
- **Google Maps API Key**: For location services

### **Initial Setup**
```bash
# 1. Clone the repository
git clone https://github.com/htongyai/Wonwon.git
cd Wonwon

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
# - Create Firebase project at https://console.firebase.google.com
# - Enable Firestore, Authentication, and Storage
# - Download google-services.json (Android) and GoogleService-Info.plist (iOS)
# - Place them in android/app/ and ios/Runner/ respectively

# 4. Configure API Keys (SECURITY CRITICAL)
# - Copy config.template.dart to config.dart
# - Fill in your actual API keys in config.dart
# - NEVER commit config.dart to version control
# - Use environment variables for production:
#   flutter run --dart-define=FIREBASE_API_KEY=your_key
#   flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key

# 5. Run the app
flutter run
```

### **Environment Variables**
```bash
# For admin portal
flutter run --dart-define=FORCE_ADMIN_MODE=true

# For web deployment
flutter build web --web-renderer html --release
```

---

## **Project Structure**

### **Directory Layout**
```
lib/
├── constants/          # App constants and configuration
│   ├── app_colors.dart
│   ├── app_constants.dart
│   └── api_constants.dart
├── models/            # Data models and entities
│   ├── user.dart
│   ├── repair_shop.dart
│   ├── review.dart
│   └── forum_topic.dart
├── services/          # Business logic and API services
│   ├── auth_manager.dart
│   ├── shop_service.dart
│   ├── review_service.dart
│   └── forum_service.dart
├── screens/           # UI screens and pages
│   ├── auth/
│   ├── user/
│   ├── admin/
│   └── desktop/
├── widgets/           # Reusable UI components
│   ├── common/
│   └── custom_navigation_bar.dart
├── utils/             # Utility functions and helpers
│   ├── app_logger.dart
│   ├── validation_utils.dart
│   └── error_handler.dart
├── mixins/            # Reusable mixins
│   ├── auth_state_mixin.dart
│   └── widget_disposal_mixin.dart
└── main.dart          # App entry point
```

### **Key Files Explained**

#### **main.dart**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services
  await _initializeServices();
  
  runApp(OptimizedWonWonApp(initialLocale: Locale('en')));
}
```
**Purpose**: App entry point, initializes Firebase and services

#### **auth_manager.dart**
```dart
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  Stream<bool> get authStateStream => _authStateController.stream;
}
```
**Purpose**: Centralized authentication state management

#### **shop_service.dart**
```dart
class ShopService {
  Future<List<RepairShop>> getAllShops() async {
    // Multi-layer caching strategy
    if (_memoryCache.isNotEmpty) return _memoryCache.values.toList();
    
    final cachedShops = await _cacheService.getCachedShops();
    if (cachedShops != null) return cachedShops;
    
    return await _fetchFromFirestore();
  }
}
```
**Purpose**: Shop data management with caching

---

## **Development Environment**

### **IDE Configuration**

#### **VS Code Extensions**
```json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode"
  ]
}
```

#### **VS Code Settings**
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 120,
  "editor.formatOnSave": true,
  "editor.rulers": [120],
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true
}
```

### **Flutter Configuration**

#### **analysis_options.yaml**
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Error rules
    avoid_print: true
    avoid_unnecessary_containers: true
    prefer_const_constructors: true
    
    # Style rules
    always_specify_types: true
    prefer_single_quotes: true
    sort_constructors_first: true
    
    # Documentation rules
    public_member_api_docs: true
    package_api_docs: true
```

#### **pubspec.yaml Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.5
  
  # Firebase
  firebase_core: ^3.13.1
  firebase_auth: ^5.5.4
  cloud_firestore: ^5.6.8
  
  # UI
  google_maps_flutter: ^2.12.2
  geolocator: ^14.0.1
  
  # Utilities
  shared_preferences: ^2.2.2
  logger: ^2.5.0
```

---

## **Code Standards**

### **Naming Conventions**

#### **Files and Directories**
```dart
// Files: snake_case
user_service.dart
shop_detail_screen.dart
custom_navigation_bar.dart

// Directories: snake_case
screens/
├── auth/
├── user/
└── admin/
```

#### **Classes and Variables**
```dart
// Classes: PascalCase
class AuthManager { }
class ShopService { }
class CustomNavigationBar { }

// Variables and methods: camelCase
String userName = 'John Doe';
bool isLoggedIn = false;
Future<void> loadShops() async { }

// Constants: UPPER_SNAKE_CASE
static const String API_BASE_URL = 'https://api.example.com';
static const int MAX_RETRY_ATTEMPTS = 3;
```

#### **Private Members**
```dart
class ShopService {
  // Private fields: _camelCase
  final Map<String, RepairShop> _memoryCache = {};
  bool _isLoading = false;
  
  // Private methods: _camelCase
  Future<void> _updateMemoryCache(List<RepairShop> shops) async { }
  void _notifyListeners() { }
}
```

### **Code Organization**

#### **Class Structure**
```dart
class ExampleService {
  // 1. Static fields
  static const String _cacheKey = 'example_cache';
  
  // 2. Instance fields
  final Map<String, dynamic> _cache = {};
  bool _isInitialized = false;
  
  // 3. Constructor
  ExampleService._internal();
  factory ExampleService() => _instance;
  
  // 4. Getters
  bool get isInitialized => _isInitialized;
  
  // 5. Public methods
  Future<void> initialize() async { }
  Future<List<Data>> getData() async { }
  
  // 6. Private methods
  Future<void> _loadFromCache() async { }
  void _notifyListeners() { }
}
```

#### **Method Order**
```dart
class ExampleWidget extends StatelessWidget {
  // 1. Constructor
  const ExampleWidget({Key? key, required this.title}) : super(key: key);
  
  // 2. Fields
  final String title;
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // 4. Helper methods
  Widget _buildHeader() { }
  Widget _buildContent() { }
}
```

### **Documentation Standards**

#### **Class Documentation**
```dart
/// Service for managing shop data with multi-layer caching
/// 
/// This service provides methods for fetching, caching, and managing
/// repair shop data. It implements a three-layer caching strategy:
/// 1. Memory cache (fastest)
/// 2. Persistent cache (SharedPreferences)
/// 3. Firestore (source of truth)
/// 
/// Example:
/// ```dart
/// final shopService = ShopService();
/// final shops = await shopService.getAllShops();
/// ```
class ShopService {
  // Implementation
}
```

#### **Method Documentation**
```dart
/// Fetches all shops with caching and distance sorting
/// 
/// This method implements a multi-layer caching strategy:
/// 1. Check memory cache first
/// 2. Check persistent cache if memory miss
/// 3. Fetch from Firestore if both miss
/// 4. Update all caches with fresh data
/// 
/// Returns a list of [RepairShop] objects sorted by distance
/// from the user's current location.
/// 
/// Throws [NetworkException] if unable to fetch data from Firestore.
/// Throws [CacheException] if unable to read from cache.
Future<List<RepairShop>> getAllShops() async {
  // Implementation
}
```

---

## **Common Patterns**

### **1. Service Pattern**

#### **Singleton Service**
```dart
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();
  
  // Service implementation
}
```

#### **Service Registration**
```dart
// main.dart
void _initializeServices() {
  ServiceManager.register(AuthManager());
  ServiceManager.register(ShopService());
  ServiceManager.register(ReviewService());
}

// Usage
final authManager = ServiceManager.get<AuthManager>();
```

### **2. State Management Pattern**

#### **Provider Usage**
```dart
// In widget
class ShopListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (context, appState, child) {
        return ListView.builder(
          itemCount: appState.shops.length,
          itemBuilder: (context, index) {
            return ShopCard(shop: appState.shops[index]);
          },
        );
      },
    );
  }
}
```

#### **State Updates**
```dart
// In service
class ShopService {
  void updateShops(List<RepairShop> shops) {
    _appStateManager.updateShops(shops);
  }
}

// In state manager
class AppStateManager extends ChangeNotifier {
  void updateShops(List<RepairShop> shops) {
    _shops = shops;
    notifyListeners();
  }
}
```

### **3. Error Handling Pattern**

#### **Try-Catch with ErrorHandler**
```dart
Future<void> loadShops() async {
  try {
    _appStateManager.setLoading(true);
    final shops = await _shopService.getAllShops();
    _appStateManager.updateShops(shops);
  } catch (error) {
    ErrorHandler.handleError(
      context,
      error,
      onRetry: loadShops,
    );
  } finally {
    _appStateManager.setLoading(false);
  }
}
```

#### **Custom Error Classes**
```dart
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

// Usage
if (email.isEmpty) {
  throw ValidationException('Email is required');
}
```

### **4. Caching Pattern**

#### **Multi-Layer Cache**
```dart
class ShopService {
  Future<List<RepairShop>> getAllShops() async {
    // Layer 1: Memory cache
    if (_memoryCache.isNotEmpty) {
      return _memoryCache.values.toList();
    }
    
    // Layer 2: Persistent cache
    final cachedShops = await _cacheService.getCachedShops();
    if (cachedShops != null) {
      _updateMemoryCache(cachedShops);
      return cachedShops;
    }
    
    // Layer 3: Firestore
    final shops = await _fetchFromFirestore();
    _updateMemoryCache(shops);
    await _cacheService.cacheShops(shops);
    
    return shops;
  }
}
```

### **5. Responsive Design Pattern**

#### **Breakpoint System**
```dart
class ResponsiveSize {
  static bool shouldShowDesktopLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1024 && width < 1200;
  }
}

// Usage
Widget build(BuildContext context) {
  if (ResponsiveSize.shouldShowDesktopLayout(context)) {
    return _buildDesktopLayout();
  } else {
    return _buildMobileLayout();
  }
}
```

---

## **Debugging Guide**

### **Logging System**

#### **AppLogger Usage**
```dart
import 'package:wonwonw2/utils/app_logger.dart';

// Basic logging
appLog('User logged in successfully');
appLog('Loading shops from cache', level: LogLevel.info);
appLog('Network error occurred', level: LogLevel.error);

// Debug logging (only in debug mode)
if (kDebugMode) {
  appLog('Debug info: ${object.toString()}');
}
```

#### **Log Levels**
```dart
enum LogLevel {
  debug,    // Detailed debug information
  info,     // General information
  warning,  // Warning messages
  error,    // Error messages
  fatal,    // Fatal errors
}
```

### **Performance Debugging**

#### **Performance Monitoring**
```dart
// Start timing
PerformanceUtils.startMeasurement('shop_loading');

// Do work
final shops = await shopService.getAllShops();

// End timing
final duration = PerformanceUtils.endMeasurement('shop_loading');
// Logs: "Performance: shop_loading took 150ms"
```

#### **Memory Debugging**
```dart
// Register objects for tracking
UnifiedMemoryManager.registerObject('shop_controller', controller);

// Check memory stats
final stats = UnifiedMemoryManager.getStats();
appLog('Memory stats: $stats');
```

### **Common Debug Scenarios**

#### **1. Authentication Issues**
```dart
// Check auth state
final authManager = AuthManager();
appLog('Is logged in: ${authManager.isLoggedIn}');
appLog('Current user: ${authManager.currentUser?.uid}');

// Listen to auth changes
authManager.authStateStream.listen((isLoggedIn) {
  appLog('Auth state changed: $isLoggedIn');
});
```

#### **2. Network Issues**
```dart
// Check network connectivity
final connectivity = await Connectivity().checkConnectivity();
appLog('Network status: $connectivity');

// Check Firebase connection
try {
  await FirebaseFirestore.instance.enableNetwork();
  appLog('Firebase connected');
} catch (e) {
  appLog('Firebase connection failed: $e');
}
```

#### **3. Cache Issues**
```dart
// Check cache status
final cacheStats = ShopCacheService.getCacheStats();
appLog('Cache stats: $cacheStats');

// Clear cache if needed
await ShopCacheService.clearCache();
appLog('Cache cleared');
```

---

## **Testing Guide**

### **Unit Testing**

#### **Test Structure**
```dart
// test/services/shop_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wonwonw2/services/shop_service.dart';

void main() {
  group('ShopService', () {
    late ShopService shopService;
    
    setUp(() {
      shopService = ShopService();
    });
    
    test('should return cached shops when available', () async {
      // Arrange
      final expectedShops = [/* mock shops */];
      await shopService.cacheShops(expectedShops);
      
      // Act
      final result = await shopService.getAllShops();
      
      // Assert
      expect(result, equals(expectedShops));
    });
  });
}
```

#### **Mocking Services**
```dart
// test/mocks/mock_shop_service.dart
class MockShopService extends Mock implements ShopService {
  @override
  Future<List<RepairShop>> getAllShops() async {
    return [/* mock data */];
  }
}

// Usage in tests
void main() {
  test('should load shops on init', () async {
    final mockShopService = MockShopService();
    // Test implementation
  });
}
```

### **Widget Testing**

#### **Basic Widget Test**
```dart
// test/widgets/shop_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonwonw2/widgets/shop_card.dart';

void main() {
  testWidgets('ShopCard displays shop information', (tester) async {
    // Arrange
    final shop = RepairShop(
      id: '1',
      name: 'Test Shop',
      address: '123 Test St',
    );
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: ShopCard(shop: shop),
      ),
    );
    
    // Assert
    expect(find.text('Test Shop'), findsOneWidget);
    expect(find.text('123 Test St'), findsOneWidget);
  });
}
```

#### **Testing User Interactions**
```dart
testWidgets('ShopCard calls onTap when tapped', (tester) async {
  bool wasTapped = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: ShopCard(
        shop: shop,
        onTap: () => wasTapped = true,
      ),
    ),
  );
  
  await tester.tap(find.byType(ShopCard));
  await tester.pump();
  
  expect(wasTapped, isTrue);
});
```

### **Integration Testing**

#### **End-to-End Test**
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete user flow', (tester) async {
    // Start app
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Navigate to shop list
    await tester.tap(find.text('Shops'));
    await tester.pumpAndSettle();
    
    // Verify shops are loaded
    expect(find.byType(ShopCard), findsWidgets);
    
    // Tap on a shop
    await tester.tap(find.byType(ShopCard).first);
    await tester.pumpAndSettle();
    
    // Verify shop details are shown
    expect(find.text('Shop Details'), findsOneWidget);
  });
}
```

---

## **Performance Optimization**

### **Memory Management**

#### **Object Lifecycle Management**
```dart
class ShopDetailScreen extends StatefulWidget {
  @override
  _ShopDetailScreenState createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> 
    with WidgetDisposalMixin {
  
  @override
  void initState() {
    super.initState();
    // Register for cleanup
    registerForDisposal(_controller);
  }
  
  @override
  void dispose() {
    // Automatic cleanup via mixin
    super.dispose();
  }
}
```

#### **Image Optimization**
```dart
class LazyLoadingImage extends StatefulWidget {
  final String imageUrl;
  final int? webQuality;
  
  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return CircularProgressIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.error);
      },
    );
  }
}
```

### **Network Optimization**

#### **Request Debouncing**
```dart
class SearchService {
  Timer? _debounceTimer;
  
  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }
}
```

#### **Pagination**
```dart
class ShopService {
  Future<List<RepairShop>> getShops({
    int page = 0,
    int pageSize = 20,
  }) async {
    final startIndex = page * pageSize;
    final endIndex = startIndex + pageSize;
    
    return await _firestore
        .collection('shops')
        .orderBy('createdAt')
        .startAt([startIndex])
        .limit(pageSize)
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => RepairShop.fromMap(doc.data()))
            .toList());
  }
}
```

---

## **Troubleshooting**

### **Common Issues**

#### **1. Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check for dependency conflicts
flutter pub deps
```

#### **2. Firebase Issues**
```bash
# Check Firebase configuration
flutter doctor -v

# Verify Firebase setup
# Check google-services.json and GoogleService-Info.plist are in correct locations
```

#### **3. Platform-Specific Issues**

**Web Issues:**
```dart
// Use conditional imports for web-specific code
import 'package:wonwonw2/services/version_service_web.dart'
    if (dart.library.io) 'package:wonwonw2/services/version_service_mobile.dart';
```

**Android Issues:**
```xml
<!-- Check AndroidManifest.xml for permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**iOS Issues:**
```xml
<!-- Check Info.plist for permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby repair shops</string>
```

### **Debug Commands**

#### **Flutter Commands**
```bash
# Check Flutter installation
flutter doctor

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for different platforms
flutter build web --release
flutter build apk --release
flutter build ios --release
```

#### **Firebase Commands**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy to Firebase
firebase deploy

# Check Firebase status
firebase projects:list
```

---

## **Contributing**

### **Development Workflow**

#### **1. Fork and Clone**
```bash
git clone https://github.com/your-username/Wonwon.git
cd Wonwon
git remote add upstream https://github.com/htongyai/Wonwon.git
```

#### **2. Create Feature Branch**
```bash
git checkout -b feature/amazing-feature
```

#### **3. Make Changes**
- Follow code standards
- Add tests for new features
- Update documentation

#### **4. Test Changes**
```bash
flutter test
flutter analyze
flutter format .
```

#### **5. Commit Changes**
```bash
git add .
git commit -m "feat: add amazing feature"
git push origin feature/amazing-feature
```

#### **6. Create Pull Request**
- Provide clear description
- Include screenshots if UI changes
- Reference related issues

### **Code Review Process**

#### **Checklist for Reviewers**
- [ ] Code follows project standards
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No breaking changes
- [ ] Performance impact considered

#### **Checklist for Authors**
- [ ] Code is tested
- [ ] Documentation is updated
- [ ] No linting errors
- [ ] Performance is acceptable
- [ ] Security considerations addressed

---

## **Resources**

### **Documentation**
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Package](https://pub.dev/packages/provider)

### **Tools**
- [Flutter Inspector](https://flutter.dev/docs/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Firebase Console](https://console.firebase.google.com)

### **Community**
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Issues](https://github.com/htongyai/Wonwon/issues)

---

**This developer guide provides comprehensive information for developers working on the Wonwonw2 project. It covers everything from setup to advanced debugging techniques, ensuring consistent development practices across the team.**
