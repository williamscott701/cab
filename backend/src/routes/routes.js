const express = require('express');
const { body } = require('express-validator');
const {
  getAllRoutes,
  getRoute,
  createRoute,
  updateRoute,
  deleteRoute,
} = require('../controllers/routeController');
const { authenticate, requireRole } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

const priceValidation = body('prices')
  .isArray({ min: 1 })
  .withMessage('At least one price entry is required');

router.get('/', getAllRoutes);
router.get('/:id', getRoute);

router.post(
  '/',
  authenticate,
  requireRole('admin'),
  [
    body('from').trim().notEmpty().withMessage('From location is required'),
    body('to').trim().notEmpty().withMessage('To location is required'),
    priceValidation,
  ],
  validate,
  createRoute
);

router.put('/:id', authenticate, requireRole('admin'), updateRoute);
router.delete('/:id', authenticate, requireRole('admin'), deleteRoute);

module.exports = router;
