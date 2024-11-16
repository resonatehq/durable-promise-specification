# Durable Promise Specification

**Keywords**

*Promise, Future, Awaitable, Future Value, Write Once Register, Write Only Register, Single Assignment Container, Concurrency, Coordination*

**tl;dr** This repository is a specification for a Durable Promise API

20 years after the launch of Amazon Web Services, building reliable and scalable cloud-based applications is a challenge even for the most seasoned developers. Developing distributed applications is a dissonant mix of idioms, patterns, and technologies, feeling fragmented and inconsistent.
Yet developing traditional applications feels coherent and consistent. Developers who craft these applications have access to composable abstractions, functions & promises a.k.a async•await, and enjoy a delightful developer experience.

Even the largest traditional systems are built consistently from the smallest building blocks: functions & promises. Functions & promises are the foundational model to express concurrency and coordination. While their interpretations vary across languages and runtimes, the ideas are the same.

## Promises

A **promise**, also called future, awaitable, or deferred is a representation of a future value. A promise is either pending or completed, that is, resolved or rejected: A promise is pending, signaling that the value is not yet available or completed, signaling success or failure.

![Promise](./img/Promise.jpg)

A promise is a coordination primitive: In a typical scenario, a downstream function execution creates a promise and awaits its completion. An upstream function execution either resolves or rejects the promise. On completion, the downstream execution resumes with the value of the promise.

![Promise API](./img/PromiseAPI.jpg)

## Adding Durability

Recently, durable functions a.k.a durable executions have emerged as an abstraction for building distributed systems. Durable functions are functions with strong execution guarantees. Traditional, that is, volatile functions are bound to a single runtime. If the runtime crashes, any volatile function execution ceases to exist. Durable function executions are not bound to a runtime. If the runtime crashes, a durable function execution is simply rescheduled on a different runtime.

Durable promises are the counterpart to durable functions. Durable promises have identity and state that is not bound to a single runtime. Based on durable promises you can compose reliable and scalable distributed systems across heterogenous technology stacks.

## Application Programming Interface (API)

Logically, the Application Programming Interface (API) is divided in two parts, the Downstream API and the Upstream API.

## Downstream API

- **Create**

  A downstream component may create a promise.

  ```
  Create(promise-id, idempotency-key, param, header, timeout, strict)
  ```

- **Cancel**

  A downstream component can cancel an existing promise.

  ```
  Cancel(promise-id, idempotency-key, value, header, strict)
  ```

- **Callback**

  A downstream component can register a callback on an existing promise.

  ```
  Callback(promise-id, root-promise-id, timeout, recv)
  ```

  A recv specifies the transport on which the callback will occur. Below is a non-exhaustive list of supported receivers.

  | Type | Data                                               | Shorthand          |
  | ---- | -------------------------------------------------- | ------------------ |
  | poll | {"group": "string", "id": "string"}                | poll://group:id    |
  | http | {"headers": {"string": "string"}, "url": "string"} | http://example.com |

## Upstream API

- **Resolve**

  An upstream component can resolve an existing promise, signaling success.

  ```
  Resolve(promise-id, idempotency-key, value, header, strict)
  ```

- **Reject**

  An upstream component can reject a promise, signalling failure.

  ```
  Reject(promise-id, idempotency-key, value, header, strict)
  ```

# Idempotence

In a distributed system, managing duplicate and racing messages is essential. When creating, resolving, or rejecting a Durable Promise, use an idempotency key. An idempotency key is a client generated value which the server uses to recognize when two different physical requests represent the same logical request.

