const mongoose = require('mongoose');

const priceEntrySchema = new mongoose.Schema(
  {
    seaterCapacity: { type: Number, required: true, enum: [4, 6, 7] },
    isCNG: { type: Boolean, required: true },
    price: { type: Number, required: true, min: 0 },
  },
  { _id: false }
);

const routeSchema = new mongoose.Schema(
  {
    from: { type: String, required: true, trim: true },
    to: { type: String, required: true, trim: true },
    routeType: {
      type: String,
      required: true,
      enum: ['city_to_airport', 'airport_to_city', 'city_to_city'],
    },
    prices: { type: [priceEntrySchema], required: true },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Route', routeSchema);
