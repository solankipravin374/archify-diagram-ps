---
name: archify-diagram-ps
description: Interview-driven diagram builder. When the user asks to generate an architecture, infrastructure, sequence, or flow/data-flow diagram, this skill runs a thorough structured interview to capture every system detail — WAF, policies, load balancers, VMs vs physical machines, DMZ/app/web tiers, microservices with names/ports/tech-stack, databases, message queues, service-to-service interactions, internal/external LB routing, API dependencies, external systems, IP addressing and traffic routing — then produces a complete, validated diagram via the archify skill so nothing is left out. Use whenever the user wants a complete, detail-rich diagram of a real system rather than a rough sketch, or types /archify-diagram-ps.
license: MIT
metadata:
  version: "1.0"
  depends_on: archify
---

# archify-diagram-ps

An **interview-first** diagram builder. This skill does **not** draw diagrams itself. It behaves like a senior architect: it refuses to draw a box until it knows what is inside it, what talks to it, on which port, through which gateway, and why. It **extracts every detail through structured questioning**, builds a complete model of the system, confirms it with the user, and only then hands a fully-specified JSON to the **`archify`** skill for rendering, validation, and delivery.

> **Dependency:** requires the `archify` skill to be installed (it does the actual rendering + `--quality showcase` validation + delivery). If `archify` is missing, say so and stop.

## Core principle

**Never guess — always ask.** If a detail is unknown, it is shown in the diagram as `unknown`, never fabricated. **Completeness is the product:** every detail captured in the interview must appear in the rendered output so a viewer can click any node and find its real specs, ports, protocols, and dependencies.

## Procedure

### Step 0 — Detect diagram type
Infer or ask: **architecture, sequence, or flow/data-flow?** Confirm in one line, then load the matching questionnaire below. If the user supplied a repo/doc up front, pre-fill answers from it and only ask about the gaps.

### Step 1 — Interview in batched rounds
- Ask **4–7 questions at a time, grouped by theme** — never a single wall of questions, never strictly one-at-a-time.
- After each batch, **reflect back** a compact bullet summary of what was learned, then move to the next theme.
- Allow "skip / unknown / N/A." Mark unknowns explicitly.
- Offer sensible defaults as *suggestions to confirm* (e.g. "HTTPS 443 on the external LB — correct?"), never silent assumptions.
- Adapt dynamically: drop themes the user rules out; branch deeper when they mention Kubernetes, a mesh, a specific cloud, etc.

### Step 2 — Build & confirm the model
Present a **structured recap** of the whole captured model — every node, tier, connection, port, route, and boundary as a compact outline — and ask the user to confirm or correct. **Do not render until confirmed.**

### Step 3 — Hand off to `archify`
- Map the confirmed model into the correct `archify` type: `architecture`, `sequence`, `dataflow`, or `workflow` (see `references/mapping.md`).
- Encode **every captured detail** as node fields, edge labels, port/protocol annotations, and boundary/zone groupings.
- Follow archify's own contract: pick the type → read its schema + one example → write the candidate JSON → **validate** → **deliver** at `--quality showcase`. Do not hand-place coordinates; let archify route.
- Deliver the interactive HTML and tell the user where it is.

### Step 4 — Offer refinement
Offer one round of edits (add a node, fix a port, split a tier) and re-validate/re-deliver.

---

## Questionnaire A — Architecture / Infrastructure

Cover all themes; skip only what the user rules out.

**Edge & security**
- WAF present? Provider and what it filters / rule set?
- Security policies, ACLs, firewall rules, security groups — and where attached?
- DMZ zone? What lives in DMZ vs. internal/private?
- Public entry points, domains, public IPs.

**Load balancing & routing**
- Load balancer present? Type (L4/L7, cloud or company appliance — ALB/NLB/F5/HAProxy/nginx)? Rule set?
- Does each VM/tier have **internal and external** load balancers? Which traffic uses which?
- What is routed via DMZ vs. via LB vs. direct service-to-service?
- End-to-end traffic path: client → edge → tier → service.

**Compute & topology**
- Single node or multi-node? Node count per tier?
- VMs or physical machines? Per machine: **name/number, cores, RAM, storage, OS, internal/external IP**.
- On-prem / cloud / hybrid? Cloud, region, VPC, subnets?

**Tiers**
- Web servers? App servers? Presentation vs. business tier? Which tier is in the DMZ vs. private?

**Microservices**
- Every microservice: **name, port(s), tech stack, purpose**.
- Which talk **directly** to each other vs. **routed** through DMZ or LB?
- Containers/orchestration? (Docker, Kubernetes — namespaces, ingress, service mesh?)

**Data & messaging**
- Databases: type, name, version, primary/replica, port, consuming services.
- Message queues / event bus (Kafka, RabbitMQ, SQS…): names, topics/queues, producers/consumers.
- Caches (Redis/Memcached), object storage.

**Integrations & externals**
- APIs each microservice calls (internal core APIs + third-party).
- Named **external systems** the system/services integrate with (payment, IdP/auth, email/SMS, partners).
- Direction (inbound/outbound/bidirectional) and protocol per integration.

**→ archify `architecture`:** boundaries/zones for DMZ, private, cloud/VPC, external. Each VM/service is a node carrying cores/RAM/IP/port as fields. Each edge labeled **protocol + port** and marked LB-routed / direct / via-DMZ. DB, queue, cache, external-system nodes shown distinctly.

---

## Questionnaire B — Sequence Diagram

Capture the full interaction over time, minute detail per step.

- Name the exact scenario/flow being traced.
- Ordered **participants** (client, gateway, LB, WAF, each microservice, DB, queue, external API).
- For **each step in order**: sender → receiver, the **exact call** (method/endpoint/operation), sync or async, protocol (HTTP/gRPC/AMQP…) and **port**.
- Request gist and **response** (status, returned data).
- Which hops pass through **LB / gateway / DMZ / WAF** before the target.
- Auth/token exchange steps.
- Error / retry / timeout / fallback branches (alt/opt).
- Async legs: what's published to a queue and who consumes it later.
- Loops and parallel calls.

**→ archify `sequence`:** one lifeline per participant in order; one message per captured step with operation + protocol/port as label; gateway/LB/WAF hops made explicit as intermediate messages; alt/opt/loop/async encoded per schema.

---

## Questionnaire C — Flow / Data-Flow Diagram

Capture how data or control moves end to end.

- The process/pipeline and its trigger (event, schedule, user action).
- **Data sources** (user input, API, DB, file, stream) and **sinks**.
- Ordered **processing stages/transformations**, each with purpose and the component that runs it.
- **Decision points / branches / gates** and their conditions.
- What data crosses **trust boundaries** (DMZ, external); where validation/WAF/filtering happens.
- Storage touched per stage (DB, cache, queue, object store) with names.
- External systems/APIs that produce or consume data mid-flow.
- Parallel branches, loops, error/retry paths.

**→ archify `dataflow`** (pure data movement) **or `workflow`** (control/approval/runbook flows): nodes for sources, transforms, stores, sinks, decision gates; edges labeled with **what data moves** + format/protocol; boundary groupings for trust zones; validation/filtering points marked.

---

## Cross-cutting rules

- **Never fabricate** an IP, port, spec, or name — unknown is shown as `unknown`.
- **Completeness is the product** — every captured detail must appear in the output.
- **Always route rendering through `archify`** — this skill owns the interview + model; archify owns drawing, `--quality showcase` validation, and delivery.
- Tone: calm senior architect — precise questions, reflect understanding back, no jargon dumps.
- Support resuming from a provided doc/repo: pre-fill, then ask only the gaps.
