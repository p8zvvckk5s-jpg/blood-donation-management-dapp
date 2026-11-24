# Smart Contract Design — Blood Donation Process Management

Session 7 proposal · `contracts/BloodDonation.sol` · Solidity `^0.8.20`

This document covers slides 5–6 of the proposal: the donation workflow, the roles
that drive it, the contract surface, and the controls that stop unauthorised
modification. It describes the framework only — the MVP scope is defined in
`docs/mvp-test-plan.md`.

---

## 1. Why a state machine at all

A blood unit is not a free-form record. It moves through a fixed, regulated path:
collected → screened → released → received → transfused. Every step has a
different responsible party, and skipping a step means bypassing quality control.

Encoding that path as an on-chain state machine gives three things a shared
spreadsheet cannot:

| Property | What it means here |
|---|---|
| **No skipping** | A unit cannot go from `Created` straight to `Transferred` — screening cannot be skipped even accidentally |
| **No rollback** | Once a unit is marked `Transfused`, nobody can quietly move it back and reuse the record |
| **Attributable** | Every transition emits an event carrying `msg.sender`, so "who released this unit" is a fact, not a claim |

---

## 2. Roles and permissions

**Four organization roles, plus the contract owner.** Roles are granted
**manually by the owner** at MVP stage — the number of participating institutions
is small and known, so on-chain governance would add complexity without adding
trust.

| Role | Enum | What they may do | What they may *not* do |
|---|---|---|---|
| Deployer | `owner` | Grant/revoke roles, set service fee, move treasury | Touch any donation record |
| Collection hospital | `DonationHospital` | `createDonation`, `sendToLab` | Record test results, confirm receipt, transfuse |
| Laboratory | `Laboratory` | `recordTest`, `transferUnit` | Create donations, transfuse |
| Receiving hospital | `ReceiverHospital` | `confirmReceipt`, `markTransfused` | Create donations, record test results |
| Payer (optional) | `Payer` | `payServiceFee` | Any state transition |

**Two layers of authorisation, not one.** A role check alone is not enough: if
only `onlyRole(Laboratory)` were enforced, any registered lab could write results
for any other lab's sample. So every function also checks *record-level
ownership*:

```solidity
modifier onlyAssignedLab(uint256 id) {
    require(records[id].lab == msg.sender, "not your lab task");
    _;
}
```

Layer 1 answers "is this account a lab?", layer 2 answers "is this *the* lab for
this unit?". Both are required.

---

## 3. State flow

```
                    createDonation()            sendToLab(id, lab)
   (off chain)  ─────────────────────►  Created ──────────────────► InLab
                                                                      │
                                                        recordTest()  │  only assigned lab
                                                                      ▼
                                                                   Tested
                                                                      │
                                                     transferUnit()   │  only if qualified == true
                                                                      ▼
                                                                Transferred
                                                                      │
                                              confirmReceipt()  ──────┤  sets receiptConfirmed = true
                                                                      │  (no state change)
                                                                      │
                                              markTransfused()  ──────▼
                                                                  Transfused
```

| # | State | Meaning | Who is holding the unit |
|---|---|---|---|
| 0 | `Created` | Donation registered, form hash on chain | Collection hospital |
| 1 | `InLab` | Sample handed to the lab | Laboratory |
| 2 | `Tested` | Screening result recorded (pass or fail) | Laboratory |
| 3 | `Transferred` | Unit released and shipped to receiving hospital | Receiving hospital |
| 4 | `Transfused` | Unit used on a patient | — (closed) |

### Why `confirmReceipt` does not change state

Arrival and use are two different facts. A unit can sit in the receiving
hospital's fridge for a week before it is used. If `confirmReceipt` moved the
record to a "Received" state we would need a sixth state, and the record would
still have to distinguish "arrived" from "used".

