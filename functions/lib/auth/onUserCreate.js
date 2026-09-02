"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserCreate = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
    const db = admin.firestore();
    // Create a profile doc for the user
    await db.collection('users').doc(user.uid).set({
        email: user.email,
        name: user.displayName || 'New User',
        phone: user.phoneNumber || null,
        roleDisplay: 'client', // Default to client visually
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Set default custom claim
    await admin.auth().setCustomUserClaims(user.uid, { role: 'client' });
});
//# sourceMappingURL=onUserCreate.js.map