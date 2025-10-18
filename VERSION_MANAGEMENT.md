# Version Management System

This document explains the automatic version checking and cache management system implemented in the WonWon app.

## Overview

The app now automatically:
1. **Checks for version updates** on every launch
2. **Clears cache** when a new version is detected
3. **Tracks user app versions** in the admin dashboard
4. **Forces users to use the latest version**

## How It Works

### 1. Version Checking on Launch

When the app starts (`main.dart`):
- `VersionService().checkAndHandleVersionUpdate()` is called
- Compares current app version with stored version in localStorage
- If versions differ, clears all caches and updates user's version in Firestore

### 2. Cache Clearing

When a new version is detected:
- **Service Worker caches** are cleared
- **localStorage** is cleared (except version info)
- **sessionStorage** is cleared
- User's app version is updated in Firestore

### 3. User Version Tracking

In the admin dashboard (`AdminUserManagementScreen`):
- Shows each user's current app version
- Displays version status (latest/outdated) with color-coded indicators
- Updates automatically when users launch new versions

## Files Modified

### Core Implementation
- `lib/services/version_service.dart` - Main version management service
- `lib/main.dart` - Added version check on app launch
- `lib/screens/admin_user_management_screen.dart` - Added version display

### Configuration
- `web/index.html` - Updated APP_VERSION constant
- `pubspec.yaml` - Current version: 1.0.76

### Deployment Scripts
- `update_version.sh` - Script to update version numbers
- `deploy_admin.sh` - Updated with version management
- `deploy_user.sh` - Updated with version management

## Usage

### Manual Version Update
```bash
./update_version.sh 1.0.77
```

### Automatic Version Increment (Optional)
Uncomment the version increment lines in deployment scripts:
```bash
# Uncomment these lines in deploy_admin.sh or deploy_user.sh
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
NEW_VERSION=$(echo $CURRENT_VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
./update_version.sh $NEW_VERSION
```

### Deployment Process
1. Update version (manually or automatically)
2. Run deployment script (`./deploy_admin.sh` or `./deploy_user.sh`)
3. Users will automatically get the new version on next launch

## Admin Dashboard Features

### User Version Display
- **App Version**: Shows user's current app version (e.g., "App v1.0.76")
- **Status Indicators**:
  - ✅ Green check: User on latest version
  - ⚠️ Orange warning: User on outdated version
- **Location**: Below "Last active" information in user cards

### Version Status Colors
- **Latest**: Green check mark
- **Outdated**: Orange warning icon
- **Unknown**: No indicator (version not tracked)

## Technical Details

### Version Service Methods
- `getCurrentVersion()` - Get current app version
- `checkAndHandleVersionUpdate()` - Main version check logic
- `getVersionStatus(userVersion)` - Compare user version with current
- `forceReload()` - Force browser reload

### Firestore Fields
New fields added to user documents:
- `appVersion` - Current app version (e.g., "1.0.76")
- `fullAppVersion` - Version with build number (e.g., "1.0.76+1")
- `lastVersionUpdate` - Timestamp of last version update
- `lastActiveAt` - Updated when version is checked

### Cache Management
- Clears all service worker caches
- Preserves only version information in localStorage
- Ensures users always get fresh content

## Benefits

1. **Always Up-to-Date**: Users automatically get the latest version
2. **No Stale Cache**: Cache is cleared on version updates
3. **Admin Visibility**: Track which users need updates
4. **Seamless Updates**: No manual cache clearing required
5. **Version Compliance**: Ensure all users use supported versions

## Troubleshooting

### Users Not Getting Updates
- Check if version numbers match in `pubspec.yaml` and `web/index.html`
- Verify deployment scripts are updating both files
- Check browser console for version check logs

### Admin Dashboard Not Showing Versions
- Users need to launch the app after the version tracking was implemented
- Version info is only available after user's first launch with the new system

### Cache Not Clearing
- Check browser console for cache clearing logs
- Verify service worker is properly registered
- Test with hard refresh (Ctrl+Shift+R)

## Future Enhancements

- **Version History**: Track user's version update history
- **Forced Updates**: Block access for critically outdated versions
- **Update Notifications**: Show in-app notifications for available updates
- **Rollback Support**: Ability to rollback to previous versions
- **A/B Testing**: Deploy different versions to different user groups
