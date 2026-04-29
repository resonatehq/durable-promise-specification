# Durable Promise Specification

> **Note:** This specification has been folded into the broader Distributed Async Await Specification. The canonical version is now maintained in the [distributed-async-await.io specification repo](https://github.com/resonatehq/distributed-async-await.io/blob/main/docs/specification/programming-model/durable-promise-specification.mdx). This repository is preserved for historical reference.

## What is a Durable Promise?

A Durable Promise is a language-agnostic, persistent representation of an asynchronous computation. Unlike an in-memory promise or future, a Durable Promise survives process crashes, restarts, and network partitions — its state is stored externally and can be observed or completed by any process that holds its identifier.

The Durable Promise Specification defines the data model, state machine, and HTTP API contract that any conforming implementation must satisfy. It is the foundation on which the [Resonate](https://resonatehq.io) durable execution framework is built.

## Why does it exist?

Distributed systems commonly need a way to represent "a computation that may not have finished yet" across process boundaries and time. Existing primitives (OS threads, language-level promises, message queues) either do not survive failures or require significant infrastructure to make durable.

The Durable Promise Specification fills this gap by defining a minimal, HTTP-native primitive that:

- Persists its state (pending, resolved, rejected) independently of any single process
- Allows multiple callers to await the same computation without duplicating work (idempotent creation)
- Can be completed by any process — not just the one that created it
- Carries structured result data and metadata tags

## How to read the spec

The specification describes:

1. **Data model** — the fields a Durable Promise record must contain (id, state, value, tags, timeout, etc.)
2. **State machine** — the valid state transitions (pending → resolved, pending → rejected, pending → timed out)
3. **HTTP API** — the endpoints and request/response shapes a conforming server must expose

Start with the state machine section to understand the lifecycle, then read the HTTP API section to see how promises are created, completed, and queried.

The canonical specification document is at:
[distributed-async-await.io — Durable Promise Specification](https://github.com/resonatehq/distributed-async-await.io/blob/main/docs/specification/programming-model/durable-promise-specification.mdx)

## Test harness

A historical conformance test suite paired with the legacy Go server is preserved at [github.com/resonatehq/legacy-durable-promise-test-harness](https://github.com/resonatehq/legacy-durable-promise-test-harness). It is archived and exercises the legacy REST API; the current Resonate server uses an RPC envelope contract not covered by this harness.

## SDKs that implement this specification

The following SDKs implement the Durable Promise Specification and work with any conforming server:

- [TypeScript SDK](https://github.com/resonatehq/resonate-sdk-ts)
- [Python SDK](https://github.com/resonatehq/resonate-sdk-py)

## Learn more

- [distributed-async-await.io](https://distributed-async-await.io) — the broader programming model that Durable Promises underpin
- [Resonate Server](https://github.com/resonatehq/resonate) — the reference implementation of this specification
- [ResonateHQ documentation](https://docs.resonatehq.io)
