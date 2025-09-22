const mongoose = require('mongoose');

const materialSchema = new mongoose.Schema({
  pair: { type: mongoose.Schema.Types.ObjectId, ref: 'Pair', required: true },
  mentor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  url: { type: String },
  document: { type: String }, // file path or cloud link
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Material', materialSchema);
