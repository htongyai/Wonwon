# WonWon Repair Finder

<p align="center">
  <img src="assets/images/wwg.png" alt="WonWon Logo" width="200"/>
</p>

## Overview

WonWon Repair Finder is a comprehensive mobile and web application designed to connect users with local repair services. The app provides a seamless experience for finding, evaluating, and contacting repair shops across various categories. With an intuitive interface and powerful features, users can easily locate the services they need when something breaks.

> ⚠️ **Important Note**: The current version does not include Firebase integration. All data is mock data, and backend functionality like authentication, real-time updates, and cloud storage will be implemented in future versions.

## 🌟 Flutter Web Support

### How to Run for Web

1. **Enable web support (if not already):**
   ```bash
   flutter config --enable-web
   ```
2. **Run in Chrome:**
   ```bash
   flutter run -d chrome
   ```
3. **Build for web:**
   ```bash
   flutter build web
   ```
   The output will be in the `build/web` directory.

### Web-Specific Notes
- All major features are supported on web, including localization, category filtering, shop details, and reviews.
- Responsive design ensures the app looks great on desktop and mobile browsers.
- Some plugins (e.g., Firebase, camera) may require additional setup for web compatibility.
- For Google Maps, ensure your API key is set in `web/index.html` as well as mobile manifests.

## 🏗️ Modern Architecture & Recent Improvements

- **SliverAppBar for Details Page:** The shop details page uses a `SliverAppBar` for the cover image, which scrolls up with the content for a modern, native feel.
- **Language Switch Loading Overlay:** When switching languages, a loading overlay is shown for 1 second for a smooth transition.
- **Responsive Design:** Uses `ResponsiveSize` utilities for consistent sizing across devices and browsers.
- **Dynamic Localization:** Instantly switch between English and Thai, with all UI elements updating live.
- **Category & Subservice System:** Categories and subservices are fully localized and filterable.
- **Lazy Loading Images:** Images are loaded only when visible for performance.
- **Settings Page:** Compact, modern, and responsive with language and account controls.
- **Shop List & Filtering:** Fast, interactive, and supports both list and map views.
- **Report System:** Users can report incorrect shop info, with a visible counter on the details page.

## 🌟 Key Features

### 📱 User Interface & Experience

#### Modern, Intuitive Design
- **Clean Visual Hierarchy**: Thoughtfully organized elements with proper spacing and visual cues
- **Responsive Layouts**: Adapts perfectly to different screen sizes and orientations
- **Consistent Styling**: Cohesive color scheme, typography, and component design
- **Dark Mode Support**: Coming in future updates

#### Animation & Interactivity
- **Fluid Transitions**: Smooth animations between screens and states
- **Loading States**: Visual feedback during data fetching operations
- **Interactive Elements**: Buttons, cards, and controls with state-based visual feedback
- **Pull-to-Refresh**: Update content with a natural gesture

#### Multilingual Support
- **English and Thai**: Complete localization for both languages
- **Extensible**: Infrastructure in place for adding more languages

### 🗺️ Map Integration

#### Google Maps Implementation
- **Interactive Map View**: Explore repair shops in a spatial context
- **Custom Location Marker**: Distinctive green person-shaped marker for user's location
- **Shop Markers**: Clearly identifiable markers for all nearby shops
- **Custom Controls**: Simplified interface with essential controls

#### Location Features
- **Real-time Location Tracking**: Updates user position as they move
- **Permission Management**: Clear permission requests with explanations
- **Location-based Search**: Find shops near your current location
- **Distance Calculation**: Shows distance between user and shops

### 🔍 Shop Discovery

#### Search & Filtering
- **Text Search**: Find shops by name, service type, or description
- **Category Filtering**: Browse by repair category (Clothing, Footwear, Watches, etc.)
- **Combined Filters**: Apply multiple filters simultaneously
- **Clear Filters**: Easily reset to default view

#### Browse Experience
- **Recommended Shops**: Curated list based on popularity and ratings
- **Category Exploration**: Visual category selection with intuitive icons
- **List View**: Scrollable list with comprehensive shop previews
- **Map View**: Alternative spatial exploration of options

### 📊 Shop Details

#### Comprehensive Information
- **Rich Shop Profiles**: Complete details including services, hours, and contact info
- **Photo Gallery**: Visual representation of the shop and its services
- **Service Categories**: Detailed breakdown of repair specialties
- **Operating Hours**: Clear schedule with current day highlighted
- **Location Details**: Address and area information with map preview

#### Interaction Options
- **Contact Methods**: Direct calling, messaging, and website links
- **Save Functionality**: Bookmark favorite shops for quick access
- **Directions**: Get navigation guidance to the shop
- **Share**: Send shop details to friends or contacts

### 🌟 Reviews & Community

