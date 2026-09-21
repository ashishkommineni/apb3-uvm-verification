# Verification Plan

## Strategy

The active UVM agent emits setup and access phases; the monitor creates a transaction at setup and completes it only when `PREADY` is observed. A four-word reference register model predicts read data, legal writes, and `PSLVERR` without inspecting DUT internals.

| Goal | Stimulus | Check |
|---|---|---|
| Register access | Directed writes/reads at all four offsets | Reference register model |
| Wait states | Extended access with `PREADY=0` | Wait counter and control-stability SVA |
| Unaligned address | Directed `0x01` and constrained-random traffic | `PSLVERR`, no side effect |
| Out-of-range address | Directed `0x40` and randomized offsets | `PSLVERR`, zero invalid read |
| Back-to-back requests | Consecutive sequence items | Setup-to-access protocol assertions |

## Constraints and coverage

Address weighting favors the implemented 16-byte window while preserving out-of-range values. A second distribution favors aligned offsets but explicitly permits unaligned values. Direction and data are free to randomize. Coverage records direction, each legal register versus invalid address class, wait behavior, and error response, with a direction × address cross.

## Assertions and closure

Properties require `PENABLE` to imply `PSEL`, every setup to advance to access, an extended access to remain selected/enabled, and control/write data to remain stable during waits. Closure requires zero UVM errors/fatals, passing assertions, planned bins hit, and `APB3_SMOKE_PASS` from the portable test.
