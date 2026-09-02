"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.confirmBooking = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.confirmBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth || !['admin', 'staff'].includes(context.auth.token.role)) {
        throw new functions.https.HttpsError('permission-denied', 'Only staff can confirm bookings');
    }
    const { bookingId } = data;
    const db = admin.firestore();
    return db.runTransaction(async (tx) => {
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await tx.get(bookingRef);
        if (!bookingDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Booking not found');
        }
        const booking = bookingDoc.data();
        if (booking.status !== 'Requested') {
            throw new functions.https.HttpsError('failed-precondition', 'Booking must be in Requested status');
        }
        const equipmentDocs = {};
        for (const eqId of booking.equipmentIds) {
            const eqDoc = await tx.get(db.collection('equipment').doc(eqId));
            if (eqDoc.exists) {
                equipmentDocs[eqId] = eqDoc.data();
            }
        }
        // Query for overlapping confirmed/dispatched items using collectionGroup query
        // In actual production this would fetch all items, but for transaction limitations 
        // we query bookings with the equipment IDs that overlap
        const overlappingBookingsQuery = db.collection('bookings')
            .where('equipmentIds', 'array-contains-any', booking.equipmentIds)
            .where('status', 'in', ['Confirmed', 'Dispatched'])
            .where('startDateTime', '<', booking.endDateTime);
        const overlappingSnapshot = await tx.get(overlappingBookingsQuery);
        // In-memory filter for the other side of the date range
        const overlapping = overlappingSnapshot.docs
            .map(doc => ({ id: doc.id, ...doc.data() }))
            .filter((b) => b.endDateTime.toMillis() > booking.startDateTime.toMillis() && b.id !== bookingId);
        const committedQuantity = {};
        booking.equipmentIds.forEach((id) => committedQuantity[id] = 0);
        for (const b of overlapping) {
            for (const item of b.equipmentRequested) {
                if (committedQuantity[item.equipmentId] !== undefined) {
                    committedQuantity[item.equipmentId] += item.quantity;
                }
            }
        }
        const conflicts = [];
        for (const item of booking.equipmentRequested) {
            const eq = equipmentDocs[item.equipmentId];
            if (!eq)
                continue;
            const availableQuantity = eq.totalQuantity - (eq.damagedQuantity || 0);
            const remaining = availableQuantity - (committedQuantity[item.equipmentId] || 0);
            if (remaining < item.quantity) {
                conflicts.push({
                    equipmentId: item.equipmentId,
                    requested: item.quantity,
                    available: remaining
                });
            }
        }
        if (conflicts.length > 0) {
            throw new functions.https.HttpsError('failed-precondition', 'conflict', { conflicts });
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        tx.update(bookingRef, {
            status: 'Confirmed',
            confirmedBy: context.auth.uid,
            confirmedAt: now,
            history: admin.firestore.FieldValue.arrayUnion({
                action: 'confirmed',
                byUserId: context.auth.uid,
                byRole: context.auth.token.role,
                timestamp: now
            })
        });
        // Update subcollection items
        const itemsSnapshot = await tx.get(bookingRef.collection('items'));
        itemsSnapshot.docs.forEach(doc => {
            tx.update(doc.ref, { status: 'Confirmed' });
        });
        return { status: 'Confirmed' };
    });
});
//# sourceMappingURL=confirmBooking.js.map