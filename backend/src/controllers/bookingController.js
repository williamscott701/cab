const Booking = require('../models/Booking');
const Route = require('../models/Route');

// ── Customer ──────────────────────────────────────────────────────────────────

const createBooking = async (req, res) => {
  try {
    const { routeId, travelDate, numberOfPeople, preferredSeater, prefersCNG, customerNotes } = req.body;

    const route = await Route.findById(routeId);
    if (!route || !route.isActive) return res.status(404).json({ message: 'Route not found' });

    const priceEntry = route.prices.find(
      (p) => p.seaterCapacity === preferredSeater && p.isCNG === prefersCNG
    );
    if (!priceEntry) {
      return res.status(400).json({
        message: `No price defined for ${preferredSeater}-seater ${prefersCNG ? 'CNG' : 'non-CNG'} on this route`,
      });
    }

    const booking = await Booking.create({
      customerId: req.user._id,
      routeId,
      travelDate,
      numberOfPeople,
      preferredSeater,
      prefersCNG: prefersCNG ?? false,
      totalAmount: priceEntry.price,
      customerNotes: customerNotes || '',
    });

    res.status(201).json(booking);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ customerId: req.user._id })
      .populate('routeId', 'from to routeType')
      .sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const getMyBookingById = async (req, res) => {
  try {
    const booking = await Booking.findOne({ _id: req.params.id, customerId: req.user._id })
      .populate('routeId', 'from to routeType');
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    // Hide driver details until confirmed
    const result = booking.toObject();
    if (!['confirmed', 'completed'].includes(result.status)) {
      result.driverName = null;
      result.driverPhone = null;
      result.licensePlate = null;
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const updateMyBooking = async (req, res) => {
  try {
    const booking = await Booking.findOne({ _id: req.params.id, customerId: req.user._id });
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.status !== 'pending') {
      return res.status(400).json({ message: 'Only pending bookings can be edited' });
    }

    const { travelDate, numberOfPeople, preferredSeater, prefersCNG, customerNotes } = req.body;

    // Recalculate price if cab preference changed
    const seater = preferredSeater ?? booking.preferredSeater;
    const cng = prefersCNG ?? booking.prefersCNG;
    const route = await Route.findById(booking.routeId);
    if (!route) return res.status(404).json({ message: 'Route not found' });

    const priceEntry = route.prices.find(
      (p) => p.seaterCapacity === seater && p.isCNG === cng
    );
    if (!priceEntry) {
      return res.status(400).json({
        message: `No price defined for ${seater}-seater ${cng ? 'CNG' : 'non-CNG'} on this route`,
      });
    }

    if (travelDate !== undefined) booking.travelDate = travelDate;
    if (numberOfPeople !== undefined) booking.numberOfPeople = numberOfPeople;
    if (preferredSeater !== undefined) booking.preferredSeater = preferredSeater;
    if (prefersCNG !== undefined) booking.prefersCNG = prefersCNG;
    if (customerNotes !== undefined) booking.customerNotes = customerNotes;
    booking.totalAmount = priceEntry.price;

    await booking.save();

    const populated = await booking.populate([
      { path: 'routeId', select: 'from to routeType prices' },
    ]);

    res.json(populated);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findOne({ _id: req.params.id, customerId: req.user._id });
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.status !== 'pending') {
      return res.status(400).json({ message: 'Only pending bookings can be cancelled' });
    }
    booking.status = 'cancelled';
    await booking.save();
    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// ── Admin ─────────────────────────────────────────────────────────────────────

const getAllBookings = async (req, res) => {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;

    const bookings = await Booking.find(filter)
      .populate('customerId', 'name email phone')
      .populate('routeId', 'from to routeType')
      .sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const getBookingById = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('customerId', 'name email phone')
      .populate('routeId', 'from to routeType');
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const assignCab = async (req, res) => {
  try {
    const { driverName, driverPhone, licensePlate } = req.body;
    if (!driverName || !driverPhone || !licensePlate) {
      return res.status(400).json({ message: 'driverName, driverPhone, and licensePlate are required' });
    }

    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.status === 'cancelled') {
      return res.status(400).json({ message: 'Cannot assign to a cancelled booking' });
    }

    booking.driverName = driverName.trim();
    booking.driverPhone = driverPhone.trim();
    booking.licensePlate = licensePlate.trim().toUpperCase();
    booking.status = 'confirmed';
    await booking.save();

    const populated = await booking.populate([
      { path: 'customerId', select: 'name email phone' },
      { path: 'routeId', select: 'from to routeType' },
    ]);

    res.json(populated);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const updateBookingStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ['completed', 'cancelled'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: `Status must be one of: ${allowed.join(', ')}` });
    }

    const booking = await Booking.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    )
      .populate('customerId', 'name email phone')
      .populate('routeId', 'from to routeType');

    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

module.exports = {
  createBooking,
  getMyBookings,
  getMyBookingById,
  updateMyBooking,
  cancelBooking,
  getAllBookings,
  getBookingById,
  assignCab,
  updateBookingStatus,
};