#### Rating System
- **Aggregate Scores**: Overall rating displayed prominently
- **Review Count**: Number of reviews contributing to the rating
- **Detailed Reviews**: Individual reviews with ratings and comments
- **User Profiles**: Reviewer information with anonymity options

#### Reporting & Feedback
- **Issue Reporting**: Report incorrect information with categorized options
- **Feedback Categories**: Address, hours, closure status, contact, and services
- **Report Tracking**: Visual indication of reported issues
- **Resolution System**: Infrastructure for addressing reports

### 👤 User Accounts

#### Authentication
- **Registration**: Create accounts with email verification
- **Secure Login**: Password-protected access
- **Password Recovery**: Reset functionality via email
- **Session Management**: Remember login state

> ⚠️ **Note**: Currently using mock authentication. Firebase Authentication will be implemented in future versions.

#### User Profile
- **Saved Locations**: Access bookmarked repair shops
- **Review Management**: Track and edit submitted reviews
- **Settings Control**: Customize app experience
- **Privacy Options**: Control data sharing and visibility

## 📋 Usage Flow

### 1. First-time Setup
1. **Install the App**: Download and install from app store (future)
2. **Language Selection**: Choose preferred language (English/Thai)
3. **Location Permission**: Grant permission for location services
4. **Optional Registration**: Create account or skip for basic functionality

### 2. Finding a Repair Shop
1. **Home Screen**: View categories and recommended shops
2. **Search or Browse**: Enter search term or select repair category
3. **View Results**: Scroll through list of matching shops
4. **Map Alternative**: Toggle to map view to see spatial distribution
5. **Filter Results**: Apply additional filters as needed

### 3. Evaluating Options
1. **Quick Preview**: See basic info in shop cards (rating, categories, etc.)
2. **Detailed View**: Tap shop card to view complete details
3. **Check Reviews**: Read customer experiences and ratings
4. **Verify Services**: Confirm shop handles your specific repair need
5. **Check Hours**: Verify shop is open when needed

### 4. Taking Action
1. **Save for Later**: Bookmark shop for future reference
2. **Contact Shop**: Call, message, or visit website directly from app
3. **Get Directions**: Navigate to shop location using maps integration
4. **Write Review**: Share your experience after visiting (requires account)
5. **Report Issues**: Submit corrections if information is outdated or incorrect

## 🧩 Technical Architecture

### Frontend: Flutter Framework
- **Cross-platform**: Single codebase for iOS and Android
- **Widget-based UI**: Compositional approach to interface design
- **State Management**: Efficient UI updates with Provider pattern
- **Responsive Layout**: Adaptable to different screen sizes and orientations

### Maps Integration
- **Google Maps Flutter**: Native maps experience
- **Location Services**: Precise user positioning with permission handling
- **Custom Markers**: Branded and contextual map indicators
- **Interactive Elements**: Tap gestures and camera controls

### Localization System
- **Internationalization**: Full support for multiple languages
- **Translation Files**: JSON-based language definitions
- **Dynamic Locale**: Change language without app restart
- **Locale-aware Formatting**: Dates, times, and numbers formatted appropriately

### Data Management
- **Mock Data Service**: Simulated backend during development
- **Future Firebase Integration**: Planned implementation for production
- **Local Storage**: Persistence for offline capabilities and settings
- **Data Models**: Type-safe representations of business objects

## 🚫 Current Limitations

### Backend Integration
- **No Firebase**: Authentication, real-time database, and cloud storage not yet implemented
- **Mock Data**: All shop information is simulated for development
- **Local Storage Only**: User preferences stored on device only
- **No Cloud Sync**: User data not synchronized across devices

### Feature Roadmap
- **Backend Integration**: Connect to Firebase services
- **Real Shop Data**: Replace mock data with actual repair shop information
- **Advanced Search**: Enhanced filtering and sorting options
- **Appointment Booking**: Schedule repairs directly through the app
- **Shop Owner Portal**: Allow businesses to claim and manage their listings

## 🛠 Getting Started

### Prerequisites
- Flutter SDK (version 3.0+)
- Android Studio or Xcode
- Google Maps API key
- Git

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/htongyai/Wonwon.git
   cd Wonwon
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Maps API key**
   - Add your API key to:
      - `android/app/src/main/AndroidManifest.xml`
      - `ios/Runner/AppDelegate.swift`
      - `web/index.html`

4. **Run the app**
   ```bash
   flutter run
   ```

### Development Setup
- **Mock Data**: Review mock data structures in `lib/data/` directory
- **Localization**: Add translations in `assets/lang/` JSON files
- **Assets**: Add images and icons to `assets/images/` directory

## 📋 Contributing

We welcome contributions to the WonWon Repair Finder app! Please see our contributing guidelines for more information.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgements

- Google Maps Platform for mapping services
- Flutter team for the fantastic framework
- All contributors who have helped shape this project
