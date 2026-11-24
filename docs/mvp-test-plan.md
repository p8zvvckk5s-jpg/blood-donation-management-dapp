# MVP Test Plan — Blood Donation Tracking Contract

Thirteen cases. Six move a donation forward, one proves the receipt flag is enforced, six try to
break the contract. The MVP is done when all thirteen pass on Sepolia and the demo runs end to
end. Status as of this revision: **written, pending execution** — the revised contract has been
deployed to Sepolia, but no case has been recorded as passed or failed yet.

| | |
| --- | --- |
| System under test | `BloodDonation.sol` — deployed at `0x3962Ef2f9C27c150F37a12a49b2a8287De8261d9`; deployment transaction `0x704d9330e79103e590cd2be37dc23816b1502d50361b5ec34a383d54ddcc12c7` |
| Network | Ethereum Sepolia, chainId `11155111` |
| Case count | 13 (6 normal path, 7 exception) |
| Recording sheet | `MVP_Test_Plan.xlsx` — same ids, same wording |
| Related | [`frontend/README.md`](../frontend/README.md) §4 for the interface |

---

## 1. Purpose and scope

**In scope.** The contract's state machine, its role checks, its payment path, and the three data
flows the frontend depends on (write, read, event).

**Out of scope for this round**, and deliberately so: concurrency, reentrancy, gas limits, load,
and cross-chain anchoring. Each is listed in §12 with the reason it was deferred, so the omission
reads as a decision rather than an oversight.

The plan answers one question: *can a stranger be handed this contract and a wallet, and be
prevented from doing anything the state machine does not allow?*

---

## 2. System under test

Five states, six workflow functions, one payment function, six workflow events.

```
Created(0) ──sendToLab──▶ InLab(1) ──recordTest──▶ Tested(2)
   ──transferUnit──▶ Transferred(3) ──markTransfused──▶ Transfused(4)   [terminal]
                          └──confirmReceipt──▶ sets receiptConfirmed = true, no state change
```

Roles: `0` none, `1` donation hospital, `2` laboratory, `3` receiving hospital, `4` payer. Four
organization roles (1–4) plus the unassigned `0`; the contract owner is a separate account, not
one of the five role values.

Two facts that the test set is built around, because they are the two most often stated wrongly:

1. `transferUnit` is called by the **laboratory**, not by the receiving hospital.
2. `confirmReceipt` does **not** move the state, but it does **write** `receiptConfirmed = true`.
   `markTransfused` then requires that flag. So the step is enforced, not decorative — it is a
   prerequisite the state machine reads, while the state itself stays `Transferred`. T8 exists to
   prove this prerequisite is actually enforced.

---

## 3. Environment and accounts

Five addresses are needed. Fill them in once and reuse them for every run; a case that passes
with one set of addresses and fails with another usually means a role was granted twice.

| Purpose | Role id | Address | Sepolia ETH |
| --- | --- | --- | --- |
| Deployer (grants roles) | — | `0x…` | ≥ 0.05 |
| Donation hospital | 1 | `0x…` | ≥ 0.01 |
| Laboratory | 2 | `0x…` | ≥ 0.01 |
| Receiving hospital | 3 | `0x…` | ≥ 0.01 |
| Payer | 4 | `0x…` | ≥ 0.01 + fee |
| Stranger (negative tests) | 0 | `0x…` | ≥ 0.01 so reverts are not masked by "no funds" |

A revert caused by an empty wallet is indistinguishable from a revert caused by a failed
`require` in a block explorer. Fund the stranger account before running T7.

Tooling: Hardhat for the automated suite, MetaMask plus the deployed frontend for the demo path,
Etherscan for reading state and events.

---

## 4. Entry and exit criteria

**Entry.** Contract deployed and verified on Sepolia; ABI exported; all four organization roles
granted by the deployer; test accounts funded.

**Exit.** Thirteen of thirteen pass; the event log of one full run shows the six state-machine
events in order, once each; the demo runs from `createDonation` to `markTransfused` without a browser
reload.

