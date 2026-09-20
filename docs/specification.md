# APB3 Register Slave Specification

The DUT is a 32-bit APB3 slave with four word-aligned registers at offsets `0x00`, `0x04`, `0x08`, and `0x0C`. A transfer consists of one setup phase (`PSEL=1, PENABLE=0`) followed by an access phase (`PSEL=1, PENABLE=1`). The configurable `WAIT_STATES` parameter holds `PREADY` low before completion. Invalid or unaligned addresses complete with `PSLVERR=1` and do not modify state.
