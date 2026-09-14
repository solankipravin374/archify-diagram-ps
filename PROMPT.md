# Build Skill: `archify-diagram-ps`

> **How to use this file:** Paste the entire contents of this file into Claude Code (or Claude) and say:
> *"Create this skill exactly as specified."*
> Claude will scaffold the skill files (`SKILL.md` + supporting references) into your skills directory. This skill is an **interview-first wrapper around the existing [`archify`](https://github.com/tt-a1i/archify) skill** — install `archify` first (it does the actual rendering).

---

## Goal

Create a Claude skill named **`archify-diagram-ps`**.

The skill's job is **not** to draw diagrams directly. Its job is to be a **relentless technical interviewer** that extracts *every* detail of a system from the user through structured questioning, builds a complete internal model of the system, and only *then* hands a fully-specified JSON off to the **`archify`** skill to render an interactive HTML diagram.

The core principle: **never guess, always ask.** A senior architect does not draw a box until they know what's inside it, what talks to it, on which port, through which gateway, and why. The skill should behave the same way.

It must support three diagram families, each with its own tailored questionnaire:

1. **Architecture / infrastructure diagram**
2. **Sequence diagram**
3. **Flow / data-flow diagram**

---

## Trigger & description

**`name`:** `archify-diagram-ps`

**`description`** (write it so Claude auto-invokes on intent, not just the exact word):
> Interview-driven diagram builder. When the user asks to generate an architecture, infrastructure, sequence, or flow/data-flow diagram, this skill runs a thorough structured interview to capture every system detail — WAF, policies, load balancers, VMs vs physical machines, DMZ/app/web tiers, microservices with names/ports/tech-stack, databases, message queues, service-to-service interactions, internal/external LB routing, API dependencies, external systems, IP addressing and traffic routing — then produces a complete, validated diagram via the `archify` skill so nothing is left out. Use whenever the user wants a *complete, detail-rich* diagram of a real system rather than a rough sketch.

**Also invoke** when the user types `/archify-diagram-ps` or says things like *"map my whole system," "document our infra as a diagram," "full sequence diagram for this flow."*

---

## Required behavior (the interview engine)

### Step 0 — Detect diagram type
Ask (or infer, then confirm): **architecture, sequence, or flow/data-flow?** Load the matching questionnaire below. Confirm the diagram type in one line before interviewing.

### Step 1 — Interview in batched rounds
- Ask questions in **small grouped batches (4–7 at a time)**, not one giant wall and not one-at-a-time. Group by theme (e.g. "Networking & edge," then "Compute," then "Services").
- After each batch, **reflect back** what was learned in a compact bullet summary, then continue to the next theme.
- Let the user answer partially or say *"skip / unknown / N/A."* Mark unknowns explicitly — never invent a value. If a field is unknown, the diagram must show it as `unknown` rather than a fabricated IP/port/spec.
- Offer **sensible defaults as suggestions** the user can accept (e.g. "HTTPS 443 on the external LB — correct?") but never silently assume.
- Adapt: if the user says "no message queues," skip the queue questions. If they mention Kubernetes, branch into pod/namespace/ingress questions.

### Step 2 — Build & confirm the model
Before rendering, present a **structured recap** of the entire captured model (a compact outline of every node, tier, connection, port, and route) and ask the user to confirm or correct. Do not render until confirmed.

### Step 3 — Hand off to `archify`
- Map the confirmed model into the correct `archify` JSON spec (`architecture`, `sequence`, or `dataflow`).
- Encode **every captured detail** as node fields, edge labels, port annotations, and boundary/zone groupings — the whole point is that the viewer can find *everything* in the rendered diagram.
- Follow archify's own contract: pick the type, read its schema + one example, write the candidate JSON, then **validate** and **deliver** at `--quality showcase`. Do not hand-place coordinates; let archify's layout engine route.
- Deliver the interactive HTML and tell the user where it is.

### Step 4 — Offer refinement
Offer one round of edits ("add a node, fix a port, split a tier") and re-validate.

---

## Questionnaire A — Architecture / Infrastructure

Ask across these themes. Cover **all** of these; skip only what the user rules out.

**Edge & security**
- Is there a WAF? What does it filter / rule set / provider?
- Any security policies, ACLs, firewall rules, or SGs attached — and where?
- Is there a DMZ zone? What lives in it vs. the internal/private zone?
- Public entry points and the domains / public IPs.

**Load balancing & routing**
- Is there a load balancer? Type (L4/L7, cloud/company appliance, e.g. ALB/NLB/F5/HAProxy/nginx)? Rule set / routing rules?
- Does each VM/tier have **internal** and **external** load balancers? Which traffic goes through which?
- What is routed through the DMZ vs. through the LB vs. direct service-to-service?
- Overall **traffic routing** path from client → edge → tier → service.

**Compute & topology**
- Single node or multi-node? How many nodes per tier?
- VMs or physical machines? For each: name/number, cores, RAM, storage, OS, IP address (internal/external).
- Is it on-prem, cloud, or hybrid? Which cloud/region/VPC/subnets?

**Tiers**
- Web servers? App servers? Presentation vs. business tier?
- Which tier sits in the DMZ, which is private?

**Microservices**
- List every microservice: **name, port(s), tech stack, purpose**.
- Which services talk **directly** to each other, and which are **routed** through the DMZ or load balancer?
- Container/orchestration? (Docker, Kubernetes — namespaces, ingress, service mesh?)

**Data & messaging**
- Databases: type, name, version, primary/replica, port, which services use them.
- Message queues / event bus (Kafka, RabbitMQ, SQS, etc.): names, topics/queues, producers/consumers.
- Caches (Redis/Memcached), object storage.

**Integrations & externals**
- Which APIs does each microservice call (internal core APIs and third-party)?
- Names of **external systems** the whole system or individual services integrate with (payment, auth/IdP, email/SMS, partners).
- Direction of each integration (inbound / outbound / bidirectional) and protocol.

### Map into `archify` `architecture`
- Use **boundaries/zones** for DMZ, private, cloud/VPC, and external.
- Each VM/service becomes a node carrying its specs (cores/RAM/IP/port) as fields/annotations.
- Each connection is an edge labeled with **protocol + port** and marked LB-routed / direct / via-DMZ.
- Group microservices; show DB, queue, cache, and external-system nodes distinctly.

---

## Questionnaire B — Sequence Diagram

Capture the **full interaction over time**, minute detail per step.

- What is the exact scenario/flow being traced (name it)?
- The ordered list of **participants / actors / systems** (client, gateway, LB, WAF, each microservice, DB, queue, external API).
- For **each step, in order**: sender → receiver, the **exact call** (method/endpoint/operation), synchronous or asynchronous, protocol (HTTP/gRPC/AMQP/etc.) and **port**.
- Request payload gist and the **response** (status, returned data).
- Where does the call pass through the **LB / gateway / DMZ / WAF** before reaching the target?
- Auth/token exchange steps.
- Error / retry / timeout / fallback branches (alt/opt paths).
- Async legs: what's published to a queue and who consumes it later.
- Loops and parallel calls.

### Map into `archify` `sequence`
- One lifeline per participant in the stated order.
- One message per captured step with the operation + protocol/port as the label.
- Represent gateway/LB/WAF hops as explicit intermediate messages, not hidden.
- Encode alt/opt/loop/async as the schema supports.

---

## Questionnaire C — Flow / Data-Flow Diagram

Capture how **data or control moves** end to end.

- The process/pipeline being mapped and its trigger (event, schedule, user action).
- **Data sources** (where data originates: user input, API, DB, file, stream) and **sinks** (where it lands).
- Ordered **processing steps / stages / transformations**, each with its purpose and the component that runs it.
- **Decision points / branches / gates** and the condition on each.
- What data crosses **trust boundaries** (DMZ, external), and where validation/WAF/filtering happens.
- Storage touched at each stage (DB, cache, queue, object store) with names.
- External systems/APIs that produce or consume data mid-flow.
- Parallel branches, loops, and error/retry paths.

### Map into `archify` `dataflow` (or `workflow` for control/approval flows)
- Nodes for sources, transforms, stores, sinks, and decision gates.
- Edges labeled with **what data moves** and the format/protocol.
- Boundary groupings for trust zones; mark validation/filtering points.

---

## Cross-cutting rules for the skill

- **Never fabricate** an IP, port, spec, or name. Unknown = shown as `unknown`.
- **Completeness is the product.** The finished diagram must let a viewer click any node and find its real specs, ports, protocols, and dependencies. If a detail was captured, it must appear in the output.
- **Always route through `archify`** for rendering — this skill owns the interview and the model, `archify` owns the drawing, validation (`--quality showcase`), and delivery.
- Keep the tone that of a **calm senior architect**: precise questions, no jargon dumps, always reflecting understanding back.
- Support resuming: if the user provides a doc/repo up front, pre-fill answers from it and only ask about the gaps.

---

## Deliverables of this skill build

1. `SKILL.md` for `archify-diagram-ps` implementing everything above (frontmatter `name` + `description` as specified, the type router, the three questionnaires, the batched-interview + confirm + handoff flow).
2. A short `references/` note documenting the field-mapping from each questionnaire into the corresponding `archify` schema.
3. A one-line note in the skill that it depends on the `archify` skill being installed.

Build it now.