**Abort.** A failing case whose cause is a contract defect stops the run — the remaining cases
share the same state and would produce noise. Record the case, the block, and the revert reason,
then hand it back to the contract owner.

---

## 5. Strategy

| Level | What it proves | Tool | When |
| --- | --- | --- | --- |
| Unit | Each `require` fires on its own | Hardhat, one `it()` per case | Every commit |
| Integration | The six workflow functions chain together on a real network | Script against Sepolia | Before each demo |
| UI | The three data flows behave from the browser | MetaMask + frontend | Before each demo |

The unit level is where the thirteen cases live; the other two exist so that a green suite cannot
hide a broken screen. A case counts as passed only at the level named in its row.

---

## 6. Normal flow tests

Each row states its precondition as the state left by the previous row. They are meant to be run
in order, as one donation moving from creation to transfusion.

| ID | Precondition | Call | Expected result | Event |
| --- | --- | --- | --- | --- |
| **T1** | Deployer granted role 1 to the hospital | `createDonation("BD-001", "QmRecordHash")` | Record exists, `status = Created (0)`, `hospital` = caller | `DonationCreated` |
| **T2** | T1 passed; record in Created | `sendToLab(1, labAddress)` | `status = InLab (1)`, `lab` set | `SentToLab` |
| **T3** | T2 passed; record in InLab | `recordTest(1, "QmResultHash", true)` | `status = Tested (2)`, `qualified = true`, `resultHash` stored | `TestRecorded` |
| **T4** | T3 passed; record in Tested | `transferUnit(1, receiverAddress)` | `status = Transferred (3)`, `receiver` set | `UnitTransferred` |
| **T5** | T4 passed; record in Transferred | `confirmReceipt(1)` | `status` **stays** `Transferred (3)` **and** `receiptConfirmed` becomes `true` | `ReceiptConfirmed` |
| **T6** | T5 passed | `markTransfused(1, "P-ANON-7")` | `status = Transfused (4)`, terminal | `MarkedTransfused` |

Assertions worth writing explicitly, because they are the ones a reviewer checks:

- **T1** — `getDonationIdsByRole()` for the hospital grows by exactly one; `createdAt` is the
  block timestamp, not zero.
- **T3** — run the negative branch as well: `recordTest(id, hash, false)` must store
  `qualified = false` and still advance to `Tested`. A rejected bag is a valid outcome, not an
  error.
- **T5** — this is the case most often skipped in a demo. Assert the state *before and after*,
  **and** assert `receiptConfirmed` flips from `false` to `true`. T8 depends on this flag, so
  leaving it unasserted means the test proves nothing. Asserting only that the transaction
  succeeded proves nothing either, since the whole point is that the *status* does not move while
  the *flag* does.
- **T6** — `patientRef` is stored; `updatedAt` advances while `createdAt` does not.

---

## 7. Exception tests

Seven ways to break the machine: the wrong person, the wrong owner, the wrong moment, twice, an
unqualified bag, and not enough money.

| ID | Type | Precondition | Call | Expected result | Event |
| --- | --- | --- | --- | --- | --- |
| **T7** | Privilege | Wallet with role 0 (stranger) | `sendToLab(1, labAddress)` from the stranger | Reverts on the role check; status and storage unchanged | none |
| **T8** | Out of order | Record in Transferred, `confirmReceipt` **not** called | `markTransfused(1, "P-ANON-7")` | Reverts on the receipt check; status stays Transferred | none |
| **T9** | Repeat | Record already Transfused | `markTransfused(1, "P-ANON-7")` again | Reverts on the terminal-state check; nothing is rewritten | none |
| **T10** | Payment (optional) | Record exists; payer holds role 4 | `payServiceFee(1)` with exactly 0.001 ETH | 0.001 ETH reaches the treasury, event recorded | `ServiceFeePaid` |
| **T11** | Unqualified unit | Record in Tested with `qualified = false` | `transferUnit(1, receiverAddress)` | Reverts with `"unit not qualified"`; status stays Tested | none |
| **T12** | Wrong owner | Record in InLab, assigned to lab A; call from lab B (role 2) | `recordTest(1, hash, true)` from lab B | Reverts with `"not your lab task"`; status stays InLab | none |
| **T13** | Repeat receipt | Record already has `receiptConfirmed = true` | `confirmReceipt(1)` again | Reverts with `"receipt already confirmed"`; flag unchanged | none |

