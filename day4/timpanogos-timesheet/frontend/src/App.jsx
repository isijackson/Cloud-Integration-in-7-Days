import { useEffect, useState } from 'react';
export default function App() {
  const [form, setForm] = useState({ nurseName: '', patientCode: '', visitDate: '', hours: '' });
  const [records, setRecords] = useState([]);
  const [status, setStatus] = useState('');
  const load = () => fetch('/api/timesheet').then(r => r.json()).then(setRecords).catch(() => setStatus('Backend unreachable'));
  useEffect(() => { load(); }, []);
  const submit = async (e) => {
    e.preventDefault();
    try {
      const r = await fetch('/api/timesheet', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(form) });
      setStatus(r.ok ? 'Saved' : 'Rejected: ' + (await r.json()).error);
    } catch { setStatus('Backend unreachable'); }
    load();
  };
  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });
  return (
    <main style={{ fontFamily: 'sans-serif', maxWidth: 520, margin: '2rem auto' }}>
      <h1>Timpanogos Home Health — Visit Timesheet</h1>
      <form onSubmit={submit}>
        <input placeholder="Nurse" value={form.nurseName} onChange={set('nurseName')} />
        <input placeholder="Patient code (e.g. P-1042)" value={form.patientCode} onChange={set('patientCode')} />
        <input type="date" value={form.visitDate} onChange={set('visitDate')} />
        <input type="number" step="0.25" placeholder="Hours" value={form.hours} onChange={set('hours')} />
        <button>Submit visit</button>
      </form>
      <p>{status}</p>
      <ul>{records.map((r, i) => <li key={i}>{r.visitDate} · {r.nurseName} · {r.patientCode} · {r.hours} h</li>)}</ul>
    </main>
  );
}
