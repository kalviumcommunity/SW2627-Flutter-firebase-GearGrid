import * as admin from 'firebase-admin';
admin.initializeApp();

// Export booking functions
export * from './booking/createBookingRequest';
export * from './booking/confirmBooking';
export * from './booking/cancelBooking';

// Export dispatch functions
export * from './dispatch/dispatchBooking';
export * from './dispatch/returnBooking';

// Export auth triggers
export * from './auth/onUserCreate';
