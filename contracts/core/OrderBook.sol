//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOrderBook.sol";

contract OrderBook is IOrderBook {
    address orderBook;
    function getOrderById(address buyer, address seller, uint256 tokenId, uint256 orderNonce) override public {
        IOrderBook(orderBook).getOrderById(buyer, seller, tokenId, orderNonce);
    }
    function getOrderStatus(bytes32 orderHash) override public {
        IOrderBook(orderBook).getOrderStatus(orderHash);
    }

    function disputeOrderById(address disputer, uint256 tokenId, uint256 orderNonce) override public {
        IOrderBook(orderBook).disputeOrderById(disputer, tokenId, orderNonce);
    }
    
    function overrideOrderDispute(bytes32 orderHash, string memory reason) override public {
        IOrderBook(orderBook).overrideOrderDispute(orderHash, reason);
    }
}