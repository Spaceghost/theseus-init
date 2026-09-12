# `the` query grammar

`the` is the read-oriented interface to the same typed state exposed by `theseus`.

The grammar is intentionally tiny and deterministic. It is not natural-language interpretation.

Current bootstrap forms:

```text
the status
the services
the failed services
the running services
the status of SERVICE
the state of SERVICE
the restart-policy of SERVICE
```

Mutation stays explicit under `theseus`:

```text
theseus status SERVICE
theseus state SERVICE
theseus services
```

Later mutating commands such as `theseus start`, `restart`, `stop`, and target transactions must never be inferred from `the` prose.

Design rule:

> `theseus` changes the machine. `the` reports what Theseus believes is true.
