"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cancelBooking = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.cancelBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    const { bookingId, reason } = data;
    const db = admin.firestore();
    return db.runTransaction(async (tx) => {
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await tx.get(bookingRef);
        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }
        const booking = bookingDoc.data();
        const role = context.auth.token.role || 'client';
        // Client can only cancel their own requested booking
        if (role === 'client' && (booking.createdBy !== context.auth.uid || booking.status !== 'Requested')) {
            throw new functions.https.HttpsError('permission-denied', 'Cannot cancel this booking');
        }
        // Staff/admin can cancel Requested or Confirmed
        if (['admin', 'staff'].includes(role) && !['Requested', 'Confirmed'].includes(booking.status)) {
            throw new functions.https.HttpsError('failed-precondition', 'Cannot cancel booking in current state');
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        tx.update(bookingRef, {
            status: 'Cancelled',
            cancelledReason: reason || 'No reason provided',
            history: admin.firestore.FieldValue.arrayUnion({
                action: 'cancelled',
                byUserId: context.auth.uid,
                byRole: role,
                timestamp: now,
                note: reason
            })
        });
        // Update subcollection items
        const itemsSnapshot = await tx.get(bookingRef.collection('items'));
        itemsSnapshot.docs.forEach(doc => {
            tx.update(doc.ref, { status: 'Cancelled' });
        });
        return { status: 'Cancelled' };
    });
});
//# sourceMappingURL=cancelBooking.js.map