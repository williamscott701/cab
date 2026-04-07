const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema(
  {
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    routeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Route', required: true },
    travelDate: { type: Date, required: true },
    numberOfPeople: { type: Number, required: true, min: 1 },
    preferredSeater: { type: Number, required: true, enum: [4, 6, 7] },
    prefersCNG: { type: Boolean, default: false },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'completed', 'cancelled'],
      default: 'pending',
    },
    driverName: { type: String, trim: true, default: null },
    driverPhone: { type: String, trim: true, default: null },
    licensePlate: { type: String, trim: true, default: null },
    totalAmount: { type: Number, required: true, min: 0 },
    customerNotes: { type: String, trim: true, default: '' },
  },
  { timestamps: true }
);

// Indexes for query performance
bookingSchema.index({ customerId: 1, createdAt: -1 });
bookingSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Booking', bookingSchema);
