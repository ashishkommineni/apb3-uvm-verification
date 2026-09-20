# Verification Plan

The master agent generates legal and illegal word-aligned transfers, reads, writes, random payloads, and back-to-back requests. A register-model scoreboard predicts storage and error responses. The monitor measures wait cycles. Coverage crosses direction and address class and records wait/error behavior. Assertions enforce setup-to-access sequencing, select during enable, and stable control while stalled.
