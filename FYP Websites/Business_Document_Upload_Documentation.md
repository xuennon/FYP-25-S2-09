# Business Document Upload Feature Documentation

## Overview
This feature allows business users to upload registration documents during the signup process with comprehensive security measures and validation.

## Features Implemented

### 1. Client-Side Validation
- **File Type Validation**: Only PDF, JPG, JPEG, and PNG files are accepted
- **File Size Validation**: Maximum 5MB per file
- **File Count Validation**: Maximum 3 files per upload
- **Real-time Validation**: Files are validated immediately upon selection

### 2. Security Measures

#### Client-Side Security
- File type checking using MIME types
- File size validation before upload
- Sanitized file naming to prevent path traversal attacks
- Progress indicators and error handling

#### Server-Side Security (Firebase Storage Rules)
- User authentication required for all operations
- Users can only upload to their own directory (`business_documents/{userId}/`)
- File size validation enforced at storage level (5MB max)
- Content type validation at storage level
- Filename pattern validation to prevent malicious uploads
- Admin-only access for reading all documents and managing files

### 3. File Upload Process

#### Upload Flow
1. User selects files → Client validation
2. Form submission → Account creation
3. File upload to Firebase Storage with structured naming
4. Document metadata saved to Firestore
5. Admin notification for review

#### File Storage Structure
```
business_documents/
  └── {userId}/
      ├── business_doc_1_{timestamp}.pdf
      ├── business_doc_2_{timestamp}.jpg
      └── business_doc_3_{timestamp}.png
```

### 4. Database Schema Updates

#### BusinessUsers Collection
```javascript
{
  // ... existing fields
  businessDocuments: [
    {
      name: "business_doc_1_1692123456789.pdf",
      originalName: "business_registration.pdf",
      url: "https://firebasestorage.googleapis.com/...",
      size: 1234567,
      type: "application/pdf",
      uploadedAt: "2023-08-15T10:30:45.123Z"
    }
  ],
  documentVerificationStatus: "pending" // pending | approved | rejected
}
```

## Firebase Storage Rules Deployment

### Deploy Storage Rules
1. Copy the `storage.rules` file to your Firebase project
2. Deploy using Firebase CLI:
```bash
firebase deploy --only storage
```

### Admin Setup Required
The storage rules reference an admin check. Choose one implementation:

#### Option 1: Firestore Admin Collection (Recommended)
Create an `admins` collection with admin user documents:
```javascript
// Firestore: /admins/{adminUserId}
{
  role: "admin",
  permissions: ["manage_users", "verify_documents"],
  createdAt: "2023-08-15T10:30:45.123Z"
}
```

#### Option 2: Custom Claims (Advanced)
Set up custom claims in your backend:
```javascript
admin.auth().setCustomUserClaims(uid, { admin: true })
```

#### Option 3: Hard-coded UIDs (Development Only)
Replace the `isAdmin` function with specific UIDs:
```javascript
function isAdmin(uid) {
  return uid in ['YOUR_ADMIN_UID_1', 'YOUR_ADMIN_UID_2'];
}
```

## Security Best Practices Implemented

### 1. Input Validation
- ✅ File type whitelist (not blacklist)
- ✅ File size limits
- ✅ File count limits
- ✅ Filename sanitization

### 2. Access Control
- ✅ User-specific upload directories
- ✅ Authentication required for all operations
- ✅ Admin-only document management
- ✅ Principle of least privilege

### 3. Error Handling
- ✅ Graceful error messages
- ✅ Upload progress indicators
- ✅ Rollback on failure
- ✅ User-friendly error display

### 4. Data Integrity
- ✅ Atomic operations (account + documents)
- ✅ Metadata tracking
- ✅ Audit trail with timestamps
- ✅ Document verification workflow

## Usage Instructions

### For Business Users
1. Fill out the registration form
2. Select business documents (PDF, JPG, JPEG, or PNG)
3. Maximum 3 files, 5MB each
4. Submit form and wait for upload completion
5. Account pending admin review

### For Administrators
1. Access admin panel (to be implemented)
2. Review business registrations
3. Download and verify uploaded documents
4. Approve or reject applications
5. Update verification status

## Maintenance Notes

### Regular Tasks
- Monitor storage usage and costs
- Review and audit document access logs
- Update security rules as needed
- Clean up rejected applications (implement retention policy)

### Monitoring
- Track upload success/failure rates
- Monitor file storage costs
- Review security rule effectiveness
- Audit admin access patterns

## Error Handling

### Common Errors and Solutions
1. **File too large**: Clear messaging, suggest compression
2. **Invalid file type**: Show accepted formats
3. **Upload failure**: Retry mechanism, error reporting
4. **Authentication errors**: Redirect to login
5. **Storage quota exceeded**: Admin notification system

## Future Enhancements
- Document compression for large files
- Preview functionality for uploaded documents
- Bulk document management for admins
- Automated document verification using OCR
- Email notifications for status updates
