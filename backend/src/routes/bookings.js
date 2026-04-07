const express = require('express');
const { body } = require('express-validator');
const {
  createBooking,
  getMyBookings,
  getMyBookingById,
  cancelBooking,
  getAllBookings,
  getBookingById,
  assignCab,
  updateBookingStatus,
} = require('../controllers/bookingController');
const { authenticate, requireRole } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

// Customer routes
router.post(
  '/',
  authenticate,
  requireRole('customer'),
  [
    body('routeId').notEmpty().withMessage('Route ID is required'),
    body('travelDate').isISO8601().withMessage('Valid travel date is required'),
    body('numberOfPeople').isInt({ min: 1 }).withMessage('Number of people must be at least 1'),
    body('preferredSeater').isIn([4, 6, 7]).withMessage('Preferred seater must be 4, 6, or 7'),
    body('prefersCNG').optional().isBoolean(),
    body('customerNotes').optional().isString(),
  ],
  validate,
  createBooking
);

router.get('/my', authenticate, requireRole('customer'), getMyBookings);
router.get('/my/:id', authenticate, requireRole('customer'), getMyBookingById);
router.patch('/my/:id/cancel', authenticate, requireRole('customer'), cancelBooking);

// Admin routes
router.get('/', authenticate, requireRole('admin'), getAllBookings);
router.get('/:id', authenticate, requireRole('admin'), getBookingById);

router.patch(
  '/:id/assign',
  authenticate,
  requireRole('admin'),
  [body('cabId').notEmpty().withMessage('cabId is required')],
  validate,
  assignCab
);

router.patch(
  '/:id/status',
  authenticate,
  requireRole('admin'),
  [body('status').isIn(['completed', 'cancelled']).withMessage('Invalid status')],
  validate,
  updateBookingStatus
);

module.exports = router;
