# EVIDENCE.md

Current verification truth.

`SPEC.md` defines what must be true.
`TODO.md` defines what work is being executed.
This file records what has actually been proven.

Do not record claims without reproducible evidence. Git preserves historical
versions; keep this file focused on current project verification state.

## Acceptance Evidence

Use one row per acceptance criterion. `Required proof` comes from the approved
criterion. `Result` is `NOT VERIFIED`, `PASS`, or `FAIL`.

| AC | Required proof | Result | Evidence |
|---|---|---|---|
| `{{TBD: AC-ID}}` | {{TBD: NORMAL, SMOKE, LIVE, MANUAL, or comma-separated combination}} | NOT VERIFIED | {{TBD: command, test, artifact, or concise observation}} |

## External Integration State

States are cumulative:

```text
IMPLEMENTED -> TESTED -> LIVE VERIFIED
```

- `IMPLEMENTED` - the real adapter/configuration path exists.
- `TESTED` - deterministic automated evidence exercises the integration contract.
- `LIVE VERIFIED` - the real target provider was contacted through its real
  credential/configuration path and the expected behavior was observed.

Mocks, deterministic stubs, no-credential fallback behavior, or adapter existence
must never be reported as `LIVE VERIFIED`.

| Integration | Required final state | Achieved state | Evidence |
|---|---|---|---|
| {{TBD: integration}} | {{TBD: IMPLEMENTED, TESTED, or LIVE VERIFIED}} | {{TBD: NOT STARTED, IMPLEMENTED, TESTED, or LIVE VERIFIED}} | {{TBD: concise evidence}} |

## Packaging / Deployment Evidence

Keep expensive packaging or deployment smoke evidence separate from routine
validation.

| Gate | Result | Evidence |
|---|---|---|
| {{TBD: packaging/deployment gate}} | NOT VERIFIED | {{TBD: command or observation}} |

## Final Certification Notes

{{TBD: concise unresolved evidence gaps, or `None` when every required proof is satisfied}}