How each one is expected to fail, in the detail a test needs:

**T7 — wrong role.** Three sub-cases, run all three, because they hit different `require`
statements: role 0 calling a hospital function, role 1 calling a laboratory function, and role 4
calling `markTransfused`. Expected in every sub-case: the transaction reverts, gas is consumed, no
event is emitted, and the donation's `updatedAt` does not move. The last assertion is the one
that catches a `require` placed after the write.

**T8 — out of order.** This case is what makes the receipt flag real. If `markTransfused` succeeds
without `confirmReceipt`, then `confirmReceipt` is decoration and the state machine has
effectively four states. Two variants: (a) never called `confirmReceipt`; (b) `confirmReceipt`
called, then `markTransfused` must **succeed** — proving the flag is a precondition, not a blocker.

**T9 — repeat.** `markTransfused` on a `Transfused` record, and `createDonation` with a duplicate
business code `"BD-001"`. Both must revert; the second is the one usually forgotten, and it is
the one that would let a bag be registered twice.

**T10 — payment (optional, outside the MVP success criteria).** Three amounts: exactly 0.001 ETH
(passes, treasury balance +0.001), 0.0009 ETH (reverts), and double payment for the same donation
(**reverts** with `"fee already paid"` — `feePaid[id]` is set `true` on success, so the second
call fails at `require(!feePaid[id])`). `payServiceFee` must not change the donation's status.
This case is `optional / future`: the function ships in the same contract but is not one of the
six core workflow functions and does not gate the MVP.

**T11 — unqualified unit.** `transferUnit` on a bag whose `qualified = false` must revert with
`"unit not qualified"`. This is the negative branch of T3 — T3 proves a rejected bag is a *valid
outcome* (it still reaches `Tested`); T11 proves that such a bag cannot then be *shipped*.

**T12 — wrong owner, right role.** A laboratory with a valid role 2 calls
`recordTest` on a donation assigned to a *different* laboratory. The `onlyAssignedLab`
modifier requires `records[id].lab == msg.sender`, so it reverts with `"not your lab task"`. This
is the second layer of defence that T7 does not cover: T7 is the wrong *role*, T12 is the right
role but the wrong *owner*.

**T13 — repeat receipt.** Calling `confirmReceipt` twice. The first call sets
`receiptConfirmed = true`; the second reverts at `require(!d.receiptConfirmed)` with `"receipt
already confirmed"`. This guards against a double acknowledgment.

---

## 8. Coverage

Every action is hit at least once by a passing case and once by a failing one, except
`confirmReceipt`, which has a legal path and two illegal paths (T8 and T13).

| Action | Passes in | Fails in |
| --- | --- | --- |
| `createDonation` | T1 | T9 (duplicate code) |
| `sendToLab` | T2 | T7 (role 0, role 2) |
| `recordTest` | T3 (true and false) | T7 (role 1), T12 (wrong owner) |
| `transferUnit` | T4 | T7 (role 3), T11 (unqualified) |
| `confirmReceipt` | T5 | T8 (order), T13 (repeat) |
| `markTransfused` | T6 | T8, T9, T7 (role 4) |
| `payServiceFee` | T10 | T10 (underpayment, double) |

| State | Reached in | Left behind in |
| --- | --- | --- |
| Created (0) | T1 | T2 |
| InLab (1) | T2 | T3, T12 |
| Tested (2) | T3 | T4, T11 |
| Transferred (3) | T4 | T5 (no change), T6, T8 |
| Transfused (4) | T6 | T9 |

---

## 9. How to run

**Automated, local chain.**

```bash
cd contracts
npx hardhat test                 # all thirteen cases
npx hardhat test --grep "T7"     # one case
```

