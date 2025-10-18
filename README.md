# Wonwonw2 - Repair Shop Finder App

A comprehensive Flutter application for finding and managing repair shops, built with modern architecture and responsive design principles.

## 🚀 Features

### Core Functionality
- **Shop Discovery**: Find repair shops by location, services, and ratings
- **Interactive Maps**: Google Maps integration with location-based search
- **User Reviews**: Rate and review repair shops with reply functionality
- **Saved Locations**: Bookmark favorite repair shops
- **Multi-language Support**: English and Thai language support
- **Responsive Design**: Optimized for mobile, tablet, and desktop

### Admin Features
- **Shop Management**: Add, edit, approve, and manage repair shops
- **User Management**: Admin dashboard for user oversight
- **Content Moderation**: Forum moderation tools for admins
- **Analytics Dashboard**: Performance metrics and insights

### User Experience
- **Authentication**: Secure login/logout with Firebase Auth
- **Real-time Updates**: Live authentication state management
- **Offline Support**: Cached data for offline browsing
- **Performance Optimized**: Lazy loading and memory management

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.x
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Maps**: Google Maps Flutter
- **State Management**: Provider pattern
- **Architecture**: Clean Architecture with MVVM

### Project Structure
```
lib/
├── constants/          # App constants and configuration
├── models/            # Data models and entities
├── services/          # Business logic and API services
├── screens/           # UI screens and pages
├── widgets/           # Reusable UI components
├── utils/             # Utility functions and helpers
├── mixins/            # Reusable mixins
└── main.dart          # App entry point
```

### Key Services
- **AuthManager**: Centralized authentication management
- **ShopService**: Shop data management with caching
- **ReviewService**: Review and rating functionality
- **ForumService**: Community forum management
- **ModeratorService**: Content moderation tools
- **UnifiedMemoryManager**: Memory optimization
- **ErrorHandler**: Centralized error handling

## 🛠️ Installation

### Prerequisites
- Flutter SDK (3.x or higher)
- Dart SDK
- Firebase project setup
- Google Maps API key

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/htongyai/Wonwon.git
   cd Wonwon
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Enable Firestore, Authentication, and Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate platform directories

4. **Configure Google Maps**
   - Get a Google Maps API key
   - Add it to your platform configuration files

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Platform Support

- **Android**: API level 21+
- **iOS**: iOS 11.0+
- **Web**: Modern browsers
- **Desktop**: Windows, macOS, Linux

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Code Quality
```bash
flutter analyze
flutter format .
```

## 🚀 Deployment

### Web Deployment
```bash
flutter build web
# Deploy the build/web directory to your hosting service
```

### Mobile Deployment
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📊 Performance Features

- **Lazy Loading**: Images and content load on demand
- **Memory Management**: Automatic cleanup and optimization
- **Caching**: Smart caching for improved performance
- **Responsive Design**: Optimized for all screen sizes
- **Error Handling**: Graceful error recovery

## 🔧 Development

### Code Quality Tools
- **Linting**: Comprehensive linting rules
- **Formatting**: Automatic code formatting
- **Pre-commit Hooks**: Automated quality checks
- **CI/CD**: GitHub Actions for continuous integration

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Support

For support and questions:
- Create an issue on GitHub
- Contact the development team

## 🔄 Changelog

### Recent Updates
- ✅ Fixed critical authentication issues
- ✅ Implemented responsive design improvements
- ✅ Added comprehensive error handling
- ✅ Optimized performance and memory usage
- ✅ Enhanced code quality and testing

## 📈 Roadmap

- [ ] Advanced search filters
- [ ] Push notifications
- [ ] Offline mode improvements
- [ ] Social features
- [ ] Payment integration
- [ ] Advanced analytics

---

**Built with ❤️ using Flutter**