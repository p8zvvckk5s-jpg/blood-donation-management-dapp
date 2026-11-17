# Session 7 Slides 1–2

Owner and speaker: Hua Yujing

## Slide 1 — Project Proposal

### Blood Donation Process Management

**A hybrid Web 2.0 and Ethereum/cloud DApp**

- Session 7 project proposal
- Course: Introduction to Ethereum and Cloud Blockchain Solutions Engineering
- Team members: Hua Yujing, Song Wenjing, Long Yuan, and Zhang Chenyu

### Speaker focus

Introduce the project title, team, purpose, and scope. Explain that the goal is to improve traceability across donation hospitals, laboratories, and receiving hospitals without placing personal or medical information on a public blockchain.

## Slide 2 — Problem and Blockchain Fit

### Current problems

- Records are fragmented across institutions.
- Handoffs and current status are difficult to verify.
- Authorization rules may be inconsistent.
- Public-chain storage creates privacy risks for medical information.

### Why blockchain fits

- A shared ledger provides tamper-evident workflow history.
- Wallet-based roles identify who performed each update.
- A smart-contract state machine enforces the correct process order.
- Events provide an auditable record of accepted transitions.

### Privacy boundary

- **On chain:** pseudonymous donation ID, status, timestamp, responsible wallet, report hash, and events.
- **Off chain:** donor identity, contact details, full laboratory reports, and medical notes.
- The Session 7 demonstration uses simulated data only.

### Research question

How can a hybrid Web 2.0 and Ethereum/cloud architecture improve the traceability of the blood donation process while keeping personal and medical information off chain?