**Against Sepolia.** Point `hardhat.config` at the network and run the same suite with the funded
accounts from §3. Reads are free; expect roughly 0.002 ETH of gas for one full run.

**Manual, for the demo.** Six steps, one wallet switch each, in this order:

1. Hospital creates `BD-001` — card appears at `Created`.
2. Hospital sends it to the lab — `InLab`.
3. Switch to the laboratory, record a qualified result — `Tested`.
4. Laboratory sends it to the receiving hospital — `Transferred`.
5. Switch to the receiving hospital, confirm receipt — **status must not change**, but the
   receipt flag flips; say this out loud during the demo, it is the detail that shows the model
   is understood.
6. Mark transfused — `Transfused`, and the next attempt reverts.

Before the demo, deliberately run one revert in front of yourself: with the wrong wallet, try
`markTransfused`. If the error message reads like a stack trace instead of a sentence, the frontend
error map is not finished.

---

## 10. Recording results

`MVP_Test_Plan.xlsx` holds the same thirteen ids with a status column (`Pending` / `Pass` / `Fail`)
and a live pass-rate cell. Enter the block number of each run next to the status; a result
without a block number cannot be re-checked.

As of this revision all thirteen statuses are `Pending — awaiting execution`.

For a failure, record four things: the case id, the transaction hash, the raw `revert reason`
from the console, and whether the state changed. "It did not work" is not a defect report.

---

## 11. Traceability

| This plan | Presentation | Paper section |
| --- | --- | --- |
| §2 state machine, §6 normal path | Slide 08 — MVP scope, five states | Solution Implementation |
| §7 exception tests, §8 coverage | Slide 08 — thirteen cases, designed not yet run | Testing Plan |
| §9 manual demo script | Slide 08 — the Week 9 demo | Testing Plan |
| §12 deferred scope | Slide 08 — what is out of the MVP | Testing Plan (limitations) |

---

## 12. Deferred, with reasons

| Not tested | Why not now | Consequence, stated openly |
| --- | --- | --- |
| Reentrancy | No external calls before state writes; `payServiceFee` transfers value | Should still be asserted once the treasury is a contract |
| Concurrency | One donation is handled by one role at a time | Two hospitals racing on one id is untested |
| Gas ceilings | Ambulance-side use implies mobile wallets and tight blocks | A large `getDonationIdsByRole()` return could exceed limits at scale |
| Cross-chain anchoring | The cloud platform is still `TBD` | The hybrid claim is architectural, not yet demonstrated |
| Load | Course demo scale | Not a production readiness claim |

Two of these are worth saying out loud in the Q&A rather than waiting to be asked: the cloud
chain platform has not been chosen (pending instructor confirmation), and the mainnet deployment
has not happened (also pending instructor confirmation on whether it is required).

---

## 13. Resolved questions

These four were open in the previous revision; the contract owner confirmed all four against the
actual ABI.

| # | Question | Answer |
| --- | --- | --- |
| 1 | Who may call `setServiceFee` / `setTreasury`? | **`onlyOwner`**, and both emit events. T10's economics hold; there is no public setter |
| 2 | Is the ABI the deployed version? | **Yes.** The current ABI (with `receiptConfirmed` / `donationIdUsed` / `feePaid`) matches the revised contract deployed at `0x3962Ef2f…61d9`. T1–T13 can now be executed; their results remain pending until transaction evidence is recorded |
| 3 | Is double payment rejected, or recorded twice? | **Rejected**, revert reason `"fee already paid"` (`require(!feePaid[id])`). T10's third variant is now decidable |
| 4 | Is `getDonationIdsByRole` an array per role or a full scan? | **Full scan O(n)** — it iterates `1..donationCount` and filters by role. The paper must not describe it as an indexed lookup; this also feeds the gas-ceiling note in §12 |

With 1 and 3 answered, T10 is fully decidable. The deployment gate is complete. The remaining work
is to execute T1–T13, record block numbers and transaction hashes, and replace `Pending` with the
actual result for each case.

