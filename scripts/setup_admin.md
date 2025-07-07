# 👨‍💼 Admin Setup Guide

## 🔥 Firebase Setup Checklist

### ✅ Already Completed:
- ✅ Firebase project created (`english-modzy`)
- ✅ Flutter app configured with Firebase
- ✅ Firebase configuration files generated

### 🚀 Next Steps:

### 1. Enable Firebase Services
Go to [Firebase Console](https://console.firebase.google.com/project/english-modzy) and:

#### Authentication:
1. Click **Authentication** → **Get Started**
2. Go to **Sign-in method** tab
3. Enable **Email/Password** authentication
4. Click **Save**

#### Firestore Database:
1. Click **Firestore Database** → **Create database**
2. Choose **Start in test mode**
3. Select a location (choose closest to your users)
4. Click **Done**

#### Storage (Optional):
1. Click **Storage** → **Get Started**
2. Choose **Start in test mode**
3. Select same location as Firestore
4. Click **Done**

### 2. Test the App

#### Run the App:
```bash
flutter run -d chrome
```

#### Test User Registration:
1. Open the app
2. Click **"Sign Up"**
3. Fill in:
   - Full Name: `Test User`
   - Email: `test@example.com`
   - Password: `password123`
4. Click **"Create Account"**

### 3. Create Admin User

#### Option A: Manual (Recommended for first admin)
1. Register a normal user first
2. Go to [Firebase Console](https://console.firebase.google.com/project/english-modzy/firestore)
3. Click on **Firestore Database**
4. Find the `users` collection
5. Click on your user document
6. Edit the document
7. Change `role` field from `"user"` to `"admin"`
8. Click **Update**
9. Refresh the app - Admin panel will appear!

#### Option B: Using Firebase Admin SDK (Advanced)
```javascript
// In Firebase Console → Functions (if you set up Cloud Functions)
const admin = require('firebase-admin');

const makeUserAdmin = async (email) => {
  const userRecord = await admin.auth().getUserByEmail(email);
  await admin.firestore().collection('users').doc(userRecord.uid).update({
    role: 'admin'
  });
  console.log(`User ${email} is now an admin!`);
};

// Usage
makeUserAdmin('your-email@example.com');
```

### 4. Firestore Security Rules

In Firebase Console → Firestore → Rules, replace with:

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
    
    // Public read for lessons/vocabulary, admin write
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

### 5. Storage Security Rules (If you enabled Storage)

In Firebase Console → Storage → Rules:

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

## 🧪 Testing Checklist

### User Features:
- [ ] User registration works
- [ ] User login works
- [ ] Password reset works
- [ ] User dashboard displays
- [ ] Progress tracking shows
- [ ] Logout works

### Admin Features:
- [ ] Admin user can access admin panel
- [ ] Admin dashboard displays statistics
- [ ] Regular users cannot access admin panel
- [ ] Admin panel shows coming soon dialogs

### UI Features:
- [ ] Blue theme is applied correctly
- [ ] Text fields have blue borders and icons
- [ ] Buttons have blue gradients
- [ ] Animations work smoothly
- [ ] App is responsive on different screen sizes

## 🚨 Troubleshooting

### Authentication Issues:
```
Error: Firebase Auth not configured
```
**Solution:** Make sure Authentication is enabled in Firebase Console

### Firestore Issues:
```
Error: Cloud Firestore not configured
```
**Solution:** Make sure Firestore Database is created in Firebase Console

### Permission Issues:
```
Error: Missing or insufficient permissions
```
**Solution:** Check Firestore Security Rules are properly configured

### Build Issues:
```
Error: Firebase configuration not found
```
**Solution:** Make sure `firebase_options.dart` file exists and is imported in `main.dart`

## 📱 Next Steps After Setup

1. **Add Content:** Create lessons, vocabulary, and videos through the admin panel
2. **Customize Colors:** Edit `lib/core/constants/app_colors.dart` to change theme
3. **Add Features:** Implement lesson management, quiz system, etc.
4. **Deploy:** Use `flutter build web` and deploy to Firebase Hosting

## 🎉 Success!

Once you complete these steps, you'll have:
- ✅ Beautiful blue-themed English learning app
- ✅ Working authentication system
- ✅ Admin panel with role-based access
- ✅ Firebase backend fully configured
- ✅ Ready for content management and further development

**Happy coding! 🚀** 