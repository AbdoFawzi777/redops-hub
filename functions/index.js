/**
 * RedOps Hub — Firebase Cloud Functions
 * 
 * Secure Admin Promotion Endpoint using Cloud Functions.
 * 
 * In production, you would deploy this by running:
 * firebase deploy --only functions
 * 
 * Ensure the environment variable `ADMIN_SECRET_KEY` is set in the Functions configuration:
 * firebase functions:config:set admin.secret="YOUR_SECURE_RANDOM_SECRET_KEY"
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.promoteToAdmin = functions.https.onRequest(async (req, res) => {
  // Enforce HTTP POST
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed. Use POST.' });
  }

  const { uid, secret } = req.body;

  // Retrieve configured secret key
  const configuredSecret = functions.config().admin ? functions.config().admin.secret : null;

  if (!configuredSecret || secret !== configuredSecret) {
    console.warn(`Unauthorized promotion attempt for UID ${uid} with secret: ${secret}`);
    return res.status(403).json({ error: 'Forbidden. Invalid secret key.' });
  }

  if (!uid) {
    return res.status(400).json({ error: 'Bad Request. Missing target user uid.' });
  }

  try {
    // Set custom claim
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    
    // Write entry to security logs
    await admin.firestore().collection('security_logs').add({
      event: 'admin_promoted_via_cf',
      targetUid: uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Successfully promoted UID: ${uid} to Admin via Cloud Functions.`);
    return res.status(200).json({ success: true, message: `UID ${uid} promoted to Admin.` });
  } catch (error) {
    console.error('Error promoting user:', error);
    return res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

// Configure Nodemailer transporter with dynamic Gmail credentials
const nodemailer = require('nodemailer');
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email ? functions.config().email.user : 'placeholder@gmail.com',
    pass: functions.config().email ? functions.config().email.pass : 'placeholderpass'
  }
});

// Send Welcome Email on user registration (onCreate auth trigger)
exports.sendWelcomeEmail = functions.auth.user().onCreate(async (user) => {
  const email = user.email;
  const displayName = user.displayName || 'Operator';

  if (!email) {
    console.warn('Skipping welcome email: User has no email registered.');
    return null;
  }

  const mailOptions = {
    from: '"RedOps Tactical Team" <no-reply@redopshub.com>',
    to: email,
    subject: 'Welcome to RedOps Hub Command',
    text: `Hello ${displayName},\n\nThe team welcomes you, thanks you, and wishes you a good job. We hope to meet your expectations.\n\nHave a great day!\n\nBest regards,\nRedOps Tactical Team`,
    html: `<p>Hello <strong>${displayName}</strong>,</p>
           <p>The team welcomes you, thanks you, and wishes you a good job. We hope to meet your expectations.</p>
           <p>Have a great day!</p>
           <br>
           <p>Best regards,<br>RedOps Tactical Team</p>`
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`✓ Welcome email sent successfully to ${email}`);
    return { success: true };
  } catch (error) {
    console.error(`Failed to send welcome email to ${email}:`, error);
    return { success: false, error: error.message };
  }
});
