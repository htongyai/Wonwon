# WonWon Repair Finder

A modern, user-friendly mobile application for finding and connecting with repair services in your area.

## Features

### Core Functionality

#### 1. Map Integration
- **Google Maps Integration**: Real-time, interactive map showing repair shops nearby
- **Custom User Location Marker**: Green person-shaped marker showing your current position
- **Location Tracking**: Real-time updates of your location as you move
- **Location Permission Handling**: Intuitive permission requests with clear explanations
- **Loading Indicators**: Visual feedback when determining location
- **Map Controls**: Custom zoom controls and follow-user functionality
- **Map Settings**: Clean interface with unnecessary controls disabled

#### 2. Shop Discovery
- **Category Filtering**: Browse shops by repair type (Clothing, Footwear, Watches, Bags, Appliances, Electronics)
- **Search Functionality**: Find shops by name, service, or description
- **Recommended Shops**: Curated list of repair services
- **Sorting Options**: Sort by distance, rating, or relevance
- **Distance Calculation**: See how far shops are from your current location

#### 3. Shop Details
- **Comprehensive Information**: View hours, contact details, services, and ratings
- **Image Gallery**: See shop photos for better recognition
- **Opening Hours**: Clear display with current day highlighted
- **Contact Options**: Direct calling, messaging, and website links
- **Service Categories**: See what types of repairs each shop specializes in
- **Directions**: Get directions to shops via Google Maps
- **Save Feature**: Bookmark your favorite repair shops for quick access

#### 4. Reviews & Reporting
- **Rating System**: View aggregate ratings and individual reviews
- **Review Writing**: Submit your own reviews with star ratings
- **Anonymous Reviews**: Option to post anonymously
- **Reporting System**: Report incorrect information with categorized reasons
- **Report Categories**: Address, hours, closure status, contact info, services
- **Report Tracking**: Count of reports visible on shop detail pages

### UI/UX Features

#### 1. Modern Interface
- **Responsive Design**: Adapts to different screen sizes
- **Smooth Animations**: Polished transitions between screens and elements
- **Pull-to-Refresh**: Update shop data with intuitive gesture
- **Skeleton Loading**: Visual placeholders during data loading
- **Error Handling**: User-friendly error messages and recovery options

#### 2. Navigation
- **Intuitive Flow**: Logical progression between screens
- **Back Navigation**: Consistent return to previous screens
- **Bottom Navigation**: Quick access to main app sections
- **Custom Transitions**: Smooth navigation between related content

#### 3. Accessibility
- **Internationalization**: Full support for English and Thai languages
- **High Contrast Elements**: Clear visual hierarchy and readable text
- **Scalable Text**: Adapts to system font size settings
- **Alternative Text**: Descriptions for images and icons

### User Account Features

#### 1. Authentication
- **User Registration**: Create new accounts with email verification
- **Secure Login**: Password-protected access to personal data
- **Password Recovery**: Reset forgotten passwords via email
- **Persistent Sessions**: Stay logged in across app restarts

#### 2. User Profile
- **Saved Locations**: Access your bookmarked repair shops
- **Review Management**: Track and edit your submitted reviews
- **Settings Management**: Customize your app experience
- **Account Deletion**: Option to remove all personal data

### Technical Features

#### 1. Performance
- **Optimized Loading**: Efficient data fetching and caching
- **Lazy Loading**: Load content as needed for faster startup
- **Image Optimization**: Properly sized images for device screens

#### 2. Offline Capabilities
- **Data Caching**: Access previously loaded shop information offline
- **Sync Management**: Updates data when connection is restored

#### 3. Security
- **Data Protection**: Secure storage of user information
- **Input Validation**: Prevents malicious data submission
- **Secure API Communication**: Protected data transfer

## Technology Stack

- **Frontend**: Flutter for cross-platform mobile development
- **Maps**: Google Maps Flutter integration
- **State Management**: Provider pattern for efficient UI updates
- **Localization**: Flutter's built-in i18n system supporting multiple languages
- **Navigation**: Go Router for declarative navigation
- **UI Components**: Custom widgets built on Material Design principles

## Getting Started

### Prerequisites
- Flutter SDK (version 3.0+)
- Android Studio or Xcode
- Google Maps API key

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure your Google Maps API key in:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/AppDelegate.swift`
   - `web/index.html`
4. Run `flutter run` to start the app

## Contributing

We welcome contributions to the WonWon Repair Finder app! Please see our contributing guidelines for more information.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
