const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connected successfully');
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    // For development, continue without MongoDB if it's not available
    console.log('Continuing without MongoDB for development...');
  }
};

module.exports = connectDB;
