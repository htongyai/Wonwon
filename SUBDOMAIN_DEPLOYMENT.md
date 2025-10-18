# Subdomain Deployment Guide

This guide explains how to deploy your WonWon app to separate subdomains for admin and user portals.

## 🎯 Overview

Your app now supports three deployment modes:

1. **Admin Portal Only** - `admin.yourdomain.com`
2. **User Portal Only** - `app.yourdomain.com` 
3. **Auto Mode** - `yourdomain.com` (original behavior)

## 🔧 Configuration

The deployment mode is controlled by environment variables in `WebConfig`:

```dart
// Force admin-only mode
static const bool forceAdminMode = bool.fromEnvironment('FORCE_ADMIN_MODE', defaultValue: false);

// Force user-only mode  
static const bool forceUserMode = bool.fromEnvironment('FORCE_USER_MODE', defaultValue: false);

// Deployment mode: 'admin', 'user', or 'auto'
static const String deploymentMode = String.fromEnvironment('DEPLOYMENT_MODE', defaultValue: 'auto');
```

## 🚀 Deployment Scripts

### Deploy Admin Portal Only
```bash
./deploy_admin.sh
```
- Builds with `--dart-define=FORCE_ADMIN_MODE=true`
- Deploys to `admin/` directory
- Only admin users can access
- Non-admin users see "Admin Portal Access Only" message

### Deploy User Portal Only
```bash
./deploy_user.sh
```
- Builds with `--dart-define=FORCE_USER_MODE=true`
- Deploys to `app/` directory
- All users access the regular interface
- Admin features are hidden/disabled

### Deploy Both Portals
```bash
./deploy_both.sh
```
- Runs both admin and user deployments
- Creates separate builds for each subdomain

## 📁 Directory Structure

After deployment, your server should have:

```
/
├── admin/          # Admin portal (admin.yourdomain.com)
│   └── build/web/
├── app/            # User portal (app.yourdomain.com)  
│   └── build/web/
└── build/web/      # Main site (yourdomain.com) - auto mode
```

## 🌐 Subdomain Configuration

### Apache/Nginx Configuration

**Apache (.htaccess or virtual host):**
```apache
# Admin subdomain
<VirtualHost *:80>
    ServerName admin.yourdomain.com
    DocumentRoot /path/to/your/site/admin
</VirtualHost>

# User subdomain
<VirtualHost *:80>
    ServerName app.yourdomain.com
    DocumentRoot /path/to/your/site/app
</VirtualHost>
```

**Nginx:**
```nginx
# Admin subdomain
server {
    listen 80;
    server_name admin.yourdomain.com;
    root /path/to/your/site/admin;
    index index.html;
}

# User subdomain  
server {
    listen 80;
    server_name app.yourdomain.com;
    root /path/to/your/site/app;
    index index.html;
}
```

### DNS Configuration

Add these DNS records:
- `admin.yourdomain.com` → Your server IP
- `app.yourdomain.com` → Your server IP

## 🔒 Security Benefits

### Admin Portal (`admin.yourdomain.com`)
- ✅ Only admin users can access
- ✅ Smaller attack surface
- ✅ Can be behind additional authentication (VPN, IP whitelist)
- ✅ Separate logging and monitoring

### User Portal (`app.yourdomain.com`)
- ✅ No admin functionality exposed
- ✅ Optimized for regular users
- ✅ Can handle higher traffic loads
- ✅ Separate caching strategies

## 🛠 Customization

### Update FTP Credentials

Edit the deployment scripts to match your hosting setup:

```bash
# In deploy_admin.sh and deploy_user.sh
lftp -u YOUR_USERNAME,YOUR_PASSWORD ftp://your-ftp-server.com <<EOF
set ssl:verify-certificate no
cd admin  # or app for user portal
mirror -R build/web .
quit
EOF
```

### Firebase Hosting

For Firebase hosting, create separate projects:

```bash
# Admin portal
firebase use admin-project-id
firebase deploy --only hosting

# User portal  
firebase use user-project-id
firebase deploy --only hosting
```

### Environment Variables

You can also set deployment mode via environment variables:

```bash
# Build admin portal
flutter build web --release --dart-define=DEPLOYMENT_MODE=admin

# Build user portal
flutter build web --release --dart-define=DEPLOYMENT_MODE=user
```

## 🧪 Testing

### Local Testing

Test different modes locally:

```bash
# Test admin mode
flutter run -d chrome --dart-define=FORCE_ADMIN_MODE=true

# Test user mode
flutter run -d chrome --dart-define=FORCE_USER_MODE=true
```

### Production Testing

1. Deploy to staging subdomains first
2. Test admin functionality on `admin.staging.yourdomain.com`
3. Test user functionality on `app.staging.yourdomain.com`
4. Verify access controls work correctly

## 📊 Benefits

✅ **Easier Management**: Separate deployments for different user types
✅ **Better Security**: Admin portal can be more restricted
✅ **Performance**: User portal optimized for regular users
✅ **Scalability**: Different caching and CDN strategies per subdomain
✅ **Maintenance**: Update admin portal without affecting users

## 🔄 Migration from Single Domain

1. Keep existing deployment at `yourdomain.com` (auto mode)
2. Add admin subdomain: `admin.yourdomain.com`
3. Add user subdomain: `app.yourdomain.com`
4. Gradually migrate users to appropriate subdomains
5. Eventually retire the main domain if desired

---

**Need help?** Check the deployment logs or contact your system administrator.
