# Saama Maintenance Page

A professional static maintenance page for signin.saama.cloud with modern design and auto-refresh functionality.

## Features

✨ **Modern Design**
- Dark theme with glassmorphism effects
- Smooth animations and transitions
- Responsive layout for all devices
- Professional gradient branding

🔄 **Auto-Refresh**
- Automatically refreshes every 5 minutes
- Checks if maintenance is complete
- Manual refresh with F5 key

📱 **Responsive**
- Works on desktop, tablet, and mobile
- Optimized for all screen sizes

## Files Included

- `index.html` - Main HTML structure
- `styles.css` - Complete styling with animations
- `script.js` - Auto-refresh and interactive functionality
- `README.md` - This documentation file

## Deployment Instructions

### Option 1: Simple HTTP Server (Python)

```bash
# Navigate to the directory
cd saama-maintenance

# Python 3
python3 -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

Then open http://localhost:8000 in your browser.

### Option 2: Node.js HTTP Server

```bash
# Install http-server globally (one time)
npm install -g http-server

# Navigate to the directory
cd saama-maintenance

# Start server
http-server -p 8000
```

### Option 3: Using PHP

```bash
cd saama-maintenance
php -S localhost:8000
```

### Option 4: Deploy to Web Server

1. **Upload Files**: Upload all files (index.html, styles.css, script.js) to your web server
2. **Configure Web Server**: Point your domain/subdomain to the directory
3. **For signin.saama.cloud**: 
   - Replace the existing content with these files
   - Or configure a redirect to this maintenance page

### Option 5: Using Nginx

Add this to your nginx configuration:

```nginx
server {
    listen 80;
    server_name signin.saama.cloud;
    
    root /path/to/saama-maintenance;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Option 6: Using Apache

Create/update `.htaccess`:

```apache
DirectoryIndex index.html

<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
</IfModule>
```

## Customization

### Change Maintenance Duration
Edit `index.html` line 48:
```html
<p class="info-text">Approximately 2-4 hours</p>
```

### Change Auto-Refresh Interval
Edit `script.js` line 2:
```javascript
const AUTO_REFRESH_INTERVAL = 5 * 60 * 1000; // 5 minutes
```

### Change Support Email
Edit `index.html` line 56:
```html
<p class="info-text">Contact: <a href="mailto:support@saama.com">support@saama.com</a></p>
```

### Change Colors
Edit `styles.css` root variables (lines 13-23):
```css
:root {
    --primary-gradient-start: #667eea;
    --primary-gradient-end: #764ba2;
    /* ... other colors ... */
}
```

## Testing Locally

1. Open `index.html` directly in your browser (double-click the file)
2. Or use any of the HTTP server options above for a more realistic test

## Browser Compatibility

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

## Notes

- The page will auto-refresh every 5 minutes to check if maintenance is complete
- All assets are self-contained (no external dependencies except Google Fonts)
- The design uses modern CSS features (backdrop-filter, CSS animations)
- JavaScript is minimal and focuses on auto-refresh functionality

## Support

For questions or issues, contact: support@saama.com

---

**Created**: December 12, 2025  
**Version**: 1.0.0
