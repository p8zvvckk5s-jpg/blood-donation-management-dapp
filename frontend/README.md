# Frontend Integration Plan

This folder documents the planned browser interface for the Session 7 proposal. The frontend
has not yet been implemented or connected end to end.

## Proposed stack

- React with Vite;
- ethers.js;
- MetaMask for wallet connection and transaction signing;
- Ethereum Sepolia (`chainId 11155111`);
- deployed contract: `0x3962Ef2f9C27c150F37a12a49b2a8287De8261d9`;
- ABI: [`../build/BloodDonation.abi.json`](../build/BloodDonation.abi.json).

## Planned screens

1. Wallet connection and network check.
2. Role-based dashboard.
3. Donation detail and permitted next action.
4. Audit history based on contract events.
5. Optional test-ETH service-payment screen, subject to instructor confirmation.

## Role-specific actions

| Role | Planned actions |
|---|---|
| Donation hospital | `createDonation`, `sendToLab` |
| Laboratory | `recordTest`, `transferUnit` |
| Receiving hospital | `confirmReceipt`, `markTransfused` |
| Payer (optional) | `payServiceFee` |

The interface will hide unavailable actions, but the Solidity contract remains the final
permission authority.

## Privacy boundary

Only synthetic identifiers, organization wallet addresses, status values, timestamps and
verification hashes are used on chain. Donor identity, patient identity, contact information and
full medical reports are excluded from the public blockchain and from this demonstration.

## Remaining implementation work

- create the React project and connect MetaMask;
- import the deployed ABI and address;
- implement reads, writes and event history;
- show pending, confirmed and failed transaction states;
- execute and record the test cases in
  [`../docs/mvp-test-plan.md`](../docs/mvp-test-plan.md).

This file is intentionally a plan, not a claim that the web interface is already complete.

