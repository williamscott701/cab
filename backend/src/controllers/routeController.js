const Route = require('../models/Route');

const getAllRoutes = async (req, res) => {
  try {
    const routes = await Route.find({ isActive: true }).sort({ createdAt: -1 });
    res.json(routes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const getRoute = async (req, res) => {
  try {
    const route = await Route.findById(req.params.id);
    if (!route || !route.isActive) return res.status(404).json({ message: 'Route not found' });
    res.json(route);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const createRoute = async (req, res) => {
  try {
    const { from, to, prices } = req.body;
    const route = await Route.create({ from, to, prices });
    res.status(201).json(route);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const updateRoute = async (req, res) => {
  try {
    const route = await Route.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!route) return res.status(404).json({ message: 'Route not found' });
    res.json(route);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

const deleteRoute = async (req, res) => {
  try {
    const route = await Route.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );
    if (!route) return res.status(404).json({ message: 'Route not found' });
    res.json({ message: 'Route removed' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

module.exports = { getAllRoutes, getRoute, createRoute, updateRoute, deleteRoute };
