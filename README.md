<div align="center">

![Solar Terrain Analytics](https://i.postimg.cc/m2ZwH00K/Logo.png)

*A Modern Web & Mobile Platform for Solar Terrain Analysis and Site Management*

<!-- Frontend -->
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)
![Google Maps](https://img.shields.io/badge/Google_Maps-API-yellow.svg)
![Firebase](https://img.shields.io/badge/Firebase-Auth-orange.svg)

<!-- Backend -->
![Java](https://img.shields.io/badge/Java-17+-red.svg)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-green.svg)
![Maven](https://img.shields.io/badge/Maven-Build-blueviolet.svg)
![REST API](https://img.shields.io/badge/REST-API-lightgrey.svg)

<!-- General -->
![Cross Platform](https://img.shields.io/badge/Cross--Platform-Web%20%7C%20Android-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

</div>

## Features

### Interactive Solar Terrain Analysis
- Draw custom areas on a map to analyze solar potential
- Real-time shading and light intensity heatmaps
- Save, view, and manage analyzed sites
- Visualize and compare multiple terrains

### Multi-Platform Support
- Web dashboard (Flutter Web)
- Android APK (Flutter)
- Responsive UI for desktop and mobile

### Secure User Management
- Firebase Authentication (Google Sign-In)
- User-specific saved sites and data

### Advanced Backend Analytics
- Spring Boot REST API for solar and terrain analysis
- Polygon-based area calculations
- Integration with elevation and weather APIs
- CORS and security configuration for safe deployment

### Data Visualization
- Google Maps integration for area selection and display
- Custom heatmap overlays for solar intensity
- Saved sites list with quick view and delete options

## Technical Stack

| Component      | Technology         | Purpose                       |
|----------------|-------------------|-------------------------------|
| Frontend       | Flutter (Dart)    | Web & Mobile UI               |
| Maps           | Google Maps API   | Map display & area drawing    |
| Auth           | Firebase Auth     | User authentication           |
| Backend        | Spring Boot (Java)| REST API & analytics          |
| Data Storage   | (Pluggable)       | Saved sites, user data        |

## Installation

### Prerequisites
- [Flutter 3.x](https://flutter.dev/docs/get-started/install) (with Dart)
- [Java 17+](https://adoptopenjdk.net/) (for backend)
- [Node.js](https://nodejs.org/) (for Firebase CLI, optional)
- Google Maps API Key
- Firebase Project (for Auth)

### Dependencies Included
- All Flutter and backend dependencies are managed via `pubspec.yaml` and `pom.xml`.

### Build Instructions

#### Backend (Spring Boot)
1. Clone the repository
2. Configure your API keys and Firebase credentials in `backend/analytics-backend/src/main/resources/application-local.yml`
3. Run: cd backend/analytics-backend ./mvnw spring-boot:run

The backend will start on `http://localhost:8081` by default.

#### Frontend (Flutter)
1. Clone the repository
2. Configure your Firebase and Google Maps keys in `lib/firebase_options.dart` and `web/index.html`
3. Run for web: cd frontend/flutter_solar_terrain_analytics flutter run -d chrome

Or build APK for Android: flutter build apk


<div align="center">

## Demonstration

[![Watch Demo Video](https://img.shields.io/badge/_Watch_Demo-YouTube-red?style=for-the-badge&logo=youtube)](https://youtu.be/6N8IoaQvjco)

![App Demo](https://i.postimg.cc/zXJrRGD5/gify.gif)

*Interactive demonstration of Solar Terrain Analytics showing area drawing, analysis, and site management*

</div>

## Usage Guide

### Basic Operation
1. Sign in with your Google account
2. Draw an area on the map to analyze solar potential
3. View the heatmap and analysis results in the left panel
4. Save analyzed areas for later review
5. Manage saved sites from the dashboard

### Supported Platforms

| Platform | Status      | Features                |
|----------|-------------|-------------------------|
| Web      | Full        | All features            |
| Android  | Full        | All features            |
| iOS      | Planned     | (Requires setup)        |

### Keyboard Shortcuts (Web)

| Key         | Action                  |
|-------------|-------------------------|
| Mouse Click | Add polygon vertex      |
| ESC         | Cancel drawing          |
| ENTER       | Complete area drawing   |

## UI Panels

### Map Panel
- Draw and select areas directly on Google Maps
- View heatmap overlays for solar intensity
- Zoom, pan, and reset view controls

### Analysis Panel
- Real-time solar and shading analysis
- Detailed metrics and heatmap legend
- Save and name analyzed areas

### Saved Sites
- List of user-saved terrains
- Quick view and delete options
- Persistent across sessions

## Architecture

### Modular Design

#### Key Components
- **GoogleMapsDashboard**: Main UI for map and analysis
- **ApiService**: Handles all backend communication
- **SolarAnalysisPanel**: Displays analysis results
- **SavedSite Model**: Represents saved terrain data
- **Spring Boot Controllers**: REST endpoints for analysis and site management

## Backend API

### Main Endpoints

| Endpoint                | Method | Description                       |
|-------------------------|--------|-----------------------------------|
| `/api/health`           | GET    | Health check                      |
| `/api/analyze-area`     | POST   | Analyze a polygon area            |
| `/api/sites`            | GET    | List saved sites                  |
| `/api/sites`            | POST   | Save a new site                   |
| `/api/sites/{id}`       | DELETE | Delete a saved site               |

## Performance & Security

- Efficient polygon and shading calculations
- CORS configuration for safe cross-origin requests
- Firebase Auth filter for secure user endpoints
- Debug logging can be enabled/disabled via config

## Configuration

### Environment Variables & Keys
- Set your Google Maps and Firebase keys in the appropriate config files
- Restrict API keys in Google Cloud Console for security
- Use `.gitignore` to prevent leaking sensitive files

## Contributing

We welcome contributions from developers of all skill levels! Whether you're fixing bugs, adding new features, improving documentation, or suggesting enhancements, your help is appreciated.

### How to Contribute

1. **Fork the repository** to your GitHub account
2. **Create a feature branch** from the main branch (`git checkout -b feature/your-feature-name`)
3. **Make your changes** and test them thoroughly
4. **Commit your changes** with clear, descriptive messages
5. **Push to your fork** (`git push origin feature/your-feature-name`)
6. **Submit a pull request** with a detailed description of your changes

## Acknowledgments

- [Flutter](https://flutter.dev/) - Cross-platform UI toolkit
- [Spring Boot](https://spring.io/projects/spring-boot) - Java backend framework
- [Google Maps Platform](https://developers.google.com/maps) - Map and geospatial APIs
- [Firebase](https://firebase.google.com/) - Authentication and backend
