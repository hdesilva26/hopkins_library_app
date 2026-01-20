# How to Set Up Your First Admin

## Step 1: Sign In to Your App
1. Run your Flutter app
2. Sign in with your Hopkins.edu Google account
3. This automatically creates a document in the `users` collection

## Step 2: Find Your User ID
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **hopkins-summer-reading**
3. Click **Authentication** → **Users**
4. Find your email address
5. Copy your **User UID** (it's a long string like `abc123xyz456...`)

## Step 3: Set Yourself as Admin
1. Go to **Firestore Database** in Firebase Console
2. Click on the **users** collection (it should already exist from Step 1)
3. Find your user document (the document ID is your User UID)
4. Click on your document to edit it
5. Change the `role` field from `student` to `admin`
6. Click **Update**

## Step 4: Refresh Your App
1. Go back to your Flutter app
2. Sign out and sign back in (or restart the app)
3. You should now see the **Admin Panel** button in your Profile page
4. The **Add Book** button should appear on the Explore tab

## Alternative: Quick Admin Setup Script
If you want to set yourself as admin programmatically, you can temporarily add this to your Profile page:

```dart
// TEMPORARY: Remove after first admin is set up
if (auth.userRole == 'student') {
  ElevatedButton(
    onPressed: () async {
      final userService = UserService();
      await userService.setUserRole(auth.user!.uid, UserService.roleAdmin);
      // Force refresh
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    },
    child: Text('Make Me Admin (One-Time Setup)'),
  ),
}
```

## Firestore Collection Structure
The `users` collection will have documents like this:

```
users/
  └── {userId}/
      ├── role: "admin" or "student"
      ├── email: "user@hopkins.edu"
      ├── displayName: "User Name"
      ├── createdAt: Timestamp
      └── updatedAt: Timestamp
```

## Security Rules
Make sure your Firestore security rules allow users to read their own data and admins to write:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can read their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      // Admins can read all user data
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      // Only admins can write user roles
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

