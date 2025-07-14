# Firebase Firestore Indexes Setup

Các indexes cần thiết cho Modzy English app:

## Required Composite Indexes

### 1. Vocabulary by Category and CreatedAt
```
Collection: vocabulary
Fields:
- category (Ascending)
- createdAt (Descending)
- __name__ (Descending)
```

### 2. Favorites by Type and AddedAt
```
Collection: users/{userId}/favorites
Fields:
- type (Ascending)  
- addedAt (Descending)
- __name__ (Descending)
```

## Setup Instructions

1. **Thông qua Firebase Console:**
   - Truy cập: https://console.firebase.google.com/project/english-modzy/firestore/indexes
   - Click "Create Index"
   - Thêm các fields theo thứ tự trên

2. **Thông qua CLI:**
```bash
# Cài đặt Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Khởi tạo project (nếu chưa có)
firebase init firestore

# Deploy indexes
firebase deploy --only firestore:indexes
```

3. **File firestore.indexes.json:**
```json
{
  "indexes": [
    {
      "collectionGroup": "vocabulary",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "category",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt", 
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "favorites",
      "queryScope": "COLLECTION_GROUP", 
      "fields": [
        {
          "fieldPath": "type",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "addedAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## Security Rules Update

Cập nhật Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User favorites
      match /favorites/{favoriteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Vocabulary - read for all authenticated users
    match /vocabulary/{vocabId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Lessons - read for all authenticated users  
    match /lessons/{lessonId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Admin collections
    match /admin/{adminId} {
      allow read, write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

## Automatic Index Creation Links

Nếu app báo lỗi missing index, click vào links này để tạo tự động:

1. **Vocabulary by Category:**
   https://console.firebase.google.com/v1/r/project/english-modzy/firestore/indexes?create_composite=ClBwcm9qZWN0cy9lbmdsaXNoLW1vZHp5L2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy92b2NhYnVsYXJ5L2luZGV4ZXMvXxABGgwKCGNhdGVnb3J5EAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg

2. **User Favorites:**
   Sẽ được tạo khi cần thiết qua error links.

## Verification

Sau khi setup, test các queries:
- Vocabulary by category filtering
- Favorites loading by type
- Search functionality with filters

## Common Issues

1. **Permission Denied:** Cập nhật Security Rules
2. **Index Building:** Đợi 1-2 phút để indexes build
3. **Offline/Online:** Test cả offline và online mode 