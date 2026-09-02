"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createBookingRequest = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
exports.createBookingRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }
    const role = context.auth.token.role || 'client'; // Default to client if no role
    const { clientName, contactPhone, eventType, location, startDateTime, endDateTime, equipmentRequested } = data;
    const db = admin.firestore();
    // Extract just the IDs for the array-contains-any query
    const equipmentIds = equipmentRequested.map((item) => item.equipmentId);
    const bookingData = {
        clientName,
        contactPhone,
        eventType,
        location,
        startDateTime: admin.firestore.Timestamp.fromMillis(startDateTime),
        endDateTime: admin.firestore.Timestamp.fromMillis(endDateTime),
        equipmentIds,
        equipmentRequested,
        status: 'Requested',
        createdBy: context.auth.uid,
        createdByRole: role,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        history: [{
                action: 'created',
                byUserId: context.auth.uid,
                byRole: role,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                note: 'Booking requested'
            }]
    };
    const bookingRef = await db.collection('bookings').add(bookingData);
    // Create line items
    const batch = db.batch();
    for (const item of equipmentRequested) {
        const itemRef = bookingRef.collection('items').doc();
        batch.set(itemRef, {
            ...item,
            startDate: bookingData.startDateTime,
            endDate: bookingData.endDateTime,
            status: 'Requested'
        });
    }
    await batch.commit();
    return { bookingId: bookingRef.id };
});
//# sourceMappingURL=createBookingRequest.js.map