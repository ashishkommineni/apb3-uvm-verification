# APB3 Register Slave Specification

## Address map

The DUT is a 32-bit APB3 peripheral with four writable registers.

| Offset | Reset value | Access |
|---|---:|---|
| `0x00` | `0x00000000` | Read/write |
| `0x04` | `0x00000000` | Read/write |
| `0x08` | `0x00000000` | Read/write |
| `0x0C` | `0x00000000` | Read/write |

Any other offset, including an unaligned address, is invalid.

## Protocol timing

Every transfer starts with a setup cycle (`PSEL=1, PENABLE=0`) and moves to an access cycle (`PSEL=1, PENABLE=1`). `WAIT_STATES` holds `PREADY` low for the configured number of access cycles. Address, direction, and write data must remain stable throughout an extended access.

On the completion cycle, `PREADY=1`. `PSLVERR` is asserted on that same cycle for an invalid address. A legal write updates its register only at completion; a failed write has no side effect. A legal read presents the selected register on `PRDATA`; invalid read data is zero.

## Reset and scope

`PRESETn` is asynchronous and active low. It clears all four registers and the wait counter. The design models one selected APB3 slave; multi-slave decode, APB4 strobes, protection fields, and low-power wakeup signaling are intentionally outside scope.
