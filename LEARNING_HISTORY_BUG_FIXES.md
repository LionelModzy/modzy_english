# Learning History Bug Fixes

## Issues Fixed

### 1. Quiz History Permission Denied Error
**Problem**: Regular users were getting "permission denied" errors when accessing quiz history, while admin users could see it fine.

**Root Cause**: The code was trying to access quiz results from `users/{userId}/quiz_results` (subcollection), but the actual Firestore structure stores quiz results in a top-level `quiz_results` collection.

**Fix**: Updated the quiz history loading logic in `learning_history_screen.dart`:
```dart
// OLD (incorrect):
final quizHistory = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('quiz_results')
    .orderBy('completedAt', descending: true)
    .limit(20)
    .get();

// NEW (correct):
final quizHistory = await FirebaseFirestore.instance
    .collection('quiz_results')
    .where('userId', isEqualTo: userId)
    .orderBy('completedAt', descending: true)
    .limit(20)
    .get();
```

### 2. Missing Firestore Index
**Problem**: The app was failing to load learning history data due to missing Firestore indexes for the `general_progress` collection.

**Error**: `[cloud_firestore/failed-precondition] The query requires an index`

**Fix**: Added the required index to `firestore.indexes.json`:
```json
{
  "collectionGroup": "general_progress",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "activityType",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "completedAt",
      "order": "DESCENDING"
    },
    {
      "fieldPath": "__name__",
      "order": "DESCENDING"
    }
  ]
}
```

### 3. Code Formatting Issues
**Problem**: Inconsistent indentation and missing setState calls in the learning history loading methods.

**Fix**: Fixed indentation and ensured proper setState calls in:
- `_loadLessonHistory()`
- `_loadQuizHistory()`
- `_loadVocabularyHistory()`

## Files Modified

1. **lib/features/profile/screens/learning_history_screen.dart**
   - Fixed quiz history collection path
   - Fixed indentation issues
   - Ensured proper setState calls

2. **firestore.indexes.json**
   - Added missing index for general_progress collection

3. **scripts/create_firestore_index.md**
   - Created instructions for manual index creation

## Next Steps

### Deploy Firestore Index
The Firestore index needs to be deployed. Choose one of these options:

1. **Automatic (Recommended)**: When you run the app, it will show an error with a direct link to create the index. Click that link.

2. **Manual**: Go to [Firebase Console](https://console.firebase.google.com/project/english-modzy/firestore/indexes) and create the index manually.

3. **CLI**: If you have Firebase CLI installed:
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Expected Results After Fix
- ✅ Quiz history loads for regular users (not just admin)
- ✅ No more "permission denied" errors
- ✅ Learning history shows actual data instead of empty states
- ✅ All three tabs (Lessons, Quizzes, Vocabulary) work correctly
- ✅ Search and filtering functionality works

## Testing
1. Login as a regular user (not admin)
2. Navigate to Learning History
3. Check all three tabs:
   - Lessons tab should show completed lessons
   - Quizzes tab should show quiz results (no permission error)
   - Vocabulary tab should show vocabulary practice history
4. Test search functionality in each tab
5. Verify that data loads correctly and summaries show proper counts

## Security Rules Verification
The Firestore security rules are correctly configured:
- Users can read their own quiz results from the top-level `quiz_results` collection
- Admin users can read all quiz results
- The `general_progress` subcollection is accessible to users for their own data
