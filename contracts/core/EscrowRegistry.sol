//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AmhoNFT.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thirdweb-dev/contracts/eip/interface/IERC721A.sol";

contract EscrowRegistry {
    address amho;
    address token;
    bool addressSet;

    enum EscrowOrderState {
        DEPOSITED_NFT,
        DEPOSITED_TOKEN,
        DISPUTE_NEW,
        DISPUTE_RECEIVED,
        DISPUTE_OVERRIDE,
        DISPUTE_CANCELLED
    }

    struct EscrowOrder {
        address payable buyer;
        address payable seller;
        uint256 value;
        EscrowOrderState status;
    }

    // Token ID to get order buyer, seller, and status

    mapping(uint256 => EscrowOrder) public escrowOrderById;

    event ReceivedNFT(address, uint256);
    event DepositedNFT(address indexed seller, address tokenAddress);
    event DepositedToken(address indexed buyer, uint256 amount);

    function setTokenAddresses(address _amho, address _token) public {
        amho = _amho;
        token = _token;
        addressSet = true;
    }

    function getTokenAddress() public view returns(address) {
        return token;
    }

    function getEscrowOrderById(uint256 _tokenId)
        public
        view
        returns (EscrowOrder memory)
    {
        return escrowOrderById[_tokenId];
    }

    function depositToken(
        address _tokenAddress,
        address from,
        uint256 _tokenId,
        uint256 amount
    ) external returns (bool) {
        require(addressSet, "Addresses not set");
        AmhoNFT _amho = AmhoNFT(amho);

        address seller = _amho.ownerOf(_tokenId);

        escrowOrderById[_tokenId] = EscrowOrder({
            buyer: payable(from),
            seller: payable(seller),
            status: EscrowOrderState.DEPOSITED_TOKEN,
            value: amount
        });

        bool success = IERC20(token).transferFrom(
            from,
            address(this),
            amount
        );

        emit DepositedToken(msg.sender, amount);
        return success;
    }

    function depositNFT(address from, uint256 _tokenId)
        external
        returns (bool)
    {
        require(addressSet, "Addresses not set");

        address seller = IERC721A(amho).ownerOf(_tokenId);
        EscrowOrder storage order = escrowOrderById[_tokenId];

        order.seller = payable(from);
        order.status = EscrowOrderState.DEPOSITED_NFT;

        IERC721A(amho).transferFrom(payable(from), address(this), _tokenId);

        emit DepositedNFT(seller, address(amho));

        return true;
    }

    function releaseOrder(uint256 _tokenId, bytes32 _secret)
        external
        secretGated(_tokenId, _secret)
        returns (uint256)
    {
        EscrowOrder memory escrowOrder = escrowOrderById[_tokenId];

        address _buyer = escrowOrder.buyer;
        address _seller = escrowOrder.seller;
        uint256 _value = escrowOrder.value;

        IERC721A(amho).transferFrom(address(this), _buyer, _tokenId);
        IERC20(token).transfer(_seller, _value);

        delete escrowOrderById[_tokenId];

        return _tokenId;
    }

    receive() external payable {
        emit ReceivedNFT(msg.sender, msg.value);
    }

    modifier secretGated(uint256 _tokenId, bytes32 _secret) {
        AmhoNFT _amho = AmhoNFT(amho);
        bytes32 secret = _amho.getSecret(_tokenId);
        require(secret == _secret, "Unauthorized");
        _;
    }
}
