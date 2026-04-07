const Cab = require('../models/Cab');

const getAllCabs = async (req, res) => {
  try {
    const filter = {};
    if (req.query.active === 'true') filter.isActive = true;
    if (req.query.seater) filter.seaterCapacity = Number(req.query.seater);
    if (req.query.cng !== undefined) filter.isCNG = req.query.cng === 'true';

    const cabs = await Cab.find(filter).sort({ createdAt: -1 });
    res.json(cabs);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const getCab = async (req, res) => {
  try {
    const cab = await Cab.findById(req.params.id);
    if (!cab) return res.status(404).json({ message: 'Cab not found' });
    res.json(cab);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const createCab = async (req, res) => {
  try {
    const cab = await Cab.create(req.body);
    res.status(201).json(cab);
  } catch (err) {
    if (err.code === 11000) return res.status(409).json({ message: 'License plate already exists' });
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const updateCab = async (req, res) => {
  try {
    const cab = await Cab.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!cab) return res.status(404).json({ message: 'Cab not found' });
    res.json(cab);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const deleteCab = async (req, res) => {
  try {
    const cab = await Cab.findByIdAndDelete(req.params.id);
    if (!cab) return res.status(404).json({ message: 'Cab not found' });
    res.json({ message: 'Cab deleted' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

module.exports = { getAllCabs, getCab, createCab, updateCab, deleteCab };