|     | Current State          | Action                 | Next State             | Output                 |
|-----|------------------------|------------------------|------------------------|------------------------|
| 1   | Init                   | Create(id, ⊥, T)       | Pending(id, ⊥, ⊥)      | OK                     |
| 2   | Init                   | Create(id, ⊥, F)       | Pending(id, ⊥, ⊥)      | OK                     |
| 3   | Init                   | Create(id, ikc, T)     | Pending(id, ikc, ⊥)    | OK                     |
| 4   | Init                   | Create(id, ikc, F)     | Pending(id, ikc, ⊥)    | OK                     |
| 5   | Init                   | Resolve(id, ⊥, T)      | Init                   | KO, Already Init       |
| 6   | Init                   | Resolve(id, ⊥, F)      | Init                   | KO, Already Init       |
| 7   | Init                   | Resolve(id, iku, T)    | Init                   | KO, Already Init       |
| 8   | Init                   | Resolve(id, iku, F)    | Init                   | KO, Already Init       |
| 9   | Init                   | Reject(id, ⊥, T)       | Init                   | KO, Already Init       |
| 10  | Init                   | Reject(id, ⊥, F)       | Init                   | KO, Already Init       |
| 11  | Init                   | Reject(id, iku, T)     | Init                   | KO, Already Init       |
| 12  | Init                   | Reject(id, iku, F)     | Init                   | KO, Already Init       |
| 13  | Init                   | Cancel(id, ⊥, T)       | Init                   | KO, Already Init       |
| 14  | Init                   | Cancel(id, ⊥, F)       | Init                   | KO, Already Init       |
| 15  | Init                   | Cancel(id, iku, T)     | Init                   | KO, Already Init       |
| 16  | Init                   | Cancel(id, iku, F)     | Init                   | KO, Already Init       |
| 17  | Pending(id, ⊥, ⊥)      | Create(id, ⊥, T)       | Pending(id, ⊥, ⊥)      | KO, Already Pending    |
| 18  | Pending(id, ⊥, ⊥)      | Create(id, ⊥, F)       | Pending(id, ⊥, ⊥)      | KO, Already Pending    |
| 19  | Pending(id, ⊥, ⊥)      | Create(id, ikc, T)     | Pending(id, ⊥, ⊥)      | KO, Already Pending    |
| 20  | Pending(id, ⊥, ⊥)      | Create(id, ikc, F)     | Pending(id, ⊥, ⊥)      | KO, Already Pending    |
| 21  | Pending(id, ⊥, ⊥)      | Resolve(id, ⊥, T)      | Resolved(id, ⊥, ⊥)     | OK                     |
| 22  | Pending(id, ⊥, ⊥)      | Resolve(id, ⊥, F)      | Resolved(id, ⊥, ⊥)     | OK                     |
| 23  | Pending(id, ⊥, ⊥)      | Resolve(id, iku, T)    | Resolved(id, ⊥, iku)   | OK                     |
| 24  | Pending(id, ⊥, ⊥)      | Resolve(id, iku, F)    | Resolved(id, ⊥, iku)   | OK                     |
| 25  | Pending(id, ⊥, ⊥)      | Reject(id, ⊥, T)       | Rejected(id, ⊥, ⊥)     | OK                     |
| 26  | Pending(id, ⊥, ⊥)      | Reject(id, ⊥, F)       | Rejected(id, ⊥, ⊥)     | OK                     |
| 27  | Pending(id, ⊥, ⊥)      | Reject(id, iku, T)     | Rejected(id, ⊥, iku)   | OK                     |
| 28  | Pending(id, ⊥, ⊥)      | Reject(id, iku, F)     | Rejected(id, ⊥, iku)   | OK                     |
| 29  | Pending(id, ⊥, ⊥)      | Cancel(id, ⊥, T)       | Canceled(id, ⊥, ⊥)     | OK                     |
| 30  | Pending(id, ⊥, ⊥)      | Cancel(id, ⊥, F)       | Canceled(id, ⊥, ⊥)     | OK                     |
| 31  | Pending(id, ⊥, ⊥)      | Cancel(id, iku, T)     | Canceled(id, ⊥, iku)   | OK                     |
| 32  | Pending(id, ⊥, ⊥)      | Cancel(id, iku, F)     | Canceled(id, ⊥, iku)   | OK                     |
| 33  | Pending(id, ikc, ⊥)    | Create(id, ⊥, T)       | Pending(id, ikc, ⊥)    | KO, Already Pending    |
| 34  | Pending(id, ikc, ⊥)    | Create(id, ⊥, F)       | Pending(id, ikc, ⊥)    | KO, Already Pending    |
| 35  | Pending(id, ikc, ⊥)    | Create(id, ikc, T)     | Pending(id, ikc, ⊥)    | OK, Deduplicated       |
| 36  | Pending(id, ikc, ⊥)    | Create(id, ikc, F)     | Pending(id, ikc, ⊥)    | OK, Deduplicated       |
| 37  | Pending(id, ikc, ⊥)    | Create(id, ikc*, T)    | Pending(id, ikc, ⊥)    | KO, Already Pending    |
| 38  | Pending(id, ikc, ⊥)    | Create(id, ikc*, F)    | Pending(id, ikc, ⊥)    | KO, Already Pending    |
| 39  | Pending(id, ikc, ⊥)    | Resolve(id, ⊥, T)      | Resolved(id, ikc, ⊥)   | OK                     |
| 40  | Pending(id, ikc, ⊥)    | Resolve(id, ⊥, F)      | Resolved(id, ikc, ⊥)   | OK                     |
| 41  | Pending(id, ikc, ⊥)    | Resolve(id, iku, T)    | Resolved(id, ikc, iku) | OK                     |
| 42  | Pending(id, ikc, ⊥)    | Resolve(id, iku, F)    | Resolved(id, ikc, iku) | OK                     |
| 43  | Pending(id, ikc, ⊥)    | Reject(id, ⊥, T)       | Rejected(id, ikc, ⊥)   | OK                     |
| 44  | Pending(id, ikc, ⊥)    | Reject(id, ⊥, F)       | Rejected(id, ikc, ⊥)   | OK                     |
| 45  | Pending(id, ikc, ⊥)    | Reject(id, iku, T)     | Rejected(id, ikc, iku) | OK                     |
| 46  | Pending(id, ikc, ⊥)    | Reject(id, iku, F)     | Rejected(id, ikc, iku) | OK                     |
| 47  | Pending(id, ikc, ⊥)    | Cancel(id, ⊥, T)       | Canceled(id, ikc, ⊥)   | OK                     |
| 48  | Pending(id, ikc, ⊥)    | Cancel(id, ⊥, F)       | Canceled(id, ikc, ⊥)   | OK                     |
| 49  | Pending(id, ikc, ⊥)    | Cancel(id, iku, T)     | Canceled(id, ikc, iku) | OK                     |
| 50  | Pending(id, ikc, ⊥)    | Cancel(id, iku, F)     | Canceled(id, ikc, iku) | OK                     |
| 51  | Resolved(id, ⊥, ⊥)     | Create(id, ⊥, T)       | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 52  | Resolved(id, ⊥, ⊥)     | Create(id, ⊥, F)       | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 53  | Resolved(id, ⊥, ⊥)     | Create(id, ikc, T)     | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 54  | Resolved(id, ⊥, ⊥)     | Create(id, ikc, F)     | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 55  | Resolved(id, ⊥, ⊥)     | Resolve(id, ⊥, T)      | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 56  | Resolved(id, ⊥, ⊥)     | Resolve(id, ⊥, F)      | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 57  | Resolved(id, ⊥, ⊥)     | Resolve(id, iku, T)    | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 58  | Resolved(id, ⊥, ⊥)     | Resolve(id, iku, F)    | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 59  | Resolved(id, ⊥, ⊥)     | Reject(id, ⊥, T)       | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 60  | Resolved(id, ⊥, ⊥)     | Reject(id, ⊥, F)       | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 61  | Resolved(id, ⊥, ⊥)     | Reject(id, iku, T)     | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 62  | Resolved(id, ⊥, ⊥)     | Reject(id, iku, F)     | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 63  | Resolved(id, ⊥, ⊥)     | Cancel(id, ⊥, T)       | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 64  | Resolved(id, ⊥, ⊥)     | Cancel(id, ⊥, F)       | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 65  | Resolved(id, ⊥, ⊥)     | Cancel(id, iku, T)     | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 66  | Resolved(id, ⊥, ⊥)     | Cancel(id, iku, F)     | Resolved(id, ⊥, ⊥)     | KO, Already Resolved   |
| 67  | Resolved(id, ⊥, iku)   | Create(id, ⊥, T)       | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 68  | Resolved(id, ⊥, iku)   | Create(id, ⊥, F)       | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 69  | Resolved(id, ⊥, iku)   | Create(id, ikc, T)     | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 70  | Resolved(id, ⊥, iku)   | Create(id, ikc, F)     | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 71  | Resolved(id, ⊥, iku)   | Resolve(id, ⊥, T)      | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 72  | Resolved(id, ⊥, iku)   | Resolve(id, ⊥, F)      | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 73  | Resolved(id, ⊥, iku)   | Resolve(id, iku, T)    | Resolved(id, ⊥, iku)   | OK, Deduplicated       |
| 74  | Resolved(id, ⊥, iku)   | Resolve(id, iku, F)    | Resolved(id, ⊥, iku)   | OK, Deduplicated       |
| 75  | Resolved(id, ⊥, iku)   | Resolve(id, iku*, T)   | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 76  | Resolved(id, ⊥, iku)   | Resolve(id, iku*, F)   | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 77  | Resolved(id, ⊥, iku)   | Reject(id, ⊥, T)       | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 78  | Resolved(id, ⊥, iku)   | Reject(id, ⊥, F)       | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 79  | Resolved(id, ⊥, iku)   | Reject(id, iku, T)     | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 80  | Resolved(id, ⊥, iku)   | Reject(id, iku, F)     | Resolved(id, ⊥, iku)   | OK, Deduplicated       |
| 81  | Resolved(id, ⊥, iku)   | Reject(id, iku*, T)    | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 82  | Resolved(id, ⊥, iku)   | Reject(id, iku*, F)    | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 83  | Resolved(id, ⊥, iku)   | Cancel(id, ⊥, T)       | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 84  | Resolved(id, ⊥, iku)   | Cancel(id, ⊥, F)       | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 85  | Resolved(id, ⊥, iku)   | Cancel(id, iku, T)     | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 86  | Resolved(id, ⊥, iku)   | Cancel(id, iku, F)     | Resolved(id, ⊥, iku)   | OK, Deduplicated       |
| 87  | Resolved(id, ⊥, iku)   | Cancel(id, iku*, T)    | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 88  | Resolved(id, ⊥, iku)   | Cancel(id, iku*, F)    | Resolved(id, ⊥, iku)   | KO, Already Resolved   |
| 89  | Resolved(id, ikc, ⊥)   | Create(id, ⊥, T)       | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 90  | Resolved(id, ikc, ⊥)   | Create(id, ⊥, F)       | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 91  | Resolved(id, ikc, ⊥)   | Create(id, ikc, T)     | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 92  | Resolved(id, ikc, ⊥)   | Create(id, ikc, F)     | Resolved(id, ikc, ⊥)   | OK, Deduplicated       |
| 93  | Resolved(id, ikc, ⊥)   | Create(id, ikc*, T)    | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 94  | Resolved(id, ikc, ⊥)   | Create(id, ikc*, F)    | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 95  | Resolved(id, ikc, ⊥)   | Resolve(id, ⊥, T)      | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 96  | Resolved(id, ikc, ⊥)   | Resolve(id, ⊥, F)      | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 97  | Resolved(id, ikc, ⊥)   | Resolve(id, iku, T)    | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 98  | Resolved(id, ikc, ⊥)   | Resolve(id, iku, F)    | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 99  | Resolved(id, ikc, ⊥)   | Reject(id, ⊥, T)       | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 100 | Resolved(id, ikc, ⊥)   | Reject(id, ⊥, F)       | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 101 | Resolved(id, ikc, ⊥)   | Reject(id, iku, T)     | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 102 | Resolved(id, ikc, ⊥)   | Reject(id, iku, F)     | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 103 | Resolved(id, ikc, ⊥)   | Cancel(id, ⊥, T)       | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 104 | Resolved(id, ikc, ⊥)   | Cancel(id, ⊥, F)       | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 105 | Resolved(id, ikc, ⊥)   | Cancel(id, iku, T)     | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 106 | Resolved(id, ikc, ⊥)   | Cancel(id, iku, F)     | Resolved(id, ikc, ⊥)   | KO, Already Resolved   |
| 107 | Resolved(id, ikc, iku) | Create(id, ⊥, T)       | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 108 | Resolved(id, ikc, iku) | Create(id, ⊥, F)       | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 109 | Resolved(id, ikc, iku) | Create(id, ikc, T)     | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 110 | Resolved(id, ikc, iku) | Create(id, ikc, F)     | Resolved(id, ikc, iku) | OK, Deduplicated       |
| 111 | Resolved(id, ikc, iku) | Create(id, ikc*, T)    | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 112 | Resolved(id, ikc, iku) | Create(id, ikc*, F)    | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 113 | Resolved(id, ikc, iku) | Resolve(id, ⊥, T)      | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 114 | Resolved(id, ikc, iku) | Resolve(id, ⊥, F)      | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 115 | Resolved(id, ikc, iku) | Resolve(id, iku, T)    | Resolved(id, ikc, iku) | OK, Deduplicated       |
| 116 | Resolved(id, ikc, iku) | Resolve(id, iku, F)    | Resolved(id, ikc, iku) | OK, Deduplicated       |
| 117 | Resolved(id, ikc, iku) | Resolve(id, iku*, T)   | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 118 | Resolved(id, ikc, iku) | Resolve(id, iku*, F)   | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 119 | Resolved(id, ikc, iku) | Reject(id, ⊥, T)       | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 120 | Resolved(id, ikc, iku) | Reject(id, ⊥, F)       | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 121 | Resolved(id, ikc, iku) | Reject(id, iku, T)     | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 122 | Resolved(id, ikc, iku) | Reject(id, iku, F)     | Resolved(id, ikc, iku) | OK, Deduplicated       |
| 123 | Resolved(id, ikc, iku) | Reject(id, iku*, T)    | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 124 | Resolved(id, ikc, iku) | Reject(id, iku*, F)    | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 125 | Resolved(id, ikc, iku) | Cancel(id, ⊥, T)       | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 126 | Resolved(id, ikc, iku) | Cancel(id, ⊥, F)       | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 127 | Resolved(id, ikc, iku) | Cancel(id, iku, T)     | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 128 | Resolved(id, ikc, iku) | Cancel(id, iku, F)     | Resolved(id, ikc, iku) | OK, Deduplicated       |
| 129 | Resolved(id, ikc, iku) | Cancel(id, iku*, T)    | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 130 | Resolved(id, ikc, iku) | Cancel(id, iku*, F)    | Resolved(id, ikc, iku) | KO, Already Resolved   |
| 131 | Rejected(id, ⊥, ⊥)     | Create(id, ⊥, T)       | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 132 | Rejected(id, ⊥, ⊥)     | Create(id, ⊥, F)       | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 133 | Rejected(id, ⊥, ⊥)     | Create(id, ikc, T)     | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 134 | Rejected(id, ⊥, ⊥)     | Create(id, ikc, F)     | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 135 | Rejected(id, ⊥, ⊥)     | Resolve(id, ⊥, T)      | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 136 | Rejected(id, ⊥, ⊥)     | Resolve(id, ⊥, F)      | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 137 | Rejected(id, ⊥, ⊥)     | Resolve(id, iku, T)    | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 138 | Rejected(id, ⊥, ⊥)     | Resolve(id, iku, F)    | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 139 | Rejected(id, ⊥, ⊥)     | Reject(id, ⊥, T)       | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 140 | Rejected(id, ⊥, ⊥)     | Reject(id, ⊥, F)       | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 141 | Rejected(id, ⊥, ⊥)     | Reject(id, iku, T)     | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 142 | Rejected(id, ⊥, ⊥)     | Reject(id, iku, F)     | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 143 | Rejected(id, ⊥, ⊥)     | Cancel(id, ⊥, T)       | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 144 | Rejected(id, ⊥, ⊥)     | Cancel(id, ⊥, F)       | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 145 | Rejected(id, ⊥, ⊥)     | Cancel(id, iku, T)     | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 146 | Rejected(id, ⊥, ⊥)     | Cancel(id, iku, F)     | Rejected(id, ⊥, ⊥)     | KO, Already Rejected   |
| 147 | Rejected(id, ⊥, iku)   | Create(id, ⊥, T)       | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 148 | Rejected(id, ⊥, iku)   | Create(id, ⊥, F)       | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 149 | Rejected(id, ⊥, iku)   | Create(id, ikc, T)     | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 150 | Rejected(id, ⊥, iku)   | Create(id, ikc, F)     | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 151 | Rejected(id, ⊥, iku)   | Resolve(id, ⊥, T)      | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 152 | Rejected(id, ⊥, iku)   | Resolve(id, ⊥, F)      | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 153 | Rejected(id, ⊥, iku)   | Resolve(id, iku, T)    | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 154 | Rejected(id, ⊥, iku)   | Resolve(id, iku, F)    | Rejected(id, ⊥, iku)   | OK, Deduplicated       |
| 155 | Rejected(id, ⊥, iku)   | Resolve(id, iku*, T)   | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 156 | Rejected(id, ⊥, iku)   | Resolve(id, iku*, F)   | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 157 | Rejected(id, ⊥, iku)   | Reject(id, ⊥, T)       | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 158 | Rejected(id, ⊥, iku)   | Reject(id, ⊥, F)       | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 159 | Rejected(id, ⊥, iku)   | Reject(id, iku, T)     | Rejected(id, ⊥, iku)   | OK, Deduplicated       |
| 160 | Rejected(id, ⊥, iku)   | Reject(id, iku, F)     | Rejected(id, ⊥, iku)   | OK, Deduplicated       |
| 161 | Rejected(id, ⊥, iku)   | Reject(id, iku*, T)    | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 162 | Rejected(id, ⊥, iku)   | Reject(id, iku*, F)    | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 163 | Rejected(id, ⊥, iku)   | Cancel(id, ⊥, T)       | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 164 | Rejected(id, ⊥, iku)   | Cancel(id, ⊥, F)       | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 165 | Rejected(id, ⊥, iku)   | Cancel(id, iku, T)     | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 166 | Rejected(id, ⊥, iku)   | Cancel(id, iku, F)     | Rejected(id, ⊥, iku)   | OK, Deduplicated       |
| 167 | Rejected(id, ⊥, iku)   | Cancel(id, iku*, T)    | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 168 | Rejected(id, ⊥, iku)   | Cancel(id, iku*, F)    | Rejected(id, ⊥, iku)   | KO, Already Rejected   |
| 169 | Rejected(id, ikc, ⊥)   | Create(id, ⊥, T)       | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 170 | Rejected(id, ikc, ⊥)   | Create(id, ⊥, F)       | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 171 | Rejected(id, ikc, ⊥)   | Create(id, ikc, T)     | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 172 | Rejected(id, ikc, ⊥)   | Create(id, ikc, F)     | Rejected(id, ikc, ⊥)   | OK, Deduplicated       |
| 173 | Rejected(id, ikc, ⊥)   | Create(id, ikc*, T)    | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 174 | Rejected(id, ikc, ⊥)   | Create(id, ikc*, F)    | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 175 | Rejected(id, ikc, ⊥)   | Resolve(id, ⊥, T)      | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 176 | Rejected(id, ikc, ⊥)   | Resolve(id, ⊥, F)      | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 177 | Rejected(id, ikc, ⊥)   | Resolve(id, iku, T)    | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 178 | Rejected(id, ikc, ⊥)   | Resolve(id, iku, F)    | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 179 | Rejected(id, ikc, ⊥)   | Reject(id, ⊥, T)       | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 180 | Rejected(id, ikc, ⊥)   | Reject(id, ⊥, F)       | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 181 | Rejected(id, ikc, ⊥)   | Reject(id, iku, T)     | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 182 | Rejected(id, ikc, ⊥)   | Reject(id, iku, F)     | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 183 | Rejected(id, ikc, ⊥)   | Cancel(id, ⊥, T)       | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 184 | Rejected(id, ikc, ⊥)   | Cancel(id, ⊥, F)       | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 185 | Rejected(id, ikc, ⊥)   | Cancel(id, iku, T)     | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 186 | Rejected(id, ikc, ⊥)   | Cancel(id, iku, F)     | Rejected(id, ikc, ⊥)   | KO, Already Rejected   |
| 187 | Rejected(id, ikc, iku) | Create(id, ⊥, T)       | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 188 | Rejected(id, ikc, iku) | Create(id, ⊥, F)       | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 189 | Rejected(id, ikc, iku) | Create(id, ikc, T)     | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 190 | Rejected(id, ikc, iku) | Create(id, ikc, F)     | Rejected(id, ikc, iku) | OK, Deduplicated       |
| 191 | Rejected(id, ikc, iku) | Create(id, ikc*, T)    | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 192 | Rejected(id, ikc, iku) | Create(id, ikc*, F)    | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 193 | Rejected(id, ikc, iku) | Resolve(id, ⊥, T)      | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 194 | Rejected(id, ikc, iku) | Resolve(id, ⊥, F)      | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 195 | Rejected(id, ikc, iku) | Resolve(id, iku, T)    | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 196 | Rejected(id, ikc, iku) | Resolve(id, iku, F)    | Rejected(id, ikc, iku) | OK, Deduplicated       |
| 197 | Rejected(id, ikc, iku) | Resolve(id, iku*, T)   | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 198 | Rejected(id, ikc, iku) | Resolve(id, iku*, F)   | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 199 | Rejected(id, ikc, iku) | Reject(id, ⊥, T)       | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 200 | Rejected(id, ikc, iku) | Reject(id, ⊥, F)       | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 201 | Rejected(id, ikc, iku) | Reject(id, iku, T)     | Rejected(id, ikc, iku) | OK, Deduplicated       |
| 202 | Rejected(id, ikc, iku) | Reject(id, iku, F)     | Rejected(id, ikc, iku) | OK, Deduplicated       |
| 203 | Rejected(id, ikc, iku) | Reject(id, iku*, T)    | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 204 | Rejected(id, ikc, iku) | Reject(id, iku*, F)    | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 205 | Rejected(id, ikc, iku) | Cancel(id, ⊥, T)       | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 206 | Rejected(id, ikc, iku) | Cancel(id, ⊥, F)       | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 207 | Rejected(id, ikc, iku) | Cancel(id, iku, T)     | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 208 | Rejected(id, ikc, iku) | Cancel(id, iku, F)     | Rejected(id, ikc, iku) | OK, Deduplicated       |
| 209 | Rejected(id, ikc, iku) | Cancel(id, iku*, T)    | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 210 | Rejected(id, ikc, iku) | Cancel(id, iku*, F)    | Rejected(id, ikc, iku) | KO, Already Rejected   |
| 211 | Canceled(id, ⊥, ⊥)     | Create(id, ⊥, T)       | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 212 | Canceled(id, ⊥, ⊥)     | Create(id, ⊥, F)       | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 213 | Canceled(id, ⊥, ⊥)     | Create(id, ikc, T)     | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 214 | Canceled(id, ⊥, ⊥)     | Create(id, ikc, F)     | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 215 | Canceled(id, ⊥, ⊥)     | Resolve(id, ⊥, T)      | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 216 | Canceled(id, ⊥, ⊥)     | Resolve(id, ⊥, F)      | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 217 | Canceled(id, ⊥, ⊥)     | Resolve(id, iku, T)    | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 218 | Canceled(id, ⊥, ⊥)     | Resolve(id, iku, F)    | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 219 | Canceled(id, ⊥, ⊥)     | Reject(id, ⊥, T)       | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 220 | Canceled(id, ⊥, ⊥)     | Reject(id, ⊥, F)       | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 221 | Canceled(id, ⊥, ⊥)     | Reject(id, iku, T)     | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 222 | Canceled(id, ⊥, ⊥)     | Reject(id, iku, F)     | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 223 | Canceled(id, ⊥, ⊥)     | Cancel(id, ⊥, T)       | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 224 | Canceled(id, ⊥, ⊥)     | Cancel(id, ⊥, F)       | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 225 | Canceled(id, ⊥, ⊥)     | Cancel(id, iku, T)     | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 226 | Canceled(id, ⊥, ⊥)     | Cancel(id, iku, F)     | Canceled(id, ⊥, ⊥)     | KO, Already Canceled   |
| 227 | Canceled(id, ⊥, iku)   | Create(id, ⊥, T)       | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 228 | Canceled(id, ⊥, iku)   | Create(id, ⊥, F)       | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 229 | Canceled(id, ⊥, iku)   | Create(id, ikc, T)     | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 230 | Canceled(id, ⊥, iku)   | Create(id, ikc, F)     | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 231 | Canceled(id, ⊥, iku)   | Resolve(id, ⊥, T)      | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 232 | Canceled(id, ⊥, iku)   | Resolve(id, ⊥, F)      | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 233 | Canceled(id, ⊥, iku)   | Resolve(id, iku, T)    | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 234 | Canceled(id, ⊥, iku)   | Resolve(id, iku, F)    | Canceled(id, ⊥, iku)   | OK, Deduplicated       |
| 235 | Canceled(id, ⊥, iku)   | Resolve(id, iku*, T)   | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 236 | Canceled(id, ⊥, iku)   | Resolve(id, iku*, F)   | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 237 | Canceled(id, ⊥, iku)   | Reject(id, ⊥, T)       | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 238 | Canceled(id, ⊥, iku)   | Reject(id, ⊥, F)       | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 239 | Canceled(id, ⊥, iku)   | Reject(id, iku, T)     | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 240 | Canceled(id, ⊥, iku)   | Reject(id, iku, F)     | Canceled(id, ⊥, iku)   | OK, Deduplicated       |
| 241 | Canceled(id, ⊥, iku)   | Reject(id, iku*, T)    | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 242 | Canceled(id, ⊥, iku)   | Reject(id, iku*, F)    | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 243 | Canceled(id, ⊥, iku)   | Cancel(id, ⊥, T)       | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 244 | Canceled(id, ⊥, iku)   | Cancel(id, ⊥, F)       | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 245 | Canceled(id, ⊥, iku)   | Cancel(id, iku, T)     | Canceled(id, ⊥, iku)   | OK, Deduplicated       |
| 246 | Canceled(id, ⊥, iku)   | Cancel(id, iku, F)     | Canceled(id, ⊥, iku)   | OK, Deduplicated       |
| 247 | Canceled(id, ⊥, iku)   | Cancel(id, iku*, T)    | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 248 | Canceled(id, ⊥, iku)   | Cancel(id, iku*, F)    | Canceled(id, ⊥, iku)   | KO, Already Canceled   |
| 249 | Canceled(id, ikc, ⊥)   | Create(id, ⊥, T)       | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 250 | Canceled(id, ikc, ⊥)   | Create(id, ⊥, F)       | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 251 | Canceled(id, ikc, ⊥)   | Create(id, ikc, T)     | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 252 | Canceled(id, ikc, ⊥)   | Create(id, ikc, F)     | Canceled(id, ikc, ⊥)   | OK, Deduplicated       |
| 253 | Canceled(id, ikc, ⊥)   | Create(id, ikc*, T)    | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 254 | Canceled(id, ikc, ⊥)   | Create(id, ikc*, F)    | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 255 | Canceled(id, ikc, ⊥)   | Resolve(id, ⊥, T)      | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 256 | Canceled(id, ikc, ⊥)   | Resolve(id, ⊥, F)      | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 257 | Canceled(id, ikc, ⊥)   | Resolve(id, iku, T)    | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 258 | Canceled(id, ikc, ⊥)   | Resolve(id, iku, F)    | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 259 | Canceled(id, ikc, ⊥)   | Reject(id, ⊥, T)       | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 260 | Canceled(id, ikc, ⊥)   | Reject(id, ⊥, F)       | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 261 | Canceled(id, ikc, ⊥)   | Reject(id, iku, T)     | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 262 | Canceled(id, ikc, ⊥)   | Reject(id, iku, F)     | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 263 | Canceled(id, ikc, ⊥)   | Cancel(id, ⊥, T)       | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 264 | Canceled(id, ikc, ⊥)   | Cancel(id, ⊥, F)       | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 265 | Canceled(id, ikc, ⊥)   | Cancel(id, iku, T)     | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 266 | Canceled(id, ikc, ⊥)   | Cancel(id, iku, F)     | Canceled(id, ikc, ⊥)   | KO, Already Canceled   |
| 267 | Canceled(id, ikc, iku) | Create(id, ⊥, T)       | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 268 | Canceled(id, ikc, iku) | Create(id, ⊥, F)       | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 269 | Canceled(id, ikc, iku) | Create(id, ikc, T)     | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 270 | Canceled(id, ikc, iku) | Create(id, ikc, F)     | Canceled(id, ikc, iku) | OK, Deduplicated       |
| 271 | Canceled(id, ikc, iku) | Create(id, ikc*, T)    | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 272 | Canceled(id, ikc, iku) | Create(id, ikc*, F)    | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 273 | Canceled(id, ikc, iku) | Resolve(id, ⊥, T)      | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 274 | Canceled(id, ikc, iku) | Resolve(id, ⊥, F)      | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 275 | Canceled(id, ikc, iku) | Resolve(id, iku, T)    | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 276 | Canceled(id, ikc, iku) | Resolve(id, iku, F)    | Canceled(id, ikc, iku) | OK, Deduplicated       |
| 277 | Canceled(id, ikc, iku) | Resolve(id, iku*, T)   | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 278 | Canceled(id, ikc, iku) | Resolve(id, iku*, F)   | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 279 | Canceled(id, ikc, iku) | Reject(id, ⊥, T)       | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 280 | Canceled(id, ikc, iku) | Reject(id, ⊥, F)       | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 281 | Canceled(id, ikc, iku) | Reject(id, iku, T)     | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 282 | Canceled(id, ikc, iku) | Reject(id, iku, F)     | Canceled(id, ikc, iku) | OK, Deduplicated       |
| 283 | Canceled(id, ikc, iku) | Reject(id, iku*, T)    | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 284 | Canceled(id, ikc, iku) | Reject(id, iku*, F)    | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 285 | Canceled(id, ikc, iku) | Cancel(id, ⊥, T)       | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 286 | Canceled(id, ikc, iku) | Cancel(id, ⊥, F)       | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 287 | Canceled(id, ikc, iku) | Cancel(id, iku, T)     | Canceled(id, ikc, iku) | OK, Deduplicated       |
| 288 | Canceled(id, ikc, iku) | Cancel(id, iku, F)     | Canceled(id, ikc, iku) | OK, Deduplicated       |
| 289 | Canceled(id, ikc, iku) | Cancel(id, iku*, T)    | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 290 | Canceled(id, ikc, iku) | Cancel(id, iku*, F)    | Canceled(id, ikc, iku) | KO, Already Canceled   |
| 291 | Timedout(id, ⊥, ⊥)     | Create(id, ⊥, T)       | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 292 | Timedout(id, ⊥, ⊥)     | Create(id, ⊥, F)       | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 293 | Timedout(id, ⊥, ⊥)     | Create(id, ikc, T)     | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 294 | Timedout(id, ⊥, ⊥)     | Create(id, ikc, F)     | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 295 | Timedout(id, ⊥, ⊥)     | Resolve(id, ⊥, T)      | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 296 | Timedout(id, ⊥, ⊥)     | Resolve(id, ⊥, F)      | Timedout(id, ⊥, ⊥)     | OK, Deduplicated       |
| 297 | Timedout(id, ⊥, ⊥)     | Resolve(id, iku, T)    | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 298 | Timedout(id, ⊥, ⊥)     | Resolve(id, iku, F)    | Timedout(id, ⊥, ⊥)     | OK, Deduplicated       |
| 299 | Timedout(id, ⊥, ⊥)     | Reject(id, ⊥, T)       | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 300 | Timedout(id, ⊥, ⊥)     | Reject(id, ⊥, F)       | Timedout(id, ⊥, ⊥)     | OK, Deduplicated       |
| 301 | Timedout(id, ⊥, ⊥)     | Reject(id, iku, T)     | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 302 | Timedout(id, ⊥, ⊥)     | Reject(id, iku, F)     | Timedout(id, ⊥, ⊥)     | OK, Deduplicated       |
| 303 | Timedout(id, ⊥, ⊥)     | Cancel(id, ⊥, T)       | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 304 | Timedout(id, ⊥, ⊥)     | Cancel(id, ⊥, F)       | Timedout(id, ⊥, ⊥)     | OK, Deduplicated       |
| 305 | Timedout(id, ⊥, ⊥)     | Cancel(id, iku, T)     | Timedout(id, ⊥, ⊥)     | KO, Already Timedout   |
| 306 | Timedout(id, ⊥, ⊥)     | Cancel(id, iku, F)     | Timedout(id, ⊥, ⊥)     | OK, Deduplicated       |
| 307 | Timedout(id, ikc, ⊥)   | Create(id, ⊥, T)       | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 308 | Timedout(id, ikc, ⊥)   | Create(id, ⊥, F)       | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 309 | Timedout(id, ikc, ⊥)   | Create(id, ikc, T)     | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 310 | Timedout(id, ikc, ⊥)   | Create(id, ikc, F)     | Timedout(id, ikc, ⊥)   | OK, Deduplicated       |
| 311 | Timedout(id, ikc, ⊥)   | Create(id, ikc*, T)    | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 312 | Timedout(id, ikc, ⊥)   | Create(id, ikc*, F)    | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 313 | Timedout(id, ikc, ⊥)   | Resolve(id, ⊥, T)      | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 314 | Timedout(id, ikc, ⊥)   | Resolve(id, ⊥, F)      | Timedout(id, ikc, ⊥)   | OK, Deduplicated       |
| 315 | Timedout(id, ikc, ⊥)   | Resolve(id, iku, T)    | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 316 | Timedout(id, ikc, ⊥)   | Resolve(id, iku, F)    | Timedout(id, ikc, ⊥)   | OK, Deduplicated       |
| 317 | Timedout(id, ikc, ⊥)   | Reject(id, ⊥, T)       | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 318 | Timedout(id, ikc, ⊥)   | Reject(id, ⊥, F)       | Timedout(id, ikc, ⊥)   | OK, Deduplicated       |
| 319 | Timedout(id, ikc, ⊥)   | Reject(id, iku, T)     | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 320 | Timedout(id, ikc, ⊥)   | Reject(id, iku, F)     | Timedout(id, ikc, ⊥)   | OK, Deduplicated       |
| 321 | Timedout(id, ikc, ⊥)   | Cancel(id, ⊥, T)       | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 322 | Timedout(id, ikc, ⊥)   | Cancel(id, ⊥, F)       | Timedout(id, ikc, ⊥)   | OK, Deduplicated       |
| 323 | Timedout(id, ikc, ⊥)   | Cancel(id, iku, T)     | Timedout(id, ikc, ⊥)   | KO, Already Timedout   |
| 324 | Timedout(id, ikc, ⊥)   | Cancel(id, iku, F)     | Timedout(id, ikc, ⊥)   | OK, Deduplicated       |
