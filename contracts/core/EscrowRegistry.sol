//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thirdweb-dev/contracts/eip/interface/IERC721A.sol";
import "@thirdweb-dev/contracts/eip/interface/IERC721Receiver.sol";

import "../interfaces/IEscrowRegistry.sol";

import "./AmhoNFT.sol";


contract EscrowRegistry is IERC721Receiver {
    address amhoContract;
    address amhoSbtContract;
    address token;
    bool addressSet;

    event ReceivedNFT(address indexed _from, uint256 _tokenId);
    event ReleasedNFT(address indexed _to, uint256 _tokenId);
    event ReceivedToken(address indexed _from, uint256 _amount);
    event ReleasedToken(address indexed _to, uint256 _amount);

    enum EscrowOrderState {
        DEPOSITED_NFT,
        DEPOSITED_TOKEN,
        DISPUTE_NEW,
        DISPUTE_RECEIVED,
        DISPUTE_OVERRIDE,
        DISPUTE_CANCELLED
    }

    struct EscrowOrder {
        address payable currentOwner;
        address payable nextOwner;
        uint256 value;
        EscrowOrderState status;
    }


    mapping(uint256 => EscrowOrder) public escrowOrderById;

    function setTokenAddresses(address _amho, address _token) public {
        amhoContract = _amho;
        token = _token;
        addressSet = true;
    }

    function getTokenAddress() public view returns (address) {
        return token;
    }

    function getEscrowOrderById(uint256 _tokenId)
        public
        view
        returns (EscrowOrder memory)
    {
        return escrowOrderById[_tokenId];
    }

    function getEscrowOrderStateById(uint256 _tokenId) public view returns (EscrowOrderState) {
        return getEscrowOrderById(_tokenId).status;
    }

    function depositToken(
        address _tokenAddress,
        address _from,
        uint256 _tokenId,
        uint256 _value
    ) external returns (bool) {
        require(addressSet, "Addresses not set");

        address _currentOwner = IERC721A(amhoContract).ownerOf(_tokenId);

        escrowOrderById[_tokenId] = EscrowOrder({
            nextOwner: payable(_from),
            currentOwner: payable(_currentOwner),
            status: EscrowOrderState.DEPOSITED_TOKEN,
            value: _value
        });

        bool success = IERC20(token).transferFrom(
            _from,
            address(this),
            _value
        );

        return success;
    }

    function depositNFT(address _from, uint256 _tokenId)
        external
        returns (bool)
    {
        require(addressSet, "Addresses not set");
        address seller = IERC721A(amhoContract).ownerOf(_tokenId);
        EscrowOrder storage order = escrowOrderById[_tokenId];

        order.currentOwner = payable(_from);
        order.status = EscrowOrderState.DEPOSITED_NFT;

        AmhoNFT(amhoContract).safeTransferFrom(
            payable(_from),
            address(this),
            _tokenId
        );

        emit ReceivedNFT(seller, _tokenId);

        return true;
    }

    function releaseOrder(uint256 _tokenId, bytes32 _secretHash)
        external
        returns (uint256)
    {
        require(
            AmhoNFT(amhoContract).getSecret(_tokenId) == _secretHash,
            "Unauthorized"
        );
        EscrowOrder memory escrowOrder = escrowOrderById[_tokenId];

        address _buyer = escrowOrder.nextOwner;
        address _seller = escrowOrder.currentOwner;
        uint256 _value = escrowOrder.value;

        IERC721A(amhoContract).transferFrom(address(this), _buyer, _tokenId);
        IERC20(token).transfer(_seller, _value);

        delete escrowOrderById[_tokenId];

        emit ReleasedNFT(_buyer, _tokenId);
        emit ReleasedToken(_seller, _value);

        return _tokenId;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {
    }
}