Instead `confirmReceipt` sets `receiptConfirmed = true` and emits
`ReceiptConfirmed`, leaving the state at `Transferred`. `markTransfused`
requires `receiptConfirmed == true`, so **arrival cannot be skipped** even
though the state machine keeps five states. Both timestamps are still recorded:
arrival time in the `ReceiptConfirmed` event, transfusion time in `updatedAt`.

`confirmReceipt` cannot be called twice — the second call reverts with
`"receipt already confirmed"`.

### Why a failed test does not have its own state

A unit that fails screening stays at `Tested` with `qualified == false`.
`transferUnit` requires `qualified == true`, so a failed unit simply cannot move
forward. No extra state, no extra branch — the flag is the gate.

---

## 4. Contract surface

### Core workflow functions

| Function | Called by | Precondition | State change | Event |
|---|---|---|---|---|
| `createDonation(donationId, recordHash)` | collection hospital | role, non-zero hash, **donation id not used before** | new record at `Created` | `DonationCreated` |
| `sendToLab(id, lab)` | collection hospital | role, owns record, `Created`, lab has Laboratory role | → `InLab` | `SentToLab` |
| `recordTest(id, resultHash, qualified)` | laboratory | role, assigned lab, `InLab` | → `Tested`, sets `qualified` | `TestRecorded` |
| `transferUnit(id, receiver)` | laboratory | role, assigned lab, `Tested`, **`qualified`**, receiver has role | → `Transferred` | `UnitTransferred` |
| `confirmReceipt(id)` | receiving hospital | role, assigned receiver, `Transferred`, **not yet confirmed** | **no state change** — sets `receiptConfirmed = true` | `ReceiptConfirmed` |
| `markTransfused(id, patientRef)` | receiving hospital | role, assigned receiver, `Transferred`, **`receiptConfirmed`** | → `Transfused` | `MarkedTransfused` |

### Administration

| Function | Called by | Precondition | State change | Event |
|---|---|---|---|---|
| `grantRole(account, role)` | owner | — | sets `roleOf[account]` | `RoleGranted` |
| `revokeRole(account)` | owner | — | clears role | `RoleGranted` |
| `setServiceFee(fee)` | owner | — | updates fee | `ServiceFeeChanged` |
| `setTreasury(addr)` | owner | non-zero | updates treasury | `TreasuryChanged` |
| `transferOwnership(to)` | owner | non-zero | moves ownership | — |

### Payment — OPTIONAL, not part of the core workflow

The process runs end to end without any payment. `payServiceFee` is kept in the
contract only so the optional fee path can be shown or dropped without touching
the state machine.

| Function | Called by | Precondition | State change | Event |
|---|---|---|---|---|
| `payServiceFee(id)` | payer | role, exact amount, **fee not yet paid** | none | `ServiceFeePaid` |

`feePaid[id]` is set on payment, so a second payment for the same record reverts.

### Read functions

| Function | Returns |
|---|---|
| `getDonation(id)` | full record: status, parties, hashes, flag, timestamps |
| `getDonationIdsByRole()` | ids the caller is allowed to see, filtered by their role |
| `donationExists(id)` | bool |
| `donationCount()` | current counter |
| `roleOf(address)` | role enum (auto-generated getter) |

---

## 5. Events

Six core workflow events carry timestamps so the frontend can rebuild the
timeline without polling storage. Workflow events are indexed by donation ID.

```
Core workflow (indexed by donation id, carry timestamps)
  DonationCreated(id, hospital, recordHash, ts)
  SentToLab(id, lab, ts)
  TestRecorded(id, resultHash, qualified, ts)
  UnitTransferred(id, receiver, ts)
  ReceiptConfirmed(id, receiver, ts)
  MarkedTransfused(id, patientRef, ts)

Payment (optional)
  ServiceFeePaid(id, payer, amount)

Administration
  RoleGranted(account, role)
  RoleRevoked(account)
  TreasuryChanged(newTreasury)
  ServiceFeeChanged(newFee)
```

