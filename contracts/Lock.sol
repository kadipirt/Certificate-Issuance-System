// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CertificateIssuanceSystem is AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct Certificate {
        uint256 id;
        string recipientName;
        uint256 issueDate;
        bool isValid;
        address owner;
    }

    event CertificateIssued(uint256 indexed id, string recipientName, uint256 issueDate, address owner);
    event CertificateRevoked(uint256 indexed id);
    event CertificateTransferred(uint256 indexed id, address indexed from, address indexed to);

    uint256 private nextCertificateId;
    mapping(uint256 => Certificate) public certificates;

    constructor() {
        nextCertificateId = 1; // Start IDs at 1 for better UX
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
    }

    function issueCertificate(string memory _recipientName, address _owner) public onlyRole(ISSUER_ROLE) {
        uint256 certificateId = nextCertificateId++;
        certificates[certificateId] = Certificate({
            id: certificateId,
            recipientName: _recipientName,
            issueDate: block.timestamp,
            isValid: true,
            owner: _owner
        });

        emit CertificateIssued(certificateId, _recipientName, block.timestamp, _owner);
    }

    function verifyCertificate(uint256 _certificateId) public view returns (bool) {
        require(certificates[_certificateId].id != 0, "Certificate does not exist.");
        return certificates[_certificateId].isValid;
    }

    function revokeCertificate(uint256 _certificateId) public onlyRole(ISSUER_ROLE) {
        require(certificates[_certificateId].id != 0, "Certificate does not exist.");
        certificates[_certificateId].isValid = false;

        emit CertificateRevoked(_certificateId);
    }

    function transferCertificate(uint256 _certificateId, address _to) public {
        require(certificates[_certificateId].id != 0, "Certificate does not exist");
        require(certificates[_certificateId].isValid, "Certificate is not valid");
        require(_to != address(0), "Invalid recipient address");
        require(certificates[_certificateId].owner == msg.sender, "Not the certificate owner");

        certificates[_certificateId].owner = _to;
        emit CertificateTransferred(_certificateId, msg.sender, _to);
    }

    // Admin functions
    function addIssuer(address _issuer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ISSUER_ROLE, _issuer);
    }

    function removeIssuer(address _issuer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ISSUER_ROLE, _issuer);
    }
}