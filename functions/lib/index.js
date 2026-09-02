"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
const admin = require("firebase-admin");
admin.initializeApp();
// Export booking functions
__exportStar(require("./booking/createBookingRequest"), exports);
__exportStar(require("./booking/confirmBooking"), exports);
__exportStar(require("./booking/cancelBooking"), exports);
// Export dispatch functions
__exportStar(require("./dispatch/dispatchBooking"), exports);
__exportStar(require("./dispatch/returnBooking"), exports);
// Export auth triggers
__exportStar(require("./auth/onUserCreate"), exports);
//# sourceMappingURL=index.js.map