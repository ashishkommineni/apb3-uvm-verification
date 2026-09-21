# Verification Results

Revalidated: 2026-09-21

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint`; zero RTL warnings |
| Executable RTL + SVA smoke | PASS | `APB3_SMOKE_PASS checks=10` |
| Parameter elaboration | PASS | Zero-wait (`WAIT_STATES=0`) variant passed strict lint |
| UVM source compile/elaboration | PASS | Complete UVM hierarchy compiled against Accellera UVM `78c0654` |

```text
APB3_SMOKE_PASS checks=10
```

The ten portable checks cover writes and readbacks for all four registers, two wait cycles per access, one out-of-range error, and one unaligned error. Runtime assertions enforce setup/access sequencing and stable selected control during every wait.

## Second-pass findings corrected

- The address constraint now generates unaligned traffic instead of silently forcing alignment.
- Directed UVM and smoke cases guarantee both unaligned and out-of-range `PSLVERR` paths.
- A wait-state property now requires `PSEL` and `PENABLE` to remain asserted.
- No-traffic and `pipefail` guards eliminate silent testbench passes.

## Xcelium boundary

Xcelium is not available in this workspace; functional coverage has therefore not been executed here. Source elaboration passed. Run `make regress` under Xcelium and accept only zero UVM errors/fatals, passing SVA, and coverage-plan closure.
