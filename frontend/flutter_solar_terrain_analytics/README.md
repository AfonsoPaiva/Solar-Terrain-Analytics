# Solar Terrain Analytics - Mobile App

Solar terrain analysis application for mobile devices, featuring the same powerful functionality as the web version but optimized for mobile UI.

## Features

### 🗺️ Interactive Map
- **Area Drawing**: Draw custom areas on the map for analysis
- **Point Selection**: Tap anywhere in Portugal for quick analysis
- **Heatmap Visualization**: Visual representation of solar potential
- **Saved Sites**: View previously analyzed locations

### 📊 Solar Analysis
- **Enhanced Analysis**: Comprehensive solar potential calculations
- **Weather Impact**: Monthly weather data analysis
- **Shading Analysis**: Advanced terrain shading calculations
- **Energy Estimates**: Annual energy production estimates

### 💾 Data Management
- **Save Analyses**: Store analysis results with custom names
- **Cloud Sync**: Firebase integration for data persistence
- **Export/Share**: Share analysis results

## Supported Platforms

- ✅ **Android**: Primary mobile platform
- ✅ **Web**: Browser-based version
- ❌ **iOS**: Removed (not supported)
- ❌ **Windows**: Removed (not supported)
- ❌ **Linux**: Removed (not supported)
- ❌ **macOS**: Removed (not supported)

## Mobile-Specific Features

### Navigation
- **3-Tab Layout**: Map, Analysis, Saved
- **Floating Action Buttons**: Context-sensitive actions
- **Mobile-Optimized UI**: Touch-friendly interface

### Drawing Mode
- **Visual Feedback**: Real-time drawing indicators
- **Vertex Numbering**: Clear point ordering
- **Completion Controls**: Easy area completion

### Analysis Display
- **Dedicated Tab**: Full-screen analysis results
- **Mobile Cards**: Information organized in mobile-friendly cards
- **Touch Navigation**: Swipe between sections

## Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Android SDK (for mobile development)
- Firebase project configured

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase (see firebase_options.dart)
4. Run `flutter run` for development

### Building
- **Debug APK**: `flutter build apk --debug`
- **Release APK**: `flutter build apk --release`
- **Web**: `flutter build web`

## Architecture

- **Frontend**: Flutter/Dart
- **Backend**: Spring Boot (Java)
- **Authentication**: Firebase Auth
- **Database**: Firebase Firestore
- **Maps**: OpenStreetMap with flutter_map
- **APIs**: Google Solar API, Google Maps Elevation API

## Development

The mobile app shares the same API and data models as the web version, ensuring consistency across platforms while providing an optimized mobile experience.
