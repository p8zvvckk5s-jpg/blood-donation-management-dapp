# Project Background and Blockchain Fit

Owner: Hua Yujing

## Background

The blood donation process crosses several organizational boundaries. A donation hospital collects blood and creates the initial record. A laboratory performs screening. A receiving hospital confirms delivery and use. Each institution may operate its own information system and apply its own access controls.

Separate systems create a coordination problem. One institution may not be able to verify the most recent status recorded by another institution. A later audit may also struggle to reconstruct when a handoff occurred and which organization authorized it.

## Why Blockchain Is Relevant

The project uses blockchain only for information that benefits from shared verification.

The planned smart contract will:

- record the current workflow state;
- enforce the permitted order of state transitions;
- restrict functions to approved institutional roles;
- record the wallet responsible for each update;
- emit events that form a shared audit timeline;
- store a hash that can be compared with an off-chain record.

Blockchain does not solve every part of the process. It will not determine whether medical test results are correct, protect information that users intentionally publish, or replace the hospitals' internal systems.

## Privacy Boundary

The public blockchain must not contain names, identity numbers, contact details, complete test reports, or medical notes. The prototype will use anonymous identifiers and simulated data.

The on-chain record contains only a donation identifier, status, timestamp, responsible wallet, report hash, and events. Sensitive fields remain in controlled off-chain storage.

## Project Scope

The Session 7 proposal covers a minimum workflow:

1. create a donation record;
2. send the record to a laboratory;
3. record a screening result;
4. transfer an approved blood unit;
5. confirm receipt;
6. mark the unit as transfused or used;
7. query the status and event history.

The prototype will also demonstrate rejection of unauthorized and out-of-order actions.

## Out of Scope for the First Prototype

- real patient or donor data;
- diagnosis or medical decision-making;
- real payments;
- integration with hospital production systems;
- large-scale performance evaluation;
- regulatory certification.

## Proposed Success Criteria

The MVP succeeds when a user can complete the simulated workflow in a browser, verify the corresponding blockchain transactions, and observe the rejection of at least one invalid action without exposing sensitive data.
