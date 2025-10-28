# Admin/Caretaker System Setup Guide

## Overview
The Thrive Wellness App now includes a comprehensive Admin/Caretaker portal for monitoring and managing elderly users' health and wellness.

## Features

### For Admins/Caretakers:
- ✅ Separate login portal with role-based access
- ✅ Dashboard with user overview and statistics
- ✅ View assigned users' health metrics (steps, heart rate, sleep)
- ✅ Monitor user activities and progress
- ✅ Manage medications for users (add, edit, delete)
- ✅ Track SOS events and emergency alerts
- ✅ Real-time data refresh

## Initial Setup

### 1. Create Admin User in Firebase Console

#### Method 1: Using Firebase Console (Recommended)

1. **Create Firebase Auth User:**
   - Go to Firebase Console → Authentication → Users
   - Click "Add user"
   - Email: `admin@thriveapp.com` (or your preferred email)
   - Password: Create a strong password
   - Note the UID of the created user

2. **Create Admin Document in Firestore:**
   - Go to Firebase Console → Firestore Database
   - Create a new collection: `admins`
   - Add a document with the UID from step 1 as the document ID
   - Add the following fields:

```json
{
  "email": "admin@thriveapp.com",
  "displayName": "Admin User",
  "role": "admin",
  "assignedUsers": [],
  "createdAt": [Timestamp - current],
  "lastLogin": [Timestamp - current],
  "isActive": true
}
```

#### Method 2: Using the App Script (Alternative)

The app includes a helper script at `lib/scripts/create_admin_user.dart`. However, this needs to be integrated into the app flow to run.

### 2. Assign Users to Admin/Caretaker

To allow an admin/caretaker to monitor specific users:

1. Get the user's UID from Firebase Authentication
2. Update the admin document in Firestore
3. Add the user UID to the `assignedUsers` array:

```json
{
  "assignedUsers": ["user1_uid", "user2_uid", "user3_uid"]
}
```

### 3. Create Caretaker Accounts

Caretakers have limited access compared to admins. To create a caretaker:

1. Create a Firebase Auth user (as in Admin setup)
2. Create an `admins` document with `role: "caretaker"`
3. Assign specific users to monitor via `assignedUsers` array

## Access Routes

### User Access:
- Regular user login: `/login`
- Regular user signup: `/signup`

### Admin Access:
- Admin/Caretaker login: `/admin/login`
- Admin dashboard: `/admin/dashboard`
- User detail view: `/admin/user/{userId}`

A link to Admin/Caretaker login is available at the bottom of the regular login screen.

## Admin Dashboard Features

### Main Dashboard (`/admin/dashboard`)
- Admin profile card with name, role, and email
- Statistics: Number of assigned users and SOS alerts
- Recent SOS events list
- Assigned users list with quick actions

### User Detail View (`/admin/user/{userId}`)

#### Health Tab:
- Latest health metrics:
  - Steps count
  - Heart rate (bpm)
  - Sleep hours
- Data refreshes on pull-down

#### Activities Tab:
- List of completed activities
- Points earned per activity
- Completion timestamps

#### Medications Tab:
- View all user medications
- Add new medication (name, dosage, frequency)
- Edit existing medications
- Delete medications
- Real-time list updates

#### SOS Events Tab:
- History of all SOS alerts
- Event type and description
- Location data (latitude/longitude)
- Timestamp of each event

## Data Structure

### Admin Collection (`admins`)
```
{
  "uid": "admin_user_id",
  "email": "admin@example.com",
  "displayName": "Admin Name",
  "role": "admin" | "caretaker",
  "assignedUsers": ["user1", "user2"],
  "createdAt": Timestamp,
  "lastLogin": Timestamp,
  "isActive": true
}
```

### Medications Collection (`medications`)
```
{
  "userId": "user_id",
  "name": "Medication Name",
  "dosage": "10mg",
  "frequency": "Twice daily",
  "createdAt": Timestamp,
  "addedBy": "admin_uid",
  "addedByRole": "admin"
}
```

### SOS Events (`users/{userId}/emergency_events`)
```
{
  "type": "SOS",
  "description": "Emergency alert triggered",
  "location": {
    "latitude": 0.0,
    "longitude": 0.0
  },
  "timestamp": Timestamp
}
```

## Security Considerations

1. **Authentication:**
   - Admins must be explicitly added to the `admins` collection
   - Regular users cannot access admin routes
   - Admin routes bypass regular user authentication

2. **Authorization:**
   - Admins can view all assigned users
   - Caretakers have the same permissions but typically fewer assigned users
   - Role-based access control via `role` field

3. **Best Practices:**
   - Use strong passwords for admin accounts
   - Regularly review assigned users
   - Monitor admin activity logs
   - Keep the `assignedUsers` list up to date

## Troubleshooting

### "Access denied. Admin credentials required."
- Ensure the user exists in the `admins` collection
- Verify the `isActive` field is set to `true`
- Check that the document ID matches the Firebase Auth UID

### "No users assigned"
- Update the `assignedUsers` array in the admin document
- Ensure user UIDs are correct

### "No health data available"
- Users must have health data recorded in Firestore
- Check the `healthData` collection for the user

### Medication list not auto-refreshing
- Medications are automatically refreshed after add/edit/delete operations
- Manual refresh available via pull-down gesture

## Future Enhancements

Potential features for future development:
- Multi-admin assignment (one user monitored by multiple admins)
- Admin activity logs
- Push notifications for SOS events
- Export health reports
- Medication reminders management
- Custom alert thresholds
- Analytics dashboard

