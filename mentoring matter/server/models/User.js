const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['admin', 'mentor', 'mentee'], required: true },
  organization: { type: String },
});

module.exports = mongoose.model('User', userSchema);
