const express = require('express');
const { body } = require('express-validator');
const { getAllCabs, getCab, createCab, updateCab, deleteCab } = require('../controllers/cabController');
const { authenticate, requireRole } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

router.use(authenticate, requireRole('admin'));

router.get('/', getAllCabs);
router.get('/:id', getCab);

router.post(
  '/',
  [
    body('driverName').trim().notEmpty().withMessage('Driver name is required'),
    body('driverPhone').trim().notEmpty().withMessage('Driver phone is required'),
    body('vehicleModel').trim().notEmpty().withMessage('Vehicle model is required'),
    body('licensePlate').trim().notEmpty().withMessage('License plate is required'),
    body('color').trim().notEmpty().withMessage('Color is required'),
    body('seaterCapacity').isIn([4, 6, 7]).withMessage('Seater capacity must be 4, 6, or 7'),
    body('isCNG').optional().isBoolean().withMessage('isCNG must be boolean'),
  ],
  validate,
  createCab
);

router.put('/:id', updateCab);
router.delete('/:id', deleteCab);

module.exports = router;