`RoleRevoked` is emitted by `revokeRole` so the frontend can drop an account's
permissions immediately. It is an administration event, not part of the six
core workflow events.

Workflow events are indexed by donation ID — the donation's record `id` is
`indexed` on every workflow event, so the frontend can filter `DonationCreated` /
`SentToLab` / … for one unit directly. We use events rather than polling: polling
wastes RPC calls and still misses the exact moment a transition happened.

---

## 6. Security controls

| Threat | Control | Where |
|---|---|---|
| Unregistered account calls a transition | `onlyRole(Role.X)` on every state-changing function | modifiers |
| Registered lab writes another lab's result | `onlyAssignedLab(id)` — record-level ownership | modifiers |
| Hospital moves another hospital's donation | `onlyOwningHospital(id)` | modifiers |
| Skipping screening | `require(status == Status.Tested)` before transfer | `transferUnit` |
| Releasing a failed unit | `require(d.qualified, "unit not qualified")` | `transferUnit` |
| Replaying a transition | each function requires an exact prior state; a completed transition leaves a different state, so the same call reverts | all transitions |
| Registering the same business donation id twice | `require(!donationIdUsed[_donationId])`, then mark it used | `createDonation` |
| Skipping the receipt confirmation | `require(d.receiptConfirmed)` before the unit can be transfused | `markTransfused` |
| Confirming the receipt twice | `require(!d.receiptConfirmed)` | `confirmReceipt` |
| Paying the fee twice for one record | `require(!feePaid[id])` | `payServiceFee` |
| Assigning an unregistered counterparty | `require(roleOf[lab] == Role.Laboratory)` / same for receiver | `sendToLab`, `transferUnit` |
| Reentrancy on fee payment | event emitted before the external call (checks-effects-interactions); only the treasury address is called | `payServiceFee` |
| Integer overflow | Solidity `^0.8` reverts on overflow by default; no `unchecked` blocks | compiler |
| Owner key compromise | out of scope for MVP — noted as a limitation, See §8 | — |

### What is *not* protected, and we say so

- **Off-chain data integrity.** We store a hash, so tampering is *detectable*, but
  nothing forces the hospital to hash the real form. Trust in the first writer
  remains — this is inherent to any hash-anchoring scheme and we flag it as a
  known limitation.
- **Owner centralisation.** The deployer can grant any role. Acceptable at MVP
  stage with a known set of institutions; a multi-sig or DAO would be the next
  step in production.
- **Patient identity.** `patientRef` is an opaque `bytes32`. Linking it back to a
  person happens off chain, so the chain itself cannot leak patient identity.

---

## 7. Privacy boundary

| On chain | Off chain |
|---|---|
| auto-increment id | donor name, ID number, phone |
| participant wallet addresses | donation form, questionnaire answers |
| status, timestamps | full laboratory report |
| `recordHash`, `resultHash` (32 bytes) | the documents those hashes commit to |
| `patientRef` (anonymous) | patient identity |

The rule we apply: **anything that identifies a person stays off chain**. The
chain carries proof that a document existed and has not changed, not the document.

---

## 8. Deliberately out of scope for Session 7

- Full unit-level inventory (we track a donation, not individual bags)
- Multi-signature ownership
- Upgradeability / proxy pattern — deployment is immutable by design
- On-chain storage of documents or images
- Automated oracle integration for external data

---

## 9. Open questions for the professor (Session 7)

1. Is Sepolia acceptable as the final deployment target, or is a specific
   platform required?
2. Is the optional `payServiceFee` path required for the final deliverable, or
   may we drop it and keep the contract purely about the process?
3. Does Session 7 require an actual deployment, or is the design sufficient?
4. Should the failed-screening case produce a distinct terminal state, or is the
   `qualified == false` flag at `Tested` acceptable?

---

## 10. Naming note and deployment status

