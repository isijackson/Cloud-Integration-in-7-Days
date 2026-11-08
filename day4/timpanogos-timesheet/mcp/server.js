// A Model Context Protocol server that exposes the Timpanogos timesheet API as three agent tools.
// MCP is the 2026 standard for letting AI agents call tools; it moved to the Linux Foundation's
// Agentic AI Foundation in December 2025 with AWS, Google, Microsoft and Cloudflare as members.
// Run with the API reachable at TIMESHEET_API (default http://localhost:5000), then connect any
// MCP-capable client (Gemini CLI, GitHub Copilot CLI, Claude Code, Kiro, Antigravity) over stdio.
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const API = process.env.TIMESHEET_API || "http://localhost:5000";
const server = new McpServer({ name: "timpanogos-timesheet", version: "1.0.0" });

server.registerTool("list_visits", {
  title: "List visits",
  description: "List every visit entry on the timesheet (nurse, patient CODE, date, hours). No patient names exist.",
  inputSchema: {},
}, async () => {
  const r = await fetch(`${API}/api/timesheet`);
  const rows = await r.json();
  return { content: [{ type: "text", text: JSON.stringify(rows, null, 2) }] };
});

server.registerTool("add_visit", {
  title: "Add a visit",
  description: "Record a visit. patientCode must be a code such as P-1042, never a patient name.",
  inputSchema: {
    nurseName: z.string().min(1),
    patientCode: z.string().regex(/^P-\d{3,}$/, "use a patient code like P-1042"),
    visitDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    hours: z.number().positive().max(24),
  },
}, async (args) => {
  const r = await fetch(`${API}/api/timesheet`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(args) });
  const body = await r.json();
  return { content: [{ type: "text", text: r.ok ? `saved (${body.saved} entries now)` : `rejected: ${body.error}` }], isError: !r.ok };
});

server.registerTool("hours_by_nurse", {
  title: "Hours by nurse",
  description: "Total hours per nurse for payroll, computed from the timesheet.",
  inputSchema: {},
}, async () => {
  const rows = await (await fetch(`${API}/api/timesheet`)).json();
  const totals = {};
  for (const v of rows) totals[v.nurseName] = (totals[v.nurseName] || 0) + Number(v.hours);
  return { content: [{ type: "text", text: JSON.stringify(totals, null, 2) }] };
});

const transport = new StdioServerTransport();
await server.connect(transport);
