"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.returnBooking = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.returnBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth || !['admin', 'staff', 'warehouse'].includes(context.auth.token.role)) {
        throw new functions.https.HttpsError('permission-denied', 'Only staff or warehouse can return');
    }
    const { bookingId } = data;
    const db = admin.firestore();
    return db.runTransaction(async (tx) => {
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await tx.get(bookingRef);
        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }
        if (bookingDoc.data().status !== 'Dispatched') {
            throw new functions.https.HttpsError('failed-precondition', 'Booking must be Dispatched to return');
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        tx.update(bookingRef, {
            status: 'Returned',
            returnedBy: context.auth.uid,
            returnedAt: now,
            history: admin.firestore.FieldValue.arrayUnion({
                action: 'returned',
                byUserId: context.auth.uid,
                byRole: context.auth.token.role,
                timestamp: now
            })
        });
        // Update subcollection items
        const itemsSnapshot = await tx.get(bookingRef.collection('items'));
        itemsSnapshot.docs.forEach(doc => {
            tx.update(doc.ref, { status: 'Returned' });
        });
        return { status: 'Returned' };
    });
});
//# sourceMappingURL=returnBooking.js.map