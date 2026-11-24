# Related Work and Requirements

**Project:** Blood Donation Process Management  ↩
**Status:** Session 7 proposal; requirements describe intended behavior, not implemented features.

## 1. Related work

### 1.1 Medical record access: MedRec

Ekblaw's MedRec thesis [1] proposes a blockchain-based system for managing access to electronic medical records. It uses a distributed permission and audit layer while integrating with records stored by healthcare providers. Its useful contribution for this project is the separation of access coordination from the actual medical data. MedRec addresses general medical record sharing rather than the specific operational stages of a blood donation. Integrating existing healthcare systems also requires cooperation from providers; blockchain alone does not establish the accuracy of a medical record.

### 1.2 Private-network donation management: Hawashin et al.

Hawashin et al. [2] propose a blood donation management system using a private Ethereum blockchain and IPFS to support traceability and manage storage. The work provides a relevant example of using smart contracts across donation stakeholders. Its private-network setting and wider design differ from our proposed small teaching prototype; the paper does not establish that a public testnet prototype provides the same privacy properties. Off-chain storage is not automatically private and needs its own access controls.

### 1.3 Blood supply-chain traceability: Sadri et al.

Sadri et al. [3] study Ethereum-based tracking in the blood donation supply chain, with smart contracts and participants across supply-chain stages. Their work illustrates how shared updates can help trace a blood unit through the process. A blockchain record, however, captures what a participant reports: by itself it does not verify a laboratory result, physical transfer, or transfusion. Our prototype therefore uses simulated events and focuses on understandable role restrictions and an observable history.

### 1.4 Comparison and project position

| Approach                                 | Main focus                              | Useful idea                                               | Scope or limitation for this project                                                      |
| ---------------------------------------- | --------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| MedRec [1]                               | Access to electronic medical records    | Permission management with provider-held data             | General medical records rather than a donation workflow; integration depends on providers |
| Private Ethereum donation management [2] | Blood donation process and storage      | Smart contracts and off-chain storage                     | A private network has different visibility assumptions from a public testnet              |
| Ethereum blood supply-chain tracking [3] | Traceability across supply-chain stages | A shared sequence of participant updates                  | On-chain updates alone cannot verify physical events                                      |
| Proposed course MVP                      | Demonstrate a small donation workflow   | Role- and assignment-based updates plus a visible history | Simulated data only; no claim of clinical deployment or methodological novelty            |

**Research question:** How can a Web application and Ethereum support traceable, role-controlled donation updates while keeping sensitive medical data off-chain?

The contribution proposed here is a scoped demonstration that brings existing ideas together. It is not a claim that blockchain traceability or medical access control is new. Whether Sepolia, cloud deployment and payment are required remains subject to instructor confirmation.

## 2. Actors and responsibilities

| Actor              | Proposed responsibility                                                | Access boundary                                                                                             |
| ------------------ | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Administrator      | Set up and maintain approved organization accounts                     | Can grant or revoke roles; role governance is a design requirement, not an assertion that it is implemented |
| Donation hospital  | Create a simulated donation record and designate a laboratory          | May act only on records and transitions permitted by its role and assignment                                |
| Testing laboratory | Record a simulated test outcome and send an eligible record onward     | May update only an assigned record at an allowed stage                                                      |
| Receiving hospital | Confirm receipt and record simulated transfusion                       | May update only an assigned record at an allowed stage                                                      |
| Donor and patient  | Represented in the demonstration by synthetic identifiers where needed | No donor or patient wallet, identity verification or direct access is assumed in the MVP                    |

Roles describe proposed requirements. The contract owner will settle exact names, functions and state transitions. In particular, failed tests should not silently proceed as successful donations; their handling remains to be agreed in the contract design.

## 3. Requirements

### Functional requirements

| ID    | Requirement                                                                                                  | Acceptance example                                                                  |
| ----- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| FR-01 | An authorized donation hospital can create a simulated record with a unique identifier.                      | A valid creation appears in the record list.                                        |
| FR-02 | Authorized accounts can be assigned their organization role.                                                 | An unapproved account cannot perform a protected update.                            |
| FR-03 | Only the appropriate role **and assigned organization** may update a record in an allowed state.             | A different laboratory cannot submit a result for the record.                       |
| FR-04 | The workflow rejects out-of-order and repeated transitions.                                                  | Recording transfusion before receipt fails without changing the record.             |
| FR-05 | Users can inspect the current state and an event history for the simulated record.                           | Successful updates are shown in chronological order with their transaction details. |
| FR-06 | Invalid or unauthorized operations are reported without changing state.                                      | A rejected action returns an error and the previous state remains.                  |
| FR-07 | If the instructor approves and time permits, demonstrate an optional service-payment function with test ETH. | A test-only payment is distinguishable from the core tracking flow.                 |

