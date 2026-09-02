"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.dispatchBooking = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.dispatchBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth || !['admin', 'staff', 'warehouse'].includes(context.auth.token.role)) {
        throw new functions.https.HttpsError('permission-denied', 'Only staff or warehouse can dispatch');
    }
    const { bookingId } = data;
    const db = admin.firestore();
    return db.runTransaction(async (tx) => {
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await tx.get(bookingRef);
        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }
        if (bookingDoc.data().status !== 'Confirmed') {
            throw new functions.https.HttpsError('failed-precondition', 'Booking must be Confirmed to dispatch');
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        tx.update(bookingRef, {
            status: 'Dispatched',
            dispatchedBy: context.auth.uid,
            dispatchedAt: now,
            history: admin.firestore.FieldValue.arrayUnion({
                action: 'dispatched',
                byUserId: context.auth.uid,
                byRole: context.auth.token.role,
                timestamp: now
            })
        });
        // Update subcollection items
        const itemsSnapshot = await tx.get(bookingRef.collection('items'));
        itemsSnapshot.docs.forEach(doc => {
            tx.update(doc.ref, { status: 'Dispatched' });
        });
        return { status: 'Dispatched' };
    });
});
//# sourceMappingURL=dispatchBooking.js.map