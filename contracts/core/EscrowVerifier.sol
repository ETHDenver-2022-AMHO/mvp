
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EscrowVerifier {
    mapping(uint256 => EncryptedMetadata) internal metadataStore;

    struct EncryptedMetadata {
        address currentOwner;
        address nextOwner;
        bytes32 secret;
    }

    constructor() public {
    }

    function idToMetadata(uint256 _tokenId) public view returns(EncryptedMetadata memory) {
        return  metadataStore[_tokenId];
    }
    function getSecretFromMetadataStore(uint256 _tokenId) public view returns (bytes32) {
        return metadataStore[_tokenId].secret;
    }
    function getNextOwnerFromMetadataStore(uint256 _tokenId) public view returns (address) {
        return metadataStore[_tokenId].nextOwner;
    }
    function getCurrentOwnerFromMetadataStore(uint256 _tokenId) public view returns (address) {
        return metadataStore[_tokenId].currentOwner;
    }
}