# Field mapping: interview model → archify schema

This note maps captured interview facts onto `archify` schema fields. Always read the actual `schemas/<type>.schema.json` + `schemas/common.schema.json` and one `examples/<type>*.json` from the installed `archify` skill before authoring — those are the source of truth for exact field names. Use this note for *intent*, not exact key names.

## General handoff contract (from archify)

1. Choose type: `architecture` | `sequence` | `dataflow` | `workflow` | `lifecycle`.
2. Read the matching schema + common schema + one matching example.
3. Write the candidate JSON with fresh stable IDs and domain wording. Set `meta.quality_profile: "showcase"`.
4. Validate: `node bin/archify.mjs validate <type> <candidate.json> --quality showcase --json` → must report all 9 artifact checks, 0 errors, 0 warnings.
5. Deliver: `node bin/archify.mjs deliver <type> <candidate.json> <output.html> --quality showcase --json`.
6. Do not hand-place coordinates. Add at most one diagnosed geometry control per repair, only when a diagnostic calls for it.

## Architecture

| Interview fact | archify representation |
|---|---|
| DMZ / private / VPC / external zones | boundary/group container nodes |
| VM or physical machine | node; cores, RAM, storage, OS, internal/external IP as description/annotation fields |
| Microservice | node; name + purpose as label, tech stack + port(s) in fields |
| WAF / firewall / policies | edge-guard node at the edge boundary; filtering summary in its fields |
| Load balancer (internal/external) | node; edges through it labeled with the LB and its rule |
| Direct vs LB vs DMZ routing | edge label / style distinguishing `direct`, `via-LB`, `via-DMZ` |
| Protocol + port on a link | edge label, e.g. `HTTPS:443`, `gRPC:50051`, `AMQP:5672` |
| Database / cache / object store | distinct node type; port + version in fields; edges from consuming services |
| Message queue / event bus | node; topics/queues in fields; producer/consumer edges directional |
| External system integration | external-zone node; edge direction = inbound/outbound/bidirectional |
| Unknown value | literal `unknown` in the field — never a fabricated number |

## Sequence

| Interview fact | archify representation |
|---|---|
| Participant/actor/system | one lifeline, ordered as stated |
| Step (sender → receiver) | one message between lifelines |
| Exact call + protocol + port | message label, e.g. `POST /pay  HTTPS:443` |
| Response | return message with status/data |
| LB / gateway / DMZ / WAF hop | explicit intermediate messages — never hidden |
| Auth/token exchange | its own messages |
| Error/retry/timeout | alt/opt fragment |
| Async publish/consume | async message + later consume message |
| Loop / parallel | loop / par fragment per schema |

## Flow / data-flow

| Interview fact | archify representation |
|---|---|
| Data source / sink | source / sink node |
| Processing stage/transform | process node; running component in fields |
| Decision / gate | decision node; condition on outgoing edges |
| Data moving on a link | edge label = payload + format/protocol |
| Trust boundary crossing | boundary group; validation/filter point marked |
| Storage touched | store node with name |
| External producer/consumer | external node, directional edge |
| Control/approval/runbook flow | use `workflow` type instead of `dataflow` |
