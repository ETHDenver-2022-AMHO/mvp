// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEscrowRegistry {
    event NFTReceived(address indexed from, uint256 indexed tokenId);
    event NFTLocked(address indexed seller, address indexed tokenAddress);
    event NFTReleased(address indexed to, uint256 indexed tokenId);
    event PaymentLocked(address indexed buyer, uint256 indexed amount);
    event PaymentReleased(address indexed to, uint256 indexed amount);
    event EscrowOverride(bytes32 orderId);

    function getEscrowStatus(uint256 tokenId) external;
    function getEscrowSecret(address buyer, address seller, uint256 tokenId) external;
}