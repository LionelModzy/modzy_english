# Create Missing Firestore Index

## Issue
The learning history screen is failing to load data because of a missing Firestore index for the `general_progress` collection.

## Error Message
```
[cloud_firestore/failed-precondition] The query requires an index. You can create it here:
https://console.firebase.google.com/v1/r/project/english-modzy/firestore/indexes?create_composite=...
```

## Solution

### Option 1: Use the Automatic Link (Recommended)
1. Copy the error message from the terminal/console
2. Click on the provided URL in the error message
3. Firebase Console will automatically create the required index
4. Wait 1-2 minutes for the index to build

### Option 2: Manual Creation
1. Go to [Firebase Console](https://console.firebase.google.com/project/english-modzy/firestore/indexes)
2. Click "Create Index"
3. Set the following fields:
   - **Collection Group ID**: `general_progress`
   - **Query Scope**: `Collection group`
   - **Fields**:
     - `activityType` (Ascending)
     - `completedAt` (Descending)
     - `__name__` (Descending)

### Option 3: Deploy via Firebase CLI (if available)
```bash
firebase deploy --only firestore:indexes
```

## Verification
After creating the index:
1. Wait 1-2 minutes for the index to build
2. Test the learning history screen
3. Check that quiz history loads without permission errors
4. Verify that vocabulary and lesson history also load correctly

## Expected Result
- Quiz history should load for regular users (not just admin)
- No more "permission denied" errors
- Learning history should show actual data instead of empty states