### Non-functional and privacy requirements

| ID     | Requirement                                                                                                                                                                                                                                                            |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| NFR-01 | Use synthetic data only throughout the course demonstration, including identifiers and off-chain examples.                                                                                                                                                             |
| NFR-02 | Do not place names, identity numbers, contact details, full medical reports, patient or donor identities, or identifiable medical information on a public blockchain.                                                                                                  |
| NFR-03 | Treat public-chain state, events, transaction history, wallet addresses and timing as publicly observable and potentially linkable. Role restrictions govern who may write; they do not hide public data.                                                              |
| NFR-04 | Use random synthetic record identifiers. A hash or pseudonym alone does not guarantee anonymity: predictable inputs can be guessed and metadata can be linked. Do not publish hashes of real personal or medical data for this demonstration.                          |
| NFR-05 | Any off-chain service used in a future implementation needs separate authentication, least-privilege authorization and appropriate secure storage; the blockchain does not enforce those controls. The present MVP does not claim a production-ready medical database. |
| NFR-06 | The interface should clearly distinguish transaction pending, confirmed and failed states. The test plan will define the concrete checks.                                                                                                                              |

## 4. Data boundary

| Location                         | Proposed example                                                                                                                | Privacy interpretation                                                                                                                |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| On-chain                         | Synthetic record ID, organization wallet addresses, simulated status, timestamps and event history                              | Public and potentially linkable. Keep payload minimal; no real patient or donor data.                                                 |
| Off-chain                        | Synthetic demonstration details; in a future real system, protected clinical data would remain in separately controlled storage | Off-chain does not mean automatically confidential; access control, encryption, retention and governance must be designed separately. |
| Excluded from this demonstration | Real identities, real clinical reports and real patient or donor data                                                           | No real medical workflow or clinical decision is performed.                                                                           |

The chain records submitted updates, not proof that a real-world action happened. Access governance, data quality, corrections, revocation, integration and legal compliance require separate design before real deployment.

## 5. Paper-ready Related Work

Blockchain has been explored for both healthcare record management and blood supply-chain traceability. Ekblaw's MedRec [1] manages medical record access and permissions while connecting to information held by providers. This separation between coordination and existing data storage is relevant to systems that should avoid publishing clinical details. However, MedRec addresses general electronic medical records rather than the operational stages of blood donation.

For the donation domain, Hawashin et al. [2] propose a private Ethereum-based management system supported by IPFS, while Sadri et al. [3] examine Ethereum-based traceability across the blood donation supply chain. Both provide examples of how shared records and smart contracts can support coordination among participants. Their settings and scopes differ from a small public-testnet demonstration, and a blockchain history cannot independently establish that a physical or clinical event occurred.

Building on these existing ideas, our proposed course prototype focuses on simulated donation status updates, organization roles, and an auditable event history exposed through a Web interface. Sensitive information is excluded from the public chain, and the demonstration uses synthetic data. This project combines existing techniques in a limited educational setting rather than claiming a novel blockchain mechanism. The final deployment platform and optional payment feature remain subject to instructor guidance.

## References

[1] A. C. Ekblaw, “MedRec: Blockchain for Medical Data Access, Permission Management and Trend Analysis,” S.M. thesis, Massachusetts Institute of Technology, Cambridge, MA, USA, 2017. https://hdl.handle.net/1721.1/109658

[2] D. Hawashin, D. A. J. Mahboobeh, K. Salah, R. Jayaraman, I. Yaqoob, M. Debe, and S. Ellahham, “Blockchain-Based Management of Blood Donation,” *IEEE Access*, vol. 9, pp. 163016–163032, 2021, doi: 10.1109/ACCESS.2021.3133953. https://doi.org/10.1109/ACCESS.2021.3133953

[3] S. Sadri, A. Shahzad, and K. Zhang, “Blockchain Traceability in Healthcare: Blood Donation Supply Chain,” in *Proc. 23rd International Conference on Advanced Communication Technology (ICACT)*, 2021, pp. 119–126, doi: 10.23919/ICACT51234.2021.9370704. https://doi.org/10.23919/ICACT51234.2021.9370704

