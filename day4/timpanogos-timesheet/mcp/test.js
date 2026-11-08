// Drives the MCP server as a client would: list tools, add a visit, list visits, total hours.
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
const transport = new StdioClientTransport({ command: "node", args: ["server.js"], env: { ...process.env } });
const client = new Client({ name: "it360-test", version: "1.0.0" });
await client.connect(transport);
const tools = await client.listTools();
console.log("tools:", tools.tools.map(t => t.name).join(", "));
console.log("add_visit:", (await client.callTool({ name: "add_visit", arguments: { nurseName: "R. Alder", patientCode: "P-1042", visitDate: "2026-11-10", hours: 1.5 } })).content[0].text);
const bad = await client.callTool({ name: "add_visit", arguments: { nurseName: "R. Alder", patientCode: "Jane Doe", visitDate: "2026-11-10", hours: 1 } });
console.log("add_visit with a patient NAME:", bad.isError ? "rejected by the schema (good)" : "accepted (bad)");
console.log("list_visits:", (await client.callTool({ name: "list_visits", arguments: {} })).content[0].text.replace(/\s+/g, " "));
console.log("hours_by_nurse:", (await client.callTool({ name: "hours_by_nurse", arguments: {} })).content[0].text.replace(/\s+/g, " "));
await client.close();
