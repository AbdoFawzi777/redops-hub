/**
 * RedOps Hub — Custom Claims Admin Promotion CLI Tool
 * 
 * This script runs locally using the Firebase Admin SDK to set the `admin: true` 
 * custom claim on a target user account. Custom claims are managed cryptographically 
 * on the Firebase Auth servers and cannot be modified by the client.
 * 
 * SECURITY PRECAUTIONS:
 * 1. Never commit the `service-account.json` file to version control.
 * 2. Delete the `service-account.json` key file immediately after running this script.
 * 
 * Usage:
 * 1. Go to Firebase Console > Project Settings > Service Accounts.
 * 2. Click "Generate New Private Key" and download the JSON file.
 * 3. Save it in this directory as `service-account.json`.
 * 4. Install dependencies: npm install firebase-admin
 * 5. Run: node promote_admin.js <USER_UID>
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'service-account.json');
const targetUid = process.argv[2];

if (!targetUid) {
  console.error('\x1b[31m[ERROR] Please specify the user UID as an argument.\x1b[0m');
  console.log('Usage: node promote_admin.js <USER_UID>');
  process.exit(1);
}

if (!fs.existsSync(serviceAccountPath)) {
  console.error('\x1b[31m[ERROR] Credentials file not found at:\x1b[0m', serviceAccountPath);
  console.log('\n\x1b[33m--- INSTRUCTIONS TO SET UP CREDENTIALS ---\x1b[0m');
  console.log('1. Open the Firebase Console (https://console.firebase.google.com/)');
  console.log('2. Select your project: redops-hub');
  console.log('3. Go to Project Settings (gear icon) > Service Accounts tab');
  console.log('4. Click the "Generate New Private Key" button');
  console.log('5. Download the JSON file, rename it to "service-account.json", and place it in this folder.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log(`\n\x1b[36mInitializing promotion sequence for UID: ${targetUid}...\x1b[0m`);

admin.auth().setCustomUserClaims(targetUid, { admin: true })
  .then(() => {
    console.log('\x1b[32m[SUCCESS] Custom claim "admin: true" has been set successfully.\x1b[0m');
    console.log(`\nUser with UID [${targetUid}] now has full administrative privileges.`);
    console.log('\x1b[33m[IMPORTANT] Please delete "service-account.json" immediately to prevent security leaks!\x1b[0m\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\x1b[31m[ERROR] Failed to set admin claims:\x1b[0m', error.message);
    process.exit(1);
  });
