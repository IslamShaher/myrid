# Firebase Service Account JSON - Step-by-Step Guide

📘 **For detailed step-by-step instructions with exact button locations, see: `GET_FIREBASE_FILE_STEPS.md`**

## Method 1: Upload via Admin Panel (Recommended)

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Login with your Google account
3. Select your Firebase project (should match the Project ID in your Laravel admin settings)

### Step 2: Generate Service Account Key
1. Click the **gear icon** ⚙️ next to "Project Overview" (top left)
2. Select **"Project settings"**
3. Click on the **"Service Accounts"** tab
4. You'll see "Firebase Admin SDK" section
5. Under "Node.js" tab, click **"Generate new private key"** button
6. A warning dialog will appear - click **"Generate key"**
7. A JSON file will automatically download (filename like: `your-project-firebase-adminsdk-xxxxx-xxxxxxxxxx.json`)

### Step 3: Upload to Laravel Admin Panel
1. Login to your Laravel Admin Panel
2. Navigate to: **Notification Settings** → **Push Notification Settings**
3. Scroll down to the **"Firebase Setup"** section
4. Find the file upload field for the service account JSON
5. Click **"Choose File"** or **"Browse"**
6. Select the downloaded JSON file
7. Click **"Upload"** or **"Save"**
8. The file will be saved as `assets/admin/push_config.json`

✅ **Done!** Push notifications should now work.

---

## Method 2: Manual File Placement (Alternative)

If you prefer to place the file manually:

### Step 1-2: Same as above - Get the JSON file

### Step 3: Place File Manually
1. Make sure the `assets/admin/` directory exists:
   ```
   assets/admin/
   ```
2. Rename your downloaded JSON file to: `push_config.json`
3. Copy the file to: `assets/admin/push_config.json`
4. Ensure file permissions allow reading (usually 644 or 755)

---

## Method 3: Share File Contents with AI (For Help)

If you want me to help you set it up, you can:

### Option A: Share File Contents (Safe Method)
1. Open the downloaded JSON file in a text editor
2. Copy the contents
3. Share it with me (I can help verify and set it up)
4. **Note:** The file contains sensitive credentials - only share if you're comfortable

### Option B: Tell Me the Project ID
1. Open the JSON file
2. Find the `"project_id"` field
3. Tell me the project ID
4. I can help verify it matches your database config

---

## What the JSON File Looks Like

The file should have this structure:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

---

## Verification After Upload

After uploading, you can verify it worked by:

1. **Check file exists:**
   ```bash
   php artisan tinker
   >>> file_exists(getFilePath('pushConfig') . '/push_config.json');
   // Should return: true
   ```

2. **Test notification:**
   - Use the admin panel to send a test push notification
   - Check logs for any errors

---

## Troubleshooting

### "File not found" error:
- Make sure directory `assets/admin/` exists
- Check file permissions (readable by PHP)
- Verify filename is exactly: `push_config.json`

### "Authentication failed" error:
- Verify the JSON file is valid JSON
- Check that `project_id` matches your Firebase config in database
- Ensure the service account hasn't been deleted in Firebase Console

### "Permission denied" error:
- Check directory permissions
- Ensure web server can read the file
- Try: `chmod 644 assets/admin/push_config.json`

---

## Security Note

⚠️ **Important Security Reminders:**
- Never commit the JSON file to Git (add to `.gitignore`)
- Keep the file secure on your server
- Only share file contents with trusted parties
- If file is compromised, regenerate it immediately in Firebase Console

---

## Need Help?

If you encounter any issues:
1. Share the error message you're seeing
2. Tell me which method you're trying (Admin Panel or Manual)
3. I can help troubleshoot step-by-step

