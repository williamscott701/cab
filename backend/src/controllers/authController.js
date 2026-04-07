const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Booking = require('../models/Booking');

const signToken = (user) =>
  jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });

const signup = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    const existing = await User.findOne({ email });
    if (existing) return res.status(409).json({ message: 'Email already registered' });

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, phone, passwordHash, role: 'customer' });

    const token = signToken(user);
    res.status(201).json({
      token,
      user: { _id: user._id, name: user.name, email: user.email, phone: user.phone, role: user.role },
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });

    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) return res.status(401).json({ message: 'Invalid credentials' });

    const token = signToken(user);
    res.json({
      token,
      user: { _id: user._id, name: user.name, email: user.email, phone: user.phone, role: user.role },
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const getMe = (req, res) => {
  const u = req.user;
  res.json({ _id: u._id, name: u.name, email: u.email, phone: u.phone, role: u.role });
};

const logout = (_req, res) => {
  // JWT is stateless; client discards token
  res.json({ message: 'Logged out successfully' });
};

const deleteAccount = async (req, res) => {
  try {
    const userId = req.user._id;

    // Cancel all pending or confirmed bookings so admin isn't left with ghost entries
    const cancelResult = await Booking.updateMany(
      { customerId: userId, status: { $in: ['pending', 'confirmed'] } },
      { status: 'cancelled' }
    );

    // Delete all bookings belonging to this user
    await Booking.deleteMany({ customerId: userId });

    // Delete the user account
    await User.findByIdAndDelete(userId);

    res.json({
      message: 'Account deleted',
      bookingsCancelled: cancelResult.modifiedCount,
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

module.exports = { signup, login, getMe, logout, deleteAccount };
