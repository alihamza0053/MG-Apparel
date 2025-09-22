const mongoose = require('mongoose');

const pairSchema = new mongoose.Schema({
  mentor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  mentees: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  organization: { type: String },
});

module.exports = mongoose.model('Pair', pairSchema);
