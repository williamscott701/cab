const mongoose = require('mongoose');

const cabSchema = new mongoose.Schema(
  {
    driverName: { type: String, required: true, trim: true },
    driverPhone: { type: String, required: true, trim: true },
    vehicleModel: { type: String, required: true, trim: true },
    licensePlate: { type: String, required: true, unique: true, uppercase: true, trim: true },
    color: { type: String, required: true, trim: true },
    seaterCapacity: { type: Number, required: true, enum: [4, 6, 7] },
    isCNG: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Cab', cabSchema);
