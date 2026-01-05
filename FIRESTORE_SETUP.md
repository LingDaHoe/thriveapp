# Firestore Setup Guide for Admin and Caregiver Accounts

## Quick Setup (Recommended)

Use the built-in account creation screen:
1. Navigate to `/setup/create-accounts` in your app
2. Click "Create Accounts" button
3. Both accounts will be created automatically

## Manual Firestore Setup

If you prefer to set up manually or the script fails, follow these steps:

### Step 1: Create Firebase Authentication Users

1. Go to **Firebase Console** → **Authentication** → **Users**
2. Click **"Add user"** button
3. Create the following users:

#### Admin User:
- **Email**: `risadmin@thriveapp.com`
- **Password**: `Admin12312#`
- Copy the **UID** (you'll need this for Firestore)

#### Caregiver User:
- **Email**: `riscaregiver@thriveapp.com`
- **Password**: `Caregiver12312#`
- Copy the **UID** (you'll need this for Firestore)

### Step 2: Create Firestore Documents

1. Go to **Firebase Console** → **Firestore Database**
2. Create collection: `admins` (if it doesn't exist)

#### Admin Document:
- **Collection**: `admins`
- **Document ID**: `[UID from Admin Auth user]` ⚠️ **MUST MATCH EXACTLY**
- **Fields**:
  ```json
  {
    "email": "risadmin@thriveapp.com",
    "displayName": "Admin User",
    "role": "admin",
    "assignedUsers": [],
    "createdAt": [Server Timestamp] ⚠️ REQUIRED - Use "Set to server time",
    "lastLogin": [Server Timestamp] ⚠️ REQUIRED - Use "Set to server time",
    "isActive": true
  }
  ```
  
  **⚠️ IMPORTANT**: Both `createdAt` and `lastLogin` MUST be set to Server Timestamp. If either is null, you'll get a parsing error.

#### Caregiver Document:
- **Collection**: `admins`
- **Document ID**: `[UID from Caregiver Auth user]` ⚠️ **MUST MATCH EXACTLY**
- **Fields**:
  ```json
  {
    "email": "riscaregiver@thriveapp.com",
    "displayName": "Caregiver User",
    "role": "caretaker",
    "assignedUsers": [],
    "createdAt": [Server Timestamp] ⚠️ REQUIRED - Use "Set to server time",
    "lastLogin": [Server Timestamp] ⚠️ REQUIRED - Use "Set to server time",
    "isActive": true
  }
  ```
  
  **⚠️ IMPORTANT**: Both `createdAt` and `lastLogin` MUST be set to Server Timestamp. If either is null, you'll get a parsing error.

### Step 3: Verify Setup

1. Try logging in with:
   - **Admin**: `risadmin@thriveapp.com` / `Admin12312#`
   - **Caregiver**: `riscaregiver@thriveapp.com` / `Caregiver12312#`

2. Admin should redirect to `/admin/dashboard`
3. Caregiver should redirect to `/caregiver/dashboard`

## Field Descriptions

- **email**: User's email address (must match Firebase Auth email)
- **displayName**: Name displayed in the app
- **role**: Either `"admin"` or `"caretaker"` (caregiver)
- **assignedUsers**: Array of user IDs that this admin/caregiver can monitor (empty initially)
- **createdAt**: Server timestamp when account was created
- **lastLogin**: Server timestamp of last login (updates automatically)
- **isActive**: Boolean flag to enable/disable account (set to `true`)

## Important Notes

1. **Document ID must match Firebase Auth UID**: The Firestore document ID must be exactly the same as the Firebase Authentication UID for the user.

2. **Role values**: 
   - Use `"admin"` for administrators
   - Use `"caretaker"` for caregivers

3. **Server Timestamps**: In Firestore console, select "timestamp" type and click "Set to server time" for `createdAt` and `lastLogin` fields.

4. **Security**: Make sure your Firestore security rules allow admins to read/write their own documents.

## Troubleshooting

### Account created but can't login?
- Verify the Firestore document ID matches the Firebase Auth UID exactly
- Check that the `role` field is set correctly (`"admin"` or `"caretaker"`)
- Ensure `isActive` is set to `true`

### Redirecting to wrong dashboard?
- Check the `role` field in Firestore
- Verify router is checking Firestore correctly (should be automatic)

### "User is not an admin" error?
- The Firestore document doesn't exist or has wrong UID
- The document exists but `role` field is missing or incorrect

