const mongoose = require('mongoose');

const goalSchema = new mongoose.Schema({
  pair: { type: mongoose.Schema.Types.ObjectId, ref: 'Pair', required: true },
  title: { type: String, required: true },
  description: { type: String },
  status: { type: String, enum: ['Not Started', 'In Progress', 'Completed'], default: 'Not Started' },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Goal', goalSchema);
