const Booking = require('../models/Booking');
const Route = require('../models/Route');
const Cab = require('../models/Cab');

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
      .populate('assignedCabId')
      .sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const getMyBookingById = async (req, res) => {
  try {
    const booking = await Booking.findOne({ _id: req.params.id, customerId: req.user._id })
      .populate('routeId', 'from to routeType')
      .populate('assignedCabId');
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    // hide cab details until confirmed
    const result = booking.toObject();
    if (!['confirmed', 'completed'].includes(result.status)) {
      result.assignedCabId = null;
    }

    res.json(result);
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
      .populate('assignedCabId')
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
      .populate('routeId', 'from to routeType prices')
      .populate('assignedCabId');
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const assignCab = async (req, res) => {
  try {
    const { cabId } = req.body;
    if (!cabId) return res.status(400).json({ message: 'cabId is required' });

    const cab = await Cab.findById(cabId);
    if (!cab || !cab.isActive) return res.status(404).json({ message: 'Cab not found or inactive' });

    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.status === 'cancelled') {
      return res.status(400).json({ message: 'Cannot assign cab to a cancelled booking' });
    }

    booking.assignedCabId = cabId;
    booking.status = 'confirmed';
    await booking.save();

    const populated = await booking.populate([
      { path: 'customerId', select: 'name email phone' },
      { path: 'routeId', select: 'from to routeType' },
      { path: 'assignedCabId' },
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
      .populate('routeId', 'from to routeType')
      .populate('assignedCabId');

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
  cancelBooking,
  getAllBookings,
  getBookingById,
  assignCab,
  updateBookingStatus,
};
