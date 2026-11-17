# Blood Donation Process Management DApp

## Session 7 Project Proposal

This repository contains the proposal and planned implementation of a hybrid Web 2.0 and Ethereum/cloud DApp for blood donation process management. The project focuses on coordination among donation hospitals, testing laboratories, and receiving hospitals.

The system will use a Solidity smart contract to record authorized process transitions and an off-chain application to manage simulated private information. The prototype will not store names, identity numbers, contact details, or full medical reports on a public blockchain.

## Problem

Blood donation involves several organizations. Each organization may keep separate records, which can make it difficult to verify the current status of a blood unit, reconstruct its handoff history, and determine who performed an update.

The project addresses four problems:

- fragmented records across institutions;
- unclear handoffs between hospitals and laboratories;
- inconsistent authorization rules;
- privacy risks when medical information is placed on a public blockchain.

## Research Question

How can a hybrid Web 2.0 and Ethereum/cloud architecture improve the traceability of the blood donation process while keeping personal and medical information off chain?

## Proposed Solution

The web application will connect to MetaMask and interact with a Solidity smart contract. The smart contract will enforce the order of the blood donation workflow and record an event for every accepted transition.

### Planned workflow

1. A donation hospital creates a pseudonymous donation record.
2. The hospital sends the record to the laboratory stage.
3. The laboratory records a pass or fail result and a hash of the off-chain report.
4. Approved blood is transferred to a receiving hospital.
5. The receiving hospital confirms receipt.
6. The receiving hospital marks the blood unit as transfused or otherwise used.

### Planned on-chain data

- donation identifier;
- workflow status;
- timestamp;
- responsible wallet address;
- hash of an off-chain record;
- smart-contract events.

### Planned off-chain data

- donor identity;
- contact information;
- full laboratory report;
- medical notes;
- any other sensitive or personally identifiable information.

All demonstrations will use simulated data.

## Minimum Viable Prototype

The first prototype will demonstrate the following functions:

- connect a MetaMask wallet;
- create one donation record;
- complete the valid hospital-to-laboratory-to-hospital workflow;
- reject an unauthorized action;
- reject an invalid state transition;
- display the current status and audit history in a browser.

Service payment using test ETH is treated as a second-phase feature until the instructor confirms whether it is required.

## Preliminary Architecture

- **Frontend:** browser-based interface for institutional users;
- **Wallet:** MetaMask for authentication and transaction signing;
- **Smart contract:** Solidity state machine with role and status checks;
- **Ethereum network:** Sepolia is proposed for development and demonstration;
- **Cloud layer:** web hosting, API, and controlled off-chain storage;
- **Audit layer:** contract events and transaction history.

## Existing Methods and Research Gap

Existing research has proposed private Ethereum and IPFS architectures for blood donation traceability. Other work uses Hyperledger Fabric for permissioned blood donation and transfusion workflows. Open-source Ethereum contracts demonstrate basic blood donation functions.

Our course project narrows the scope to a demonstrable cross-institution workflow with explicit role permissions, ordered state transitions, a browser interface, and a strict on-chain/off-chain privacy boundary.

## Team Responsibilities

| Member | Complete module | Presentation slides |
|---|---|---|
| Hua Yujing | Project definition, blockchain fit, coordination, README, and final integration | 1–2 |
| Song Wenjing | Related work, actors, requirements, and references | 3–4 |
| Long Yuan | Business workflow, smart-contract design, and security controls | 5–6 |
| Zhang Chenyu | Hybrid architecture, MVP, frontend plan, and testing plan | 7–8 |

Each member owns a complete module and its corresponding Session 7 presentation section.

## Repository Structure

```text
.
├── README.md
├── docs/
│   ├── background.md
│   ├── hua-opening-script.md
│   ├── instructor-questions.md
│   ├── slides-1-2.md
│   └── team-responsibilities.md
├── contracts/
│   └── README.md
├── frontend/
│   └── README.md
└── test/
    └── README.md
```

## Questions for the Instructor

1. Does the final system require Ethereum plus one cloud blockchain platform or Ethereum plus two cloud blockchain platforms?
2. May the team use Sepolia instead of Ethereum Mainnet for the course demonstration?
3. Is the service-payment function mandatory, or may it remain a second-phase feature?

## Current Status

- [x] Topic selected
- [x] Session 7 proposal prepared
- [x] Research question and MVP boundary defined
- [x] Team ownership assigned
- [x] Privacy boundary documented
- [ ] Instructor questions answered
- [ ] Smart-contract skeleton added by Long Yuan
- [ ] Related-work document added by Song Wenjing
- [ ] Architecture and test plan added by Zhang Chenyu
- [ ] Prototype implemented and deployed

## References

- Hawashin, D. et al. “Blockchain-Based Management of Blood Donation.” *IEEE Access*, 2021. https://doi.org/10.1109/ACCESS.2021.3133953
- Priya, E. S., Priya, R., and Surendiran, R. “Implementation of Trust-based Blood Donation and Transfusion System using Blockchain Technology.” *IJETT*, 2022. https://doi.org/10.14445/22315381/IJETT-V70I8P210
- Daddie-b. “Blood-Bank-BlockChain.” GitHub. https://github.com/Daddie-b/Blood-Bank-BlockChain
- GEC Academy course materials: Course Project Guidance, Final Project Specification, and Project High-Level Plan.

## Educational and Privacy Notice

This project is an educational prototype. It does not process real medical data and is not intended for clinical or production use.