This version is the group's single technical standard and follows the function
names in the course brief: `createDonation`, `sendToLab`, `recordTest`,
`transferUnit`, `confirmReceipt`, `markTransfused`, plus `Status` and
`DonationRecord`.

**Deployment status: DEPLOYED on 2026-11-24.**

| Item | Value |
|---|---|
| **New Sepolia address** | `0x3962Ef2f9C27c150F37a12a49b2a8287De8261d9` |
| **Deployment transaction hash** | `0x704d9330e79103e590cd2be37dc23816b1502d50361b5ec34a383d54ddcc12c7` |
| **Final ABI** | `build/BloodDonation.abi.json` (22 functions / 11 events) |
| **Final source** | `contracts/BloodDonation.sol` |
| **Compiler version** | solc 0.8.39 (`pragma solidity ^0.8.20`) |
| **Deployment date** | 2026-11-24 |
| Block number | 12201501 |
| Gas used | 11,765,904 |
| Constructor | `_treasury = 0x6ec71A58908D575016fe68557A69F8B4469B07bf`, `_serviceFee = 1000000000000000` (0.001 ETH) |
| Etherscan | <https://sepolia.etherscan.io/address/0x3962Ef2f9C27c150F37a12a49b2a8287De8261d9> |
| **Verification** | **Verified on 2026-11-24** — "Successfully generated matching Bytecode and ABI". Source is publicly readable on the Contract tab |

### The earlier prototype is superseded

Address `0xdc67c017604D88c1C24157e78a6631C74BeF7df1` was an **earlier prototype
deployment** with different function names (`sendToLaboratory`,
`recordTestResult`, `sendToHospital`, `transfuse`) and different type names
(`DonationStatus`, `Donation`). It does not implement `receiptConfirmed` or the
`donationIdUsed` guard, and its ABI is not compatible with this source.

**Do not run the new tests against the old address.** T1–T13 must be run against
`0x3962Ef2f9C27c150F37a12a49b2a8287De8261d9` with `build/BloodDonation.abi.json`.


### Roles are granted and verified

| Role | Enum | Address | Verified |
|---|---|---|---|
| Collection hospital | 1 | `0x86aBC34205ABE15f8352288B47be422685cC8846` | `roleOf = 1` |
| Laboratory #1 | 2 | `0xb4f6035A90F9D0ffd06e0B515CCe67154e5e25cf` | `roleOf = 2` |
| Receiving hospital | 3 | `0x75a0f9a291ee1d3a0750eC4A95c92C6d9Eb25Afe` | `roleOf = 3` |
| Laboratory #2 (also owner) | 2 | `0x6ec71A58908D575016fe68557A69F8B4469B07bf` | `roleOf = 2` |

Grant transactions:

| Role | Tx hash |
|---|---|
| Collection hospital | `0xe5e6ca0cc8cc1f147bd5c1b075a890abb32cff89c09fbdf5e0cc1e5df3068f6d` |
| Laboratory #1 | `0xb2ee445ca8dd8433126ead71ebd3746af0da0363c1d175ff8addb5641f1efa76` |
| Receiving hospital | `0x0b74d4d7a6551934655dc0b9854aaff64fa86542dc9bbcee28e48d2c846b9dc0` |
| Laboratory #2 | `0xf7fb2eed05ce69530740b077f6d2b6ad8d11405f35954b5c0df7c366dfae0810` |

**Why two laboratories.** T12 tests the *ownership* guard: a registered laboratory
that is **not** the lab assigned to a record must be rejected by
`onlyAssignedLab`. One lab account cannot exercise that, so the deployer account
also holds role 2. It can be swapped for a dedicated account later with
`grantRole`.

**Not yet assigned: Payer (role 4).** T10 is an optional test and is not part of
the MVP success criteria. Grant it with `grantRole(addr, 4)` if the payment path
is demonstrated.

**For T7 (privilege)** any account with no role works as the stranger — the
deployer account is also valid for that before it was given role 2, but any
empty account will do.


