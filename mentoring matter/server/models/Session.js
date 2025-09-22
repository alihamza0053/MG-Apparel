const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  pair: { type: mongoose.Schema.Types.ObjectId, ref: 'Pair', required: true },
  date: { type: Date, required: true },
  notes: { type: String },
});

module.exports = mongoose.model('Session', sessionSchema);
