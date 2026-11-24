// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title  BloodDonation
 * @notice Blood donation process management on Ethereum — Session 7 proposal framework.
 *
 * State machine (forward-only, no skipping, no rollback):
 *
 *   Created --sendToLab--> InLab --recordTest--> Tested
 *           --transferUnit--> Transferred --markTransfused--> Transfused
 *
 * Roles: four organization roles (DonationHospital, Laboratory, ReceiverHospital,
 * Payer) plus the contract owner. Roles are granted manually by the deployer
 * through `grantRole`. Each transition is restricted to the party that owns that
 * step, and to the specific record that party is already linked to — a registered
 * hospital cannot touch another hospital's donation.
 *
 * Privacy boundary — on chain we store only:
 *   numeric id, participant addresses, status, timestamps, hashes, anonymous patient ref.
 * Donor name, ID number, full lab report, patient identity stay off chain; the
 * hash is enough to prove the off-chain document was not altered.
 */
contract BloodDonation {
    // ------------------------------------------------------------------ types

    enum Status {
        Created,      // 0 — donation registered by the collection hospital
        InLab,        // 1 — sample handed to the laboratory
        Tested,       // 2 — lab result recorded
        Transferred,  // 3 — unit released to the receiving hospital
        Transfused    // 4 — unit used on a patient
    }

    enum Role {
        None,              // 0 — not registered
        DonationHospital,  // 1 — collects the blood, creates the record
        Laboratory,        // 2 — runs the screening tests
        ReceiverHospital,  // 3 — stores the unit and transfuses it
        Payer              // 4 — optional: pays the service fee
    }

    struct DonationRecord {
        bytes32 donationId;   // business id from the paper / off-chain system
        address hospital;     // collection hospital
        address lab;          // laboratory handling this unit
        address receiver;     // receiving hospital
        bytes32 recordHash;   // hash of the off-chain donation form
        bytes32 resultHash;   // hash of the off-chain test report
        bytes32 patientRef;   // anonymous patient reference (no personal data)
        bool qualified;       // screening result
        bool receiptConfirmed;// set by confirmReceipt; required before markTransfused
        Status status;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // ------------------------------------------------------------------ storage

    address public owner;
    address public treasury;      // receives the optional service fee
    uint256 public serviceFee;

    mapping(address => Role) public roleOf;
    mapping(uint256 => DonationRecord) private records;
    uint256 public donationCount;  // auto-increment key, starts at 1

    // A business donation id may be used at most once — otherwise a paper record
    // could be registered twice and the chain would hold two conflicting versions.
    mapping(bytes32 => bool) public donationIdUsed;

    // Optional payment: one payment per record, never two.
    mapping(uint256 => bool) public feePaid;

    // ------------------------------------------------------------------ events
    // The frontend refreshes from these instead of polling the chain.

    event DonationCreated(uint256 indexed id, address indexed hospital, bytes32 recordHash, uint256 ts);
    event SentToLab(uint256 indexed id, address indexed lab, uint256 ts);
    event TestRecorded(uint256 indexed id, bytes32 resultHash, bool qualified, uint256 ts);
    event UnitTransferred(uint256 indexed id, address indexed receiver, uint256 ts);
    event ReceiptConfirmed(uint256 indexed id, address indexed receiver, uint256 ts);
    event MarkedTransfused(uint256 indexed id, bytes32 patientRef, uint256 ts);
    event ServiceFeePaid(uint256 indexed id, address indexed payer, uint256 amount);
    event RoleGranted(address indexed account, uint8 role);
    event RoleRevoked(address indexed account);
    event TreasuryChanged(address indexed newTreasury);
    event ServiceFeeChanged(uint256 newFee);

    // ------------------------------------------------------------------ guards

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyRole(Role r) {
        require(roleOf[msg.sender] == r, "role not allowed");
        _;
    }

    modifier validId(uint256 id) {
        require(id > 0 && id <= donationCount, "no such donation");
        _;
    }

    /// Only the hospital that created this record may move it forward.
    modifier onlyOwningHospital(uint256 id) {
        require(records[id].hospital == msg.sender, "not your donation");
        _;
    }

    /// Only the lab this unit was assigned to may record its result.
    modifier onlyAssignedLab(uint256 id) {
        require(records[id].lab == msg.sender, "not your lab task");
        _;
    }

    /// Only the receiving hospital this unit was sent to may touch it.
    modifier onlyAssignedReceiver(uint256 id) {
        require(records[id].receiver == msg.sender, "not your case");
        _;
    }

    // ------------------------------------------------------------------ setup

    constructor(address _treasury, uint256 _serviceFee) {
        require(_treasury != address(0), "treasury required");
        owner = msg.sender;
        treasury = _treasury;
        serviceFee = _serviceFee;
    }

    // ------------------------------------------------------------------ admin

    /// Deployer grants roles manually. Kept simple on purpose: at MVP stage the
    /// number of institutions is small and known, so on-chain governance would
    /// add complexity without adding trust.
    function grantRole(address account, Role role) external onlyOwner {
        require(account != address(0), "zero address");
        roleOf[account] = role;
        emit RoleGranted(account, uint8(role));
    }

    /// @notice Revokes a previously granted role. Emits RoleRevoked so the
    ///         frontend can drop the account's permissions immediately.
    function revokeRole(address account) external onlyOwner {
        roleOf[account] = Role.None;
        emit RoleRevoked(account);
    }

    function setServiceFee(uint256 fee) external onlyOwner {
        serviceFee = fee;
        emit ServiceFeeChanged(fee);
    }

    function setTreasury(address t) external onlyOwner {
        require(t != address(0), "zero address");
        treasury = t;
        emit TreasuryChanged(t);
    }

    function transferOwnership(address to) external onlyOwner {
        require(to != address(0), "zero address");
        owner = to;
    }

    // ------------------------------------------------------------------ process

    /// @notice Step 0. Collection hospital registers a new donation.
    /// @dev    Only a hash goes on chain — the form itself stays off chain.
    ///         A business donation id may be registered at most once.
    function createDonation(bytes32 _donationId, bytes32 _recordHash)
        external
        onlyRole(Role.DonationHospital)
        returns (uint256 id)
    {
        require(_recordHash != bytes32(0), "record hash required");
        require(_donationId != bytes32(0), "donation id required");
        require(!donationIdUsed[_donationId], "donation id already used");
        donationIdUsed[_donationId] = true;

        id = ++donationCount;
        records[id] = DonationRecord({
            donationId: _donationId,
            hospital: msg.sender,
            lab: address(0),
            receiver: address(0),
            recordHash: _recordHash,
            resultHash: bytes32(0),
            patientRef: bytes32(0),
            qualified: false,
            receiptConfirmed: false,
            status: Status.Created,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        emit DonationCreated(id, msg.sender, _recordHash, block.timestamp);
    }

    /// @notice Step 1. Created -> InLab.
    function sendToLab(uint256 id, address lab)
        external
        onlyRole(Role.DonationHospital)
        validId(id)
        onlyOwningHospital(id)
    {
        DonationRecord storage d = records[id];
        require(d.status == Status.Created, "bad state");
        require(roleOf[lab] == Role.Laboratory, "lab not registered");
        d.lab = lab;
        d.status = Status.InLab;
        d.updatedAt = block.timestamp;
        emit SentToLab(id, lab, block.timestamp);
    }

    /// @notice Step 2. InLab -> Tested.
    function recordTest(uint256 id, bytes32 _resultHash, bool _qualified)
        external
        onlyRole(Role.Laboratory)
        validId(id)
        onlyAssignedLab(id)
    {
        DonationRecord storage d = records[id];
        require(d.status == Status.InLab, "bad state");
        require(_resultHash != bytes32(0), "result hash required");
        d.resultHash = _resultHash;
        d.qualified = _qualified;
        d.status = Status.Tested;
        d.updatedAt = block.timestamp;
        emit TestRecorded(id, _resultHash, _qualified, block.timestamp);
    }

    /// @notice Step 3. Tested -> Transferred. Only a qualified unit may move.
    function transferUnit(uint256 id, address receiver)
        external
        onlyRole(Role.Laboratory)
        validId(id)
        onlyAssignedLab(id)
    {
        DonationRecord storage d = records[id];
        require(d.status == Status.Tested, "bad state");
        require(d.qualified, "unit not qualified");
        require(roleOf[receiver] == Role.ReceiverHospital, "receiver not registered");
        d.receiver = receiver;
        d.status = Status.Transferred;
        d.updatedAt = block.timestamp;
        emit UnitTransferred(id, receiver, block.timestamp);
    }

    /// @notice Acknowledgement of arrival. Does not move the state machine —
    ///         arrival and use are two different facts — but it sets
    ///         receiptConfirmed, which markTransfused requires. So a unit cannot
    ///         be marked transfused without a recorded arrival, while keeping
    ///         the five-state design and both timestamps.
    function confirmReceipt(uint256 id)
        external
        onlyRole(Role.ReceiverHospital)
        validId(id)
        onlyAssignedReceiver(id)
    {
        DonationRecord storage d = records[id];
        require(d.status == Status.Transferred, "bad state");
        require(!d.receiptConfirmed, "receipt already confirmed");
        d.receiptConfirmed = true;
        emit ReceiptConfirmed(id, msg.sender, block.timestamp);
    }

    /// @notice Step 4. Transferred -> Transfused. Requires a prior confirmReceipt.
    function markTransfused(uint256 id, bytes32 _patientRef)
        external
        onlyRole(Role.ReceiverHospital)
        validId(id)
        onlyAssignedReceiver(id)
    {
        DonationRecord storage d = records[id];
        require(d.status == Status.Transferred, "bad state");
        require(d.receiptConfirmed, "receipt not confirmed");
        require(_patientRef != bytes32(0), "patient ref required");
        d.patientRef = _patientRef;
        d.status = Status.Transfused;
        d.updatedAt = block.timestamp;
        emit MarkedTransfused(id, _patientRef, block.timestamp);
    }

    // ------------------------------------------------------------------ reads

    function donationExists(uint256 id) external view returns (bool) {
        return id > 0 && id <= donationCount;
    }

    function getDonation(uint256 id)
        external
        view
        validId(id)
        returns (
            Status status,
            address hospital,
            address lab,
            address receiver,
            bytes32 recordHash,
            bytes32 resultHash,
            bytes32 patientRef,
            bool qualified,
            bool receiptConfirmed,
            uint256 createdAt,
            uint256 updatedAt
        )
    {
        DonationRecord storage d = records[id];
        return (d.status, d.hospital, d.lab, d.receiver, d.recordHash,
                d.resultHash, d.patientRef, d.qualified, d.receiptConfirmed,
                d.createdAt, d.updatedAt);
    }

    /// @notice "My records" for the current caller, filtered by their role.
    function getDonationIdsByRole() external view returns (uint256[] memory) {
        Role r = roleOf[msg.sender];
        uint256 n = donationCount;
        uint256[] memory tmp = new uint256[](n);
        uint256 k = 0;
        for (uint256 i = 1; i <= n; i++) {
            DonationRecord storage d = records[i];
            bool visible = false;
            if (r == Role.DonationHospital && d.hospital == msg.sender) visible = true;
            else if (r == Role.Laboratory && d.lab == msg.sender) visible = true;
            else if (r == Role.ReceiverHospital && d.receiver == msg.sender) visible = true;
            else if (r == Role.Payer) visible = true;
            if (visible) tmp[k++] = i;
        }
        uint256[] memory out = new uint256[](k);
        for (uint256 j = 0; j < k; j++) out[j] = tmp[j];
        return out;
    }

    // ----------------------------------------------------------- payment (OPTIONAL)
    // NOT part of the six core workflow functions. The process runs end to end
    // without it. Kept in the contract so the optional fee path can be shown or
    // dropped without touching the state machine.

    /// @notice Optional flat service fee. At most one payment per record.
    /// @dev    Effects are written before the external call (reentrancy safety).
    function payServiceFee(uint256 id) external payable validId(id) {
        require(roleOf[msg.sender] == Role.Payer, "role not allowed");
        require(msg.value == serviceFee, "wrong amount");
        require(!feePaid[id], "fee already paid");
        feePaid[id] = true;
        emit ServiceFeePaid(id, msg.sender, msg.value);
        (bool ok, ) = treasury.call{value: msg.value}("");
        require(ok, "transfer failed");
    }
}

