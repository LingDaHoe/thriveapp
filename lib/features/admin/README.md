# Admin/Caretaker Feature

## Overview
This feature provides a comprehensive administrative portal for monitoring and managing elderly users in the Thrive Wellness App.

## Structure

```
admin/
├── models/
│   └── admin_user.dart          # Admin user model with roles and permissions
├── services/
│   └── admin_service.dart       # Business logic for admin operations
├── screens/
│   ├── admin_login_screen.dart        # Admin authentication
│   ├── admin_dashboard_screen.dart    # Main admin dashboard
│   └── user_detail_screen.dart        # Detailed user monitoring
└── README.md
```

## Key Components

### Models

#### AdminUser (`models/admin_user.dart`)
- Represents an admin or caretaker user
- Fields: uid, email, displayName, role, assignedUsers, timestamps
- Roles: 'admin' or 'caretaker'
- Helper properties: `isAdmin`, `isCaretaker`

### Services

#### AdminService (`services/admin_service.dart`)
Core service handling all admin operations:

**Authentication:**
- `getCurrentAdminUser()` - Get current logged-in admin
- `adminLogin(email, password)` - Admin authentication
- `createAdminUser()` - Create new admin accounts

**User Management:**
- `getAssignedUsers(adminUid)` - Get all assigned users
- `getUserHealthMetrics(userId)` - Fetch user's health data
- `getUserActivities(userId)` - Get user's activity history

**Medication Management:**
- `getUserMedications(userId)` - Get user's medications
- `addMedicationForUser(userId, medication)` - Add medication
- `updateMedication(medicationId, updates)` - Edit medication
- `deleteMedication(medicationId)` - Remove medication

**SOS Monitoring:**
- `getSOSEvents(userId)` - Get user's SOS history
- `getAllSOSEvents(adminUid)` - Get all SOS events for assigned users

### Screens

#### AdminLoginScreen (`screens/admin_login_screen.dart`)
- Email/password authentication
- Validation and error handling
- Navigation to admin dashboard
- Back link to regular user login

#### AdminDashboardScreen (`screens/admin_dashboard_screen.dart`)
- Admin profile card
- Statistics: assigned users, SOS alerts
- Recent SOS events list
- Assigned users list with quick actions
- Refresh and logout functionality

#### UserDetailScreen (`screens/user_detail_screen.dart`)
Tabbed interface with 4 sections:

1. **Health Tab:**
   - Current health metrics (steps, heart rate, sleep)
   - Refresh on pull-down

2. **Activities Tab:**
   - Completed activities list
   - Points earned
   - Timestamps

3. **Medications Tab:**
   - List all medications
   - Add/Edit/Delete medications
   - Real-time updates

4. **SOS Events Tab:**
   - Emergency events history
   - Location data
   - Event details

## Routes

```dart
/admin/login                        # Admin login
/admin/dashboard                    # Main dashboard
/admin/user/:userId                 # User detail view
/admin/user/:userId/health          # Direct to health tab
/admin/user/:userId/medications     # Direct to medications tab
```

## Data Flow

### Login Flow:
1. User enters credentials in AdminLoginScreen
2. AdminService.adminLogin() authenticates with Firebase
3. Checks if user exists in `admins` collection
4. Updates lastLogin timestamp
5. Returns AdminUser or null
6. Navigates to dashboard or shows error

### Dashboard Flow:
1. AdminDashboardScreen loads
2. getCurrentAdminUser() checks authentication
3. getAssignedUsers() fetches user list
4. getAllSOSEvents() fetches recent alerts
5. Displays data with refresh capability

### User Monitoring Flow:
1. Admin clicks user in dashboard
2. Navigate to UserDetailScreen with userId
3. Loads user profile, health, activities, medications, SOS events
4. Displays in tabbed interface
5. Allows CRUD operations on medications

## Firestore Collections

### `admins`
```
{
  uid: string (document ID)
  email: string
  displayName: string
  role: 'admin' | 'caretaker'
  assignedUsers: string[]
  createdAt: Timestamp
  lastLogin: Timestamp
  isActive: boolean
}
```

### `medications`
```
{
  userId: string
  name: string
  dosage: string
  frequency: string
  createdAt: Timestamp
  addedBy: string (admin uid)
  addedByRole: 'admin' | 'caretaker'
}
```

### `users/{userId}/emergency_events`
```
{
  type: string
  description: string
  location: {
    latitude: number
    longitude: number
  }
  timestamp: Timestamp
}
```

## Security

### Authentication:
- Separate from regular user authentication
- Must exist in `admins` collection
- Active status check

### Authorization:
- Role-based access (admin/caretaker)
- Assigned users restriction
- Admin-only operations tracked (addedBy field)

## Usage Example

### Creating an Admin User (Firebase Console):
1. Create Firebase Auth user
2. Add document to `admins` collection:
```json
{
  "email": "admin@example.com",
  "displayName": "Admin Name",
  "role": "admin",
  "assignedUsers": ["user1_uid", "user2_uid"],
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLogin": "2024-01-01T00:00:00Z",
  "isActive": true
}
```

### Adding Medication Programmatically:
```dart
final adminService = AdminService();
await adminService.addMedicationForUser(
  'user_id',
  {
    'name': 'Aspirin',
    'dosage': '100mg',
    'frequency': 'Once daily',
  },
);
```

## Error Handling

All services include try-catch blocks with:
- Debug logging
- Graceful fallbacks
- User-friendly error messages
- Snackbar notifications in UI

## Future Enhancements

Potential improvements:
- [ ] Push notifications for SOS events
- [ ] Medication reminder scheduling
- [ ] Health trend analytics
- [ ] Export reports (PDF/CSV)
- [ ] Multi-admin assignment per user
- [ ] Admin activity logs
- [ ] Custom alert thresholds
- [ ] Bulk operations (assign multiple users)

## Testing

To test the admin features:
1. Create test admin in Firebase Console
2. Assign test user IDs
3. Login via `/admin/login`
4. Verify dashboard loads correctly
5. Test user detail views
6. Test medication CRUD operations
7. Verify SOS events display

## Dependencies

- `firebase_auth` - Authentication
- `cloud_firestore` - Data storage
- `go_router` - Navigation
- `flutter_bloc` - State management (inherited from app)

## Notes

- Admin routes bypass regular app authentication flow
- Refresh is pull-to-refresh or manual button
- All timestamps handled properly (Timestamp ↔ DateTime conversion)
- Medication list auto-refreshes after operations
- Empty states handled with helpful messages

