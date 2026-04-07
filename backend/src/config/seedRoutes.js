const Route = require('../models/Route');

const defaultRoutes = [
  // Visakhapatnam (Vizag)
  { from: 'Visakhapatnam', to: 'Visakhapatnam Airport', prices: [
    { seaterCapacity: 4, isCNG: false, price: 800 },
    { seaterCapacity: 4, isCNG: true,  price: 600 },
    { seaterCapacity: 6, isCNG: false, price: 1200 },
    { seaterCapacity: 6, isCNG: true,  price: 1000 },
    { seaterCapacity: 7, isCNG: false, price: 1400 },
  ]},
  { from: 'Visakhapatnam Airport', to: 'Visakhapatnam', prices: [
    { seaterCapacity: 4, isCNG: false, price: 800 },
    { seaterCapacity: 4, isCNG: true,  price: 600 },
    { seaterCapacity: 6, isCNG: false, price: 1200 },
    { seaterCapacity: 6, isCNG: true,  price: 1000 },
    { seaterCapacity: 7, isCNG: false, price: 1400 },
  ]},
  { from: 'Visakhapatnam', to: 'Rajahmundry', prices: [
    { seaterCapacity: 4, isCNG: false, price: 2500 },
    { seaterCapacity: 4, isCNG: true,  price: 2000 },
    { seaterCapacity: 6, isCNG: false, price: 3500 },
    { seaterCapacity: 6, isCNG: true,  price: 3000 },
    { seaterCapacity: 7, isCNG: false, price: 4000 },
  ]},
  { from: 'Visakhapatnam', to: 'Kakinada', prices: [
    { seaterCapacity: 4, isCNG: false, price: 3000 },
    { seaterCapacity: 4, isCNG: true,  price: 2400 },
    { seaterCapacity: 6, isCNG: false, price: 4200 },
    { seaterCapacity: 6, isCNG: true,  price: 3600 },
    { seaterCapacity: 7, isCNG: false, price: 4800 },
  ]},
  { from: 'Visakhapatnam', to: 'Vijayawada', prices: [
    { seaterCapacity: 4, isCNG: false, price: 4500 },
    { seaterCapacity: 4, isCNG: true,  price: 3600 },
    { seaterCapacity: 6, isCNG: false, price: 6300 },
    { seaterCapacity: 6, isCNG: true,  price: 5400 },
    { seaterCapacity: 7, isCNG: false, price: 7200 },
  ]},
  { from: 'Visakhapatnam', to: 'Araku Valley', prices: [
    { seaterCapacity: 4, isCNG: false, price: 2000 },
    { seaterCapacity: 4, isCNG: true,  price: 1600 },
    { seaterCapacity: 6, isCNG: false, price: 2800 },
    { seaterCapacity: 6, isCNG: true,  price: 2400 },
    { seaterCapacity: 7, isCNG: false, price: 3200 },
  ]},

  // Vijayawada
  { from: 'Vijayawada', to: 'Vijayawada Airport (Gannavaram)', prices: [
    { seaterCapacity: 4, isCNG: false, price: 500 },
    { seaterCapacity: 4, isCNG: true,  price: 400 },
    { seaterCapacity: 6, isCNG: false, price: 700 },
    { seaterCapacity: 6, isCNG: true,  price: 600 },
    { seaterCapacity: 7, isCNG: false, price: 800 },
  ]},
  { from: 'Vijayawada Airport (Gannavaram)', to: 'Vijayawada', prices: [
    { seaterCapacity: 4, isCNG: false, price: 500 },
    { seaterCapacity: 4, isCNG: true,  price: 400 },
    { seaterCapacity: 6, isCNG: false, price: 700 },
    { seaterCapacity: 6, isCNG: true,  price: 600 },
    { seaterCapacity: 7, isCNG: false, price: 800 },
  ]},
  { from: 'Vijayawada', to: 'Hyderabad', prices: [
    { seaterCapacity: 4, isCNG: false, price: 4000 },
    { seaterCapacity: 4, isCNG: true,  price: 3200 },
    { seaterCapacity: 6, isCNG: false, price: 5600 },
    { seaterCapacity: 6, isCNG: true,  price: 4800 },
    { seaterCapacity: 7, isCNG: false, price: 6400 },
  ]},
  { from: 'Vijayawada', to: 'Guntur', prices: [
    { seaterCapacity: 4, isCNG: false, price: 600 },
    { seaterCapacity: 4, isCNG: true,  price: 500 },
    { seaterCapacity: 6, isCNG: false, price: 850 },
    { seaterCapacity: 6, isCNG: true,  price: 700 },
    { seaterCapacity: 7, isCNG: false, price: 1000 },
  ]},
  { from: 'Vijayawada', to: 'Amaravati', prices: [
    { seaterCapacity: 4, isCNG: false, price: 400 },
    { seaterCapacity: 4, isCNG: true,  price: 350 },
    { seaterCapacity: 6, isCNG: false, price: 600 },
    { seaterCapacity: 6, isCNG: true,  price: 500 },
    { seaterCapacity: 7, isCNG: false, price: 700 },
  ]},
  { from: 'Vijayawada', to: 'Tirupati', prices: [
    { seaterCapacity: 4, isCNG: false, price: 5500 },
    { seaterCapacity: 4, isCNG: true,  price: 4400 },
    { seaterCapacity: 6, isCNG: false, price: 7700 },
    { seaterCapacity: 6, isCNG: true,  price: 6600 },
    { seaterCapacity: 7, isCNG: false, price: 8800 },
  ]},

  // Tirupati
  { from: 'Tirupati', to: 'Tirupati Airport (Renigunta)', prices: [
    { seaterCapacity: 4, isCNG: false, price: 400 },
    { seaterCapacity: 4, isCNG: true,  price: 350 },
    { seaterCapacity: 6, isCNG: false, price: 600 },
    { seaterCapacity: 6, isCNG: true,  price: 500 },
    { seaterCapacity: 7, isCNG: false, price: 700 },
  ]},
  { from: 'Tirupati Airport (Renigunta)', to: 'Tirupati', prices: [
    { seaterCapacity: 4, isCNG: false, price: 400 },
    { seaterCapacity: 4, isCNG: true,  price: 350 },
    { seaterCapacity: 6, isCNG: false, price: 600 },
    { seaterCapacity: 6, isCNG: true,  price: 500 },
    { seaterCapacity: 7, isCNG: false, price: 700 },
  ]},
  { from: 'Tirupati', to: 'Tirumala', prices: [
    { seaterCapacity: 4, isCNG: false, price: 500 },
    { seaterCapacity: 4, isCNG: true,  price: 400 },
    { seaterCapacity: 6, isCNG: false, price: 700 },
    { seaterCapacity: 6, isCNG: true,  price: 600 },
    { seaterCapacity: 7, isCNG: false, price: 800 },
  ]},
  { from: 'Tirupati', to: 'Chennai', prices: [
    { seaterCapacity: 4, isCNG: false, price: 2500 },
    { seaterCapacity: 4, isCNG: true,  price: 2000 },
    { seaterCapacity: 6, isCNG: false, price: 3500 },
    { seaterCapacity: 6, isCNG: true,  price: 3000 },
    { seaterCapacity: 7, isCNG: false, price: 4000 },
  ]},
  { from: 'Tirupati', to: 'Nellore', prices: [
    { seaterCapacity: 4, isCNG: false, price: 2000 },
    { seaterCapacity: 4, isCNG: true,  price: 1600 },
    { seaterCapacity: 6, isCNG: false, price: 2800 },
    { seaterCapacity: 6, isCNG: true,  price: 2400 },
    { seaterCapacity: 7, isCNG: false, price: 3200 },
  ]},

  // Rajahmundry
  { from: 'Rajahmundry', to: 'Rajahmundry Airport', prices: [
    { seaterCapacity: 4, isCNG: false, price: 400 },
    { seaterCapacity: 4, isCNG: true,  price: 350 },
    { seaterCapacity: 6, isCNG: false, price: 600 },
    { seaterCapacity: 6, isCNG: true,  price: 500 },
    { seaterCapacity: 7, isCNG: false, price: 700 },
  ]},
  { from: 'Rajahmundry Airport', to: 'Rajahmundry', prices: [
    { seaterCapacity: 4, isCNG: false, price: 400 },
    { seaterCapacity: 4, isCNG: true,  price: 350 },
    { seaterCapacity: 6, isCNG: false, price: 600 },
    { seaterCapacity: 6, isCNG: true,  price: 500 },
    { seaterCapacity: 7, isCNG: false, price: 700 },
  ]},
  { from: 'Rajahmundry', to: 'Kakinada', prices: [
    { seaterCapacity: 4, isCNG: false, price: 600 },
    { seaterCapacity: 4, isCNG: true,  price: 500 },
    { seaterCapacity: 6, isCNG: false, price: 850 },
    { seaterCapacity: 6, isCNG: true,  price: 700 },
    { seaterCapacity: 7, isCNG: false, price: 1000 },
  ]},
  { from: 'Rajahmundry', to: 'Vijayawada', prices: [
    { seaterCapacity: 4, isCNG: false, price: 2200 },
    { seaterCapacity: 4, isCNG: true,  price: 1800 },
    { seaterCapacity: 6, isCNG: false, price: 3100 },
    { seaterCapacity: 6, isCNG: true,  price: 2600 },
    { seaterCapacity: 7, isCNG: false, price: 3500 },
  ]},

  // Kakinada
  { from: 'Kakinada', to: 'Rajahmundry', prices: [
    { seaterCapacity: 4, isCNG: false, price: 500 },
    { seaterCapacity: 4, isCNG: true,  price: 600 },
    { seaterCapacity: 6, isCNG: false, price: 700 },
    { seaterCapacity: 6, isCNG: true,  price: 700 },
    { seaterCapacity: 7, isCNG: false, price: 800 },
  ]},
  { from: 'Kakinada', to: 'Rajahmundry Airport', prices: [
    { seaterCapacity: 4, isCNG: false, price: 700 },
    { seaterCapacity: 4, isCNG: true,  price: 550 },
    { seaterCapacity: 6, isCNG: false, price: 1000 },
    { seaterCapacity: 6, isCNG: true,  price: 850 },
    { seaterCapacity: 7, isCNG: false, price: 1100 },
  ]},
  { from: 'Kakinada', to: 'Vijayawada', prices: [
    { seaterCapacity: 4, isCNG: false, price: 2500 },
    { seaterCapacity: 4, isCNG: true,  price: 2000 },
    { seaterCapacity: 6, isCNG: false, price: 3500 },
    { seaterCapacity: 6, isCNG: true,  price: 3000 },
    { seaterCapacity: 7, isCNG: false, price: 4000 },
  ]},
  { from: 'Kakinada', to: 'Visakhapatnam Airport', prices: [
    { seaterCapacity: 4, isCNG: false, price: 3200 },
    { seaterCapacity: 4, isCNG: true,  price: 2600 },
    { seaterCapacity: 6, isCNG: false, price: 4500 },
    { seaterCapacity: 6, isCNG: true,  price: 3800 },
    { seaterCapacity: 7, isCNG: false, price: 5100 },
  ]},

  // Other intercity
  { from: 'Guntur', to: 'Vijayawada Airport (Gannavaram)', prices: [
    { seaterCapacity: 4, isCNG: false, price: 700 },
    { seaterCapacity: 4, isCNG: true,  price: 550 },
    { seaterCapacity: 6, isCNG: false, price: 1000 },
    { seaterCapacity: 6, isCNG: true,  price: 850 },
    { seaterCapacity: 7, isCNG: false, price: 1100 },
  ]},
  { from: 'Nellore', to: 'Tirupati Airport (Renigunta)', prices: [
    { seaterCapacity: 4, isCNG: false, price: 2200 },
    { seaterCapacity: 4, isCNG: true,  price: 1800 },
    { seaterCapacity: 6, isCNG: false, price: 3100 },
    { seaterCapacity: 6, isCNG: true,  price: 2600 },
    { seaterCapacity: 7, isCNG: false, price: 3500 },
  ]},
  { from: 'Kurnool', to: 'Hyderabad', prices: [
    { seaterCapacity: 4, isCNG: false, price: 3500 },
    { seaterCapacity: 4, isCNG: true,  price: 2800 },
    { seaterCapacity: 6, isCNG: false, price: 4900 },
    { seaterCapacity: 6, isCNG: true,  price: 4200 },
    { seaterCapacity: 7, isCNG: false, price: 5600 },
  ]},
  { from: 'Anantapur', to: 'Bangalore', prices: [
    { seaterCapacity: 4, isCNG: false, price: 3000 },
    { seaterCapacity: 4, isCNG: true,  price: 2400 },
    { seaterCapacity: 6, isCNG: false, price: 4200 },
    { seaterCapacity: 6, isCNG: true,  price: 3600 },
    { seaterCapacity: 7, isCNG: false, price: 4800 },
  ]},
];

const seedRoutes = async () => {
  const count = await Route.countDocuments();
  if (count > 0) return;

  await Route.insertMany(defaultRoutes);
  console.log(`Seeded ${defaultRoutes.length} Andhra Pradesh routes`);
};

module.exports = seedRoutes;
