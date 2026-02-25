# Carvia - Vehicle Listing & Comparison App

## 🚗 About The Project
Carvia is a modern mobile application providing a premium experience for users to view, filter, and compare vehicles dynamically. The platform leverages intelligent integration for vehicle discovery, personalized suggestions, and real-time database syncing to ensure the latest marketplace state is always available. Designed with scalability and clean architecture, Carvia streamlines the vehicle discovery process seamlessly.

## ✨ Key Features
- **Dynamic Vehicle Discovery**: Browse massive lists of vehicles directly fetched from Firebase Firestore.
- **Side-by-Side Comparison**: Scroll-free, responsive table layout highlighting the best specifications across two vehicles perfectly balanced for phone formats. 
- **AI-Powered Searching/Interaction**: Intelligent filtering and integrations using the Google Generative AI toolkit.
- **Cloud Database (Firebase)**: Full CRUD operations for vehicle creation, test drive scheduling, and live state updates. 
- **Modern Theme System**: Includes responsive dark mode by default matching a premium marketplace look.
- **Provider State Management**: Fast, predictable, and robust cross-widget state execution.

## 🛠 Tech Stack
- **Framework**: Flutter (Dart SDK >= 3.10.0)
- **State Management**: Provider
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth & Google Sign-In
- **AI Integration**: Google Generative AI
- **Asset Storage**: Firebase Storage
- **Location & Mapping**: Google Maps, Geolocator, Geocoding
- **Styling**: Google Fonts (Outfit), Iconsax

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`>=3.10.0 <4.0.0`)
- Android Studio or VS Code with Flutter extensions installed.
- A functional Firebase backend config (`google-services.json` and `GoogleService-Info.plist`).

### Installation

1. Clone the repository:
```bash
git clone https://github.com/VehicleX/Carvia.git
cd Carvia
```

2. Fetch dependencies:
```bash
flutter clean
flutter pub get
```

3. Run the app on your connected device or emulator:
```bash
flutter run
```

---

## 📄 Documentation
For detailed insights into the project, tasks completion status, and roadmap mapping according to assignment guidelines, please refer to the [Project Document](Project_Document.md) located in the repository.
