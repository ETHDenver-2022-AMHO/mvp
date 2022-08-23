// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
interface IOrderBook {
    event OrderInitiated(address indexed buyer, uint256 indexed tokenId);
    event OrderCancelled(address indexed buyer, uint256 indexed tokenId);
    event OrderDispute(address indexed buyer, address indexed seller, uint256 indexed tokenId, string reason);
    event OrderOverride(uint256 indexed tokenId, string reason);

    function getOrderById(address buyer, address seller, uint256 tokenId, uint256 orderNonce) external;
    function getOrderStatus(bytes32 orderHash) external;
    function disputeOrderById(address disputer, uint256 tokenId, uint256 orderNonce) external;
    function overrideOrderDispute(bytes32 orderHash, string memory reason) external;
}