# 🌟 Modzy English - AI-Powered English Learning Platform

A beautiful and modern Flutter app for learning English with Firebase integration, featuring a comprehensive admin panel and stunning blue-themed UI design.

## ✨ Features

### 🎯 Core Features
- **Beautiful Blue-Themed UI** - Modern design with blue color scheme and smooth animations
- **Firebase Authentication** - Secure login, registration, and password reset
- **User Progress Tracking** - Track lessons completed, vocabulary learned, and overall progress
- **Admin Panel** - Complete admin dashboard for managing users, content, and analytics
- **Responsive Design** - Works perfectly on mobile, tablet, and web
- **Custom UI Components** - Beautiful custom text fields, buttons, and cards with blue borders and icons

### 👤 User Features
- User registration and login with **Remember Me** functionality
- Progress tracking with levels (Beginner to Advanced)
- Beautiful dashboard with statistics
- Comprehensive **Profile Management** with image upload
- **Learning History** tracking completed lessons and quizzes
- **Favorites System** for lessons, vocabulary, and videos
- **Settings Panel** with theme, language, and notification preferences
- Password reset functionality

### 🔧 Admin Features
- Admin dashboard with platform statistics
- User management (coming soon)
- Content management (coming soon)
- Media library management (coming soon)
- Analytics and reporting (coming soon)
- System settings (coming soon)

## 🎨 Design Features

### Color Scheme
- **Primary Blue**: Deep blue (#1E3A8A) for main elements
- **Light Blue**: Bright blue (#3B82F6) for highlights
- **Secondary Blue**: Light blue (#60A5FA) for secondary elements
- **Admin Purple**: Purple (#7C3AED) for admin-specific features

### UI Components
- **Custom Text Fields**: Blue-bordered inputs with icons and animations
- **Custom Buttons**: Gradient buttons with loading states and icons
- **Cards**: Beautiful cards with blue borders and shadow effects
- **Animations**: Smooth transitions and hover effects

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd modzy_english
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Enable Firebase Storage
   - Download configuration files:
     - `google-services.json` for Android (place in `android/app/`)
     - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
     - Add Firebase web configuration to `web/index.html`

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Platforms Supported
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart          # App color scheme
│   ├── services/
│   │   ├── firebase_service.dart    # Firebase operations
│   │   ├── cloudinary_service.dart  # Media management
│   │   └── preferences_service.dart # Local storage & preferences
│   ├── utils/
│   │   └── validators.dart          # Form validation
│   └── widgets/
│       ├── custom_text_field.dart   # Beautiful input fields
│       └── custom_button.dart       # Custom buttons
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart # Authentication logic
│   │   └── screens/
│   │       ├── login_screen.dart    # Login interface
│   │       └── register_screen.dart # Registration interface
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart     # Main dashboard
│   ├── profile/
│   │   └── screens/
│   │       ├── profile_screen.dart        # User profile
│   │       ├── edit_profile_screen.dart   # Edit profile
│   │       ├── settings_screen.dart       # App settings
│   │       ├── learning_history_screen.dart # Learning tracking
│   │       └── favorites_screen.dart      # Saved content
│   └── admin/
│       └── screens/
│           └── admin_dashboard_screen.dart # Admin panel
├── models/
│   ├── user_model.dart              # User data model
│   ├── video_model.dart             # Video content model
│   └── vocab_model.dart             # Vocabulary model
└── main.dart                        # App entry point
```

## 🔥 Firebase Configuration

### 1. Authentication Rules
Enable Email/Password authentication in Firebase Console.

### 2. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admin-only collections
    match /admin/{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Public read access for lessons and vocabulary
    match /lessons/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /vocabulary/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 3. Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## 👨‍💼 Admin Setup

To create an admin user:

1. Register a normal user account
2. Go to Firestore Console
3. Find the user document in the `users` collection
4. Change the `role` field from `'user'` to `'admin'`
5. The user will now have access to the admin panel

## 🎯 Usage

### For Regular Users
1. Register with email and password
2. Complete your profile
3. Access learning materials
4. Track your progress
5. View statistics and achievements

### For Administrators
1. Login with admin credentials
2. Access the admin panel from the home screen
3. View platform statistics
4. Manage users and content (features coming soon)
5. Monitor system analytics

## 🔧 Customization

### Changing Colors
Edit `lib/core/constants/app_colors.dart` to customize the color scheme:

```dart
// Change primary color
static const Color primary = Color(0xFF1E3A8A); // Your color here

// Change admin color
static const Color adminPrimary = Color(0xFF7C3AED); // Your color here
```

### Adding New Features
1. Create feature folder in `lib/features/`
2. Add screens, data, and widgets
3. Update navigation in `main.dart`
4. Add Firebase rules if needed

## 📦 Dependencies

### Main Dependencies
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `cached_network_image` - Image caching
- `image_picker` - Image selection
- `video_player` - Video playback

### UI Dependencies
- `loading_animation_widget` - Loading animations
- `shimmer` - Shimmer effects

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- The open-source community for inspiration

---

## 🔮 Coming Soon

- [ ] Lesson management system
- [ ] Vocabulary builder
- [ ] Video lessons
- [ ] Quiz system
- [ ] Progress analytics
- [ ] Push notifications
- [ ] Offline mode
- [ ] Multi-language support

---

**Built with ❤️ using Flutter and Firebase**
