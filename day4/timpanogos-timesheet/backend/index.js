const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.json());
const timesheets = [];
app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.post('/api/timesheet', (req, res) => {
  const { nurseName, patientCode, visitDate, hours } = req.body;
  if (!nurseName || !patientCode || !visitDate || !hours) {
    return res.status(400).json({ error:
      'nurseName, patientCode, visitDate and hours are required' });
  }
  timesheets.push({ nurseName, patientCode, visitDate, hours: Number(hours) });
  res.status(201).json({ saved: timesheets.length });
});
app.get('/api/timesheet', (req, res) => res.json(timesheets));
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Timesheet API on port ${PORT}`));
