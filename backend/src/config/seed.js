const bcrypt = require('bcryptjs');
const User = require('../models/User');

const seedAdmin = async () => {
  const existing = await User.findOne({ role: 'admin' });
  if (existing) return;

  const passwordHash = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);
  await User.create({
    name: process.env.ADMIN_NAME,
    email: process.env.ADMIN_EMAIL,
    phone: process.env.ADMIN_PHONE,
    passwordHash,
    role: 'admin',
  });
  console.log(`Admin seeded: ${process.env.ADMIN_EMAIL}`);
};

module.exports = seedAdmin;
