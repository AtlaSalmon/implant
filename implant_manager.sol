// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ImplantManager {
    
    // -------------------------
    // Roles
    // -------------------------
    address public owner; // contract owner (admin)
 
    mapping(address => bool) public agents;
    mapping(address => bool) public dentists;
    mapping(address => bool) public patients;

    constructor() {
        owner = msg.sender; // deployer is admin
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyAgent() {
        require(agents[msg.sender], "Not an agent");
        _;
    }

    modifier onlyDentist() {
        require(dentists[msg.sender], "Not a dentist");
        _;
    }

    // -------------------------
    // Actor Management
    // -------------------------
    function addAgent(address _agent) external onlyOwner {
        agents[_agent] = true;
    }

    function addDentist(address _dentist) external onlyOwner {
        dentists[_dentist] = true;
    }

    function addPatient(address _patient) internal {
        patients[_patient] = true;
    }

    // -------------------------
    // Implant Struct
    // -------------------------
    struct OwnershipRecord {
        address owner;
        uint256 timestamp;
        string action; // "Registered", "Transferred", "Used"
    }

    struct Implant {
        uint256 id;
        string specs;       // implant specifications
        address currentOwner;
        bool used;
        address patient;
    }

    mapping(uint256 => Implant) public implants;
    mapping(uint256 => OwnershipRecord[]) public implantHistory;

    uint256 public implantCounter;

    // -------------------------
    // Implant Functions
    // -------------------------

    // Agent registers a new implant
    function registerImplant(string memory _specs) external onlyAgent returns (uint256) {
        implantCounter++;
        uint256 newId = implantCounter;

        implants[newId] = Implant({
            id: newId,
            specs: _specs,
            currentOwner: msg.sender,
            used: false,
            patient: address(0)
        });

        implantHistory[newId].push(OwnershipRecord({
            owner: msg.sender,
            timestamp: block.timestamp,
            action: "Registered"
        }));

        return newId;
    }

    // Agent transfers implant to a dentist
    function transferToDentist(uint256 _implantId, address _dentist) external onlyAgent {
        require(dentists[_dentist], "Recipient is not a dentist");
        Implant storage imp = implants[_implantId];
        require(!imp.used, "Implant already used");
        require(imp.currentOwner == msg.sender, "You are not the owner");

        imp.currentOwner = _dentist;

        implantHistory[_implantId].push(OwnershipRecord({
            owner: _dentist,
            timestamp: block.timestamp,
            action: "Transferred to Dentist"
        }));
    }

    // Dentist assigns implant to patient
    function assignToPatient(uint256 _implantId, address _patient) external onlyDentist {
        Implant storage imp = implants[_implantId];
        require(imp.currentOwner == msg.sender, "You are not the owner");
        require(!imp.used, "Implant already used");

        imp.currentOwner = _patient;
        imp.used = true;
        imp.patient = _patient;
        addPatient(_patient);

        implantHistory[_implantId].push(OwnershipRecord({
            owner: _patient,
            timestamp: block.timestamp,
            action: "Assigned to Patient"
        }));
    }

    // Get implant history
    function getImplantHistory(uint256 _implantId) external view returns (OwnershipRecord[] memory) {
        return implantHistory[_implantId];
    }

    // Get implant specs
    function getImplantSpecs(uint256 _implantId) external view returns (string memory, address, bool, address) {
        Implant memory imp = implants[_implantId];
        return (imp.specs, imp.currentOwner, imp.used, imp.patient);
    }
}


// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 agent
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db dentist
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db patient