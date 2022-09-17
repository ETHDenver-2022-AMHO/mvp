// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEscrowRegistry {
    event ReceivedNFT(address indexed from, uint256 indexed tokenId);
    event ReleasedNFT(address indexed to, uint256 indexed tokenId);
    event LockNFT(address indexed seller, address indexed tokenAddress);
    event UnlockNFT(address indexed seller, address indexed tokenAddress);
    event ReceivedToken(address indexed buyer, uint256 indexed amount);
    event ReleasedToken(address indexed to, uint256 indexed amount);
    event OrderOverride(bytes32 orderId);

    function setTokenAddresses(address, address) external;
    function getTokenAddress() external view;
    function getEscrowOrderById(uint256) external view;
    function getEscrowOrderStateById(uint256) external view;

    function depositToken(address, address, uint256, uint256) external returns (bool);
    function depositNFT(address, uint256) external returns (bool);

    function releaseOrder(uint256, bytes32) external returns (int256);
}