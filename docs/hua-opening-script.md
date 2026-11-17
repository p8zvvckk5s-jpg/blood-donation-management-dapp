# Hua Yujing — Session 7 Opening Script

## Slide 1 — Project Proposal

Good morning, Professor. Our team project is called Blood Donation Process Management.

We propose a hybrid Web 2.0 and Ethereum/cloud DApp for coordination among donation hospitals, testing laboratories, and receiving hospitals.

Our main goal is to create a shared audit trail for the blood donation workflow. The blockchain will record important status changes and institutional actions, while personal identity and complete medical information will remain off chain.

This is our Session 7 project proposal. Today, we are presenting the problem, the reason for using blockchain, our planned MVP, and the responsibilities of each team member. We are not claiming that the final system has already been completed.

## Slide 2 — Operational Problems and Blockchain Fit

The current process involves several independent organizations. Each institution may maintain a separate database, which makes cross-organization status verification and handoff auditing difficult.

Our design uses blockchain for the parts that benefit from shared verification. The smart contract will record the current state, timestamp, responsible wallet, record hash, and an event for each accepted update. Role and state checks will reject unauthorized or out-of-order actions.

We also define a strict privacy boundary. Names, identity numbers, contact details, full laboratory reports, and medical notes will not be stored on the public blockchain. The prototype will use simulated data only.

Our research question is: How can a hybrid Web 2.0 and Ethereum/cloud architecture improve the traceability of the blood donation process while keeping personal and medical information off chain?

Next, Song Wenjing will introduce the existing methods, research gap, actors, and system requirements.

## Short Answers for Likely Questions

### Why not use a normal database?

A normal database works well inside one organization. Our proposal investigates a shared workflow across independent institutions where each organization should be able to verify the same status and handoff history. We still use an off-chain database for private information.

### Why use Sepolia?

Sepolia allows us to test wallet interaction and real blockchain transactions without using real money. We will confirm with the instructor whether Sepolia is acceptable for the final demonstration.

### Will you store medical data on chain?

No. We will use simulated data, anonymous identifiers, and hashes. Full reports and personal information remain off chain.

### Is payment part of the MVP?

Not currently. We treat test-ETH service payment as a second-phase feature until the instructor confirms whether it is mandatory.
