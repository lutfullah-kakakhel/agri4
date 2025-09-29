# AGRI4 ADVISOR - Hostinger Upload Guide

## 🌐 **Upload to Hostinger Website**

Your web app is ready! Here's how to upload it to your Hostinger website.

## 📁 **Files to Upload**

### **Source Location:**
- **Local folder:** `/home/l3k/agri4/agri4_app/build/web/`
- **Compressed file:** `agri4_web_app.tar.gz` (12MB)

### **Upload Options:**

#### **Option 1: Upload Compressed File (Recommended)**
1. **Download:** `agri4_web_app.tar.gz` (12MB)
2. **Upload to Hostinger** via File Manager
3. **Extract** in your website's public directory

#### **Option 2: Upload Individual Files**
1. **Copy all files** from `build/web/` folder
2. **Upload directly** to your website's public directory

## 🚀 **Step-by-Step Upload Process**

### **Step 1: Access Hostinger File Manager**
1. **Login** to your Hostinger account
2. **Go to** "hPanel" (control panel)
3. **Click** "File Manager"
4. **Navigate** to your website's public directory:
   - Usually: `public_html/` or `www/`
   - Or: `yourdomain.com/` folder

### **Step 2: Upload Files**

#### **Method A: Upload Compressed File**
1. **Click** "Upload Files" in File Manager
2. **Select** `agri4_web_app.tar.gz`
3. **Wait** for upload to complete
4. **Right-click** the uploaded file
5. **Select** "Extract" or "Extract Here"
6. **Delete** the .tar.gz file after extraction

#### **Method B: Upload Individual Files**
1. **Create folder** called `agri4-advisor` (optional)
2. **Upload all files** from `build/web/` folder:
   - `index.html`
   - `main.dart.js`
   - `flutter_bootstrap.js`
   - `manifest.json`
   - `favicon.png`
   - `assets/` folder (entire folder)
   - `icons/` folder (entire folder)
   - `canvaskit/` folder (entire folder)

### **Step 3: Set Up Access**

#### **Option A: Subdomain (Recommended)**
- **URL:** `https://agri4.yourdomain.com`
- **Setup:** Create subdomain in Hostinger
- **Upload to:** `public_html/agri4/` folder

#### **Option B: Subdirectory**
- **URL:** `https://yourdomain.com/agri4-advisor`
- **Upload to:** `public_html/agri4-advisor/` folder

#### **Option C: Main Domain**
- **URL:** `https://yourdomain.com`
- **Upload to:** `public_html/` folder (replace existing files)

## 📋 **File Structure After Upload**

```
yourdomain.com/
├── index.html              # Main app file
├── main.dart.js            # Flutter app code
├── flutter_bootstrap.js    # Flutter bootstrap
├── manifest.json           # PWA manifest
├── favicon.png            # Website icon
├── assets/                # App assets
│   ├── images/            # Crop icons, logos
│   ├── fonts/             # Font files
│   └── packages/          # Flutter packages
├── icons/                 # PWA icons
│   ├── Icon-192.png
│   ├── Icon-512.png
│   └── Icon-maskable-192.png
└── canvaskit/             # Flutter rendering engine
    ├── canvaskit.js
    ├── canvaskit.wasm
    └── skwasm.wasm
```

## 🔧 **Hostinger-Specific Settings**

### **Enable HTTPS (Important!)**
1. **Go to** "SSL" in hPanel
2. **Enable** "Let's Encrypt SSL"
3. **Force HTTPS** redirect

### **Set MIME Types (if needed)**
Add to `.htaccess` file:
```apache
# Flutter Web MIME types
AddType application/wasm .wasm
AddType application/javascript .js
AddType application/json .json
```

### **Enable GZIP Compression**
Add to `.htaccess`:
```apache
# Enable GZIP compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
    AddOutputFilterByType DEFLATE application/json
    AddOutputFilterByType DEFLATE application/wasm
</IfModule>
```

## 🎯 **Access Your App**

### **After Upload:**
- **Main URL:** `https://yourdomain.com/agri4-advisor/`
- **Direct access:** `https://yourdomain.com/agri4-advisor/index.html`

### **Test the App:**
1. **Visit** your website URL
2. **Check** if the app loads
3. **Test** map functionality
4. **Verify** all features work

## 📱 **Mobile Optimization**

### **PWA Features:**
- **Add to home screen** - works like native app
- **Offline capability** - cached data
- **Full-screen mode** - immersive experience

### **Mobile Testing:**
1. **Open** on mobile browser
2. **Test** touch gestures
3. **Check** GPS location
4. **Verify** responsive design

## 🚀 **Performance Optimization**

### **Enable Caching:**
Add to `.htaccess`:
```apache
# Cache static assets
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType application/wasm "access plus 1 year"
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
</IfModule>
```

### **CDN Setup (Optional):**
- **Use** Hostinger's CDN
- **Enable** in hPanel
- **Faster** global loading

## 🔍 **Troubleshooting**

### **Common Issues:**

#### **App doesn't load:**
- **Check** file permissions (644 for files, 755 for folders)
- **Verify** all files uploaded correctly
- **Check** browser console for errors

#### **Maps not working:**
- **Ensure** HTTPS is enabled
- **Check** if location permission is granted
- **Verify** internet connection

#### **Assets not loading:**
- **Check** file paths are correct
- **Verify** all folders uploaded
- **Check** MIME types in .htaccess

### **Debug Steps:**
1. **Open** browser developer tools (F12)
2. **Check** Console tab for errors
3. **Check** Network tab for failed requests
4. **Verify** all files are accessible

## 📊 **Analytics Setup**

### **Google Analytics:**
Add to `index.html` before closing `</head>`:
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

## 🎉 **Ready to Launch!**

After upload, your AGRI4 ADVISOR web app will be available at:
- **URL:** `https://yourdomain.com/agri4-advisor/`
- **Features:** All mobile app features
- **Platforms:** Windows, Mac, Linux, Android, iOS
- **Access:** No installation required!

**Users can now access your agricultural advisory app from any device with a web browser! 🌾**
