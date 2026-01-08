# Firebase Setup Instructions

This guide will help you set up Firebase for the FleetTrack iOS application.

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `FleetTrack` (or your preferred name)
4. Disable Google Analytics (optional for development)
5. Click **"Create project"**

---

## Step 2: Add iOS App to Firebase Project

1. In Firebase Console, click the **iOS icon** to add an iOS app
2. Enter iOS bundle ID: `com.fleettrack.FleetTrack` (or match your Xcode bundle ID)
3. Enter App nickname: `FleetTrack iOS`
4. Leave App Store ID empty (for now)
5. Click **"Register app"**

---

## Step 3: Download Configuration File

1. Download `GoogleService-Info.plist`
2. **Important:** Save this file - you'll add it to Xcode in the next step
3. Click **"Next"** and **"Continue to console"**

---

## Step 4: Add GoogleService-Info.plist to Xcode

1. Open your FleetTrack project in Xcode
2. Drag `GoogleService-Info.plist` into the Xcode project navigator
3. **Important:** Make sure "Copy items if needed" is checked
4. Make sure the file is added to the FleetTrack target
5. The file should be at the root level of your project

**File location should be:**
```
FleetTrack/
├── GoogleService-Info.plist  ← Here
├── FleetTrack/
│   ├── App/
│   ├── Core/
│   └── ...
```

---

## Step 5: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter package URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: **10.20.0** or later
4. Click **"Add Package"**
5. Select the following products:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseAnalytics** (optional)
6. Click **"Add Package"**

---

## Step 6: Enable Authentication Methods

### Enable Email/Password Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click **"Email/Password"**
3. Toggle **"Enable"**
4. Click **"Save"**

### Enable Phone Authentication

1. In the same **Sign-in method** page
2. Click **"Phone"**
3. Toggle **"Enable"**
4. Click **"Save"**

**Note:** Phone authentication requires:
- Valid phone numbers for testing
- SMS quota (10,000 free per month)
- May require reCAPTCHA verification in production

---

## Step 7: Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in test mode"** (for development)
4. Choose a location (e.g., `us-central`)
5. Click **"Enable"**

**Security Rules (for development):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow admins to read all users (requires custom claims)
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.token.role == 'admin';
    }
  }
}
```

**Note:** Update these rules for production!

---

## Step 8: Initialize Firebase in Your App

The initialization code is already added in `FleetTrackApp.swift`:

```swift
import FirebaseCore

@main
struct FleetTrackApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    // ...
}
```

---

## Step 9: Test Firebase Connection

1. Build and run the app in Xcode
2. Check the console for Firebase initialization message
3. You should see: `[Firebase/Core][I-COR000003] The default Firebase app has been configured.`

---

## Step 10: Create Test Users

### Option 1: Via Firebase Console (Recommended for Development)

**Create Admin User:**
1. Go to **Authentication** → **Users**
2. Click **"Add user"**
3. Enter email: `admin@fleettrack.com`
4. Enter password: `Admin@123`
5. Click **"Add user"**
6. Manually add user metadata in Firestore:
   - Go to **Firestore Database**
   - Create collection: `users`
   - Create document with ID: (copy the UID from Authentication)
   - Add fields:
     ```
     id: <UID>
     role: "Fleet Manager"
     email: "admin@fleettrack.com"
     isActive: true
     isVerified: true
     createdAt: <current timestamp>
     twoFactorEnabled: false
     ```

**Create Driver User:**
1. In **Authentication**, click **"Add user"**
2. Use phone number: `+15551234567`
3. Set password (temporary)
4. Add to Firestore `users` collection:
   ```
   id: <UID>
   role: "Driver"
   phoneNumber: "+15551234567"
   employeeID: "DRV001"
   isActive: true
   isVerified: true
   createdAt: <current timestamp>
   twoFactorEnabled: true
   ```

### Option 2: Via App (After Implementation)

Use the admin creation flow in the app to create users programmatically.

---

## Step 11: Configure Phone Authentication (Optional)

For production phone authentication:

1. Go to **Authentication** → **Settings** → **Phone**
2. Add authorized domains
3. Configure reCAPTCHA (for web)
4. Set up App Check (recommended for production)

---

## Troubleshooting

### Issue: "GoogleService-Info.plist not found"
**Solution:** Make sure the file is in the root of your Xcode project and added to the target.

### Issue: "Firebase not configured"
**Solution:** Ensure `FirebaseApp.configure()` is called in `FleetTrackApp.swift` init.

### Issue: "Phone authentication not working"
**Solution:** 
- Check that Phone authentication is enabled in Firebase Console
- Verify phone number format includes country code (+1 for US)
- Check SMS quota in Firebase Console

### Issue: "Firestore permission denied"
**Solution:** Update Firestore security rules to allow authenticated users.

---

## Cost Estimate

### Firebase Free Tier (Spark Plan)
- ✅ Authentication: Unlimited users
- ✅ Phone Auth: 10,000 verifications/month
- ✅ Firestore: 1GB storage, 50K reads/day, 20K writes/day
- ✅ Hosting: 10GB storage, 360MB/day transfer

### When to Upgrade
- More than 10,000 SMS/month
- More than 50K Firestore reads/day
- More than 1GB Firestore storage

**Estimated cost for 100 active users:** $0-5/month

---

## Next Steps

1. ✅ Complete Firebase setup
2. ✅ Test authentication flows
3. ✅ Create test users
4. ✅ Implement Views (LoginView, etc.)
5. ✅ Deploy Firestore security rules
6. ✅ (Optional) Set up Cloud Functions for custom claims

---

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

---

**Need help?** Check the Firebase Console logs or contact support.
