//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "./EscrowRegistry.sol";

contract AmhoNFT is ERC721Base {
    uint256 private _tokenIds = 0;

    // NOTE: Enum values will be used to show the state of the item on the frontend

    enum ItemState {
        NEW,
        PENDING_INIT,
        PENDING_TETHER,
        TETHERED,
        UNTETHERED
    }

    struct NFTState {
        ItemState itemState;
        uint256 tokenId;
        uint256 price;
        address currentOwner;
        address nextOwner;
        bytes32 secret;
    }

    address payable escrowContractAddress;
    EscrowRegistry escrowContract;

    mapping(uint256 => NFTState) idToNFTState;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltySplitRecipient,
        uint128 _royaltySplitBps,
        address payable _escrowContractAddress
    ) ERC721Base(_name, _symbol, _royaltySplitRecipient, _royaltySplitBps) {
        escrowContractAddress = payable(_escrowContractAddress);
        escrowContract = EscrowRegistry(_escrowContractAddress);
    }

    function getCurrentTokenId() public view returns (uint256) {
        uint256 currTokenId = _tokenIds;
        return currTokenId;
    }

    function getPrice(uint256 _tokenId) public view returns (uint256) {
        return getNFTState(_tokenId).price;
    }

    function getNFTState(uint256 _tokenId)
        public
        view
        returns (NFTState memory)
    {
        return idToNFTState[_tokenId];
    }

    function getSecret(uint256 _tokenId) external view returns (bytes32) {
        NFTState memory orderState = getNFTState(_tokenId);
        return orderState.secret;
    }

    function depositTokenToEscrow(uint256 _tokenId, uint256 _amount) public {
        _depositTokenToEscrow(_tokenId, _amount);
    }

    function _depositTokenToEscrow(uint256 _tokenId, uint256 _amount)
        public
        priceMatch(_tokenId, _amount)
    {
        require(
            escrowContract.depositToken(msg.sender, _tokenId, _amount),
            "Tokens were not able to be deposited."
        );

        NFTState storage nftState = idToNFTState[_tokenId];
        nftState.nextOwner = msg.sender;
        nftState.itemState = ItemState.PENDING_INIT;
    }

    function depositNftToEscrow(uint256 _tokenId, bytes32 _secret) 
        ownerMatch(_tokenId) 
        secretMatch(_tokenId, _secret)
    public {
        _depositNftToEscrow(_tokenId, _secret);
    }

    function _depositNftToEscrow(uint256 _tokenId, bytes32 _secret) public {
        require(
            escrowContract.depositNFT(msg.sender, _tokenId),
            "NFT was not able to be deposited."
        );

        NFTState storage nftState = idToNFTState[_tokenId];
        if (nftState.currentOwner != msg.sender) {
            nftState.currentOwner = msg.sender;
        }

        nftState.itemState = ItemState.PENDING_TETHER;
    }

    function releaseOrderToEscrow(uint256 _tokenId, bytes32 _secret)
        public
        returns (uint256)
    {
        _releaseOrderToEscrow(_tokenId, _secret);
    }

    function _releaseOrderToEscrow(uint256 _tokenId, bytes32 _secret)
        public
        returns (uint256)
    {
        require(msg.sender == idToNFTState[_tokenId].nextOwner);
        NFTState storage nftState = idToNFTState[_tokenId];
        nftState.itemState = ItemState.TETHERED;
        nftState.currentOwner = msg.sender;
        uint256 retTokenId = escrowContract.releaseOrder(_tokenId, _secret);
        return retTokenId;
    }

    function mintNftTo(
        address _to,
        bytes32 secret,
        string memory tokenURI,
        uint256 _price
    ) onlyOwner public payable returns (uint256) {
        uint256 id = _tokenIds;

        setApprovalForAll(escrowContractAddress, true);
        mintTo(_to, tokenURI);

        idToNFTState[id] = NFTState({
            price: _price,
            tokenId: id,
            currentOwner: _to,
            nextOwner: address(0),
            itemState: ItemState.NEW,
            secret: secret
        });

        _tokenIds = _tokenIds += 1;
        // _setTokenURI(id, tokenURI);

        return id;
    }

    // NOTE: Fetch On Sale

    function fetchOnSale() public view returns (NFTState[] memory) {
        uint256 totalCount = _tokenIds;
        uint256 ownedCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idToNFTState[i].itemState == ItemState.NEW) {
                ownedCount++;
            }
        }

        NFTState[] memory inMemItems = new NFTState[](ownedCount);

        for (uint256 i = 0; i < ownedCount; i++) {
            if (idToNFTState[i].itemState == ItemState.NEW) {
                uint256 currentId = idToNFTState[i].tokenId;
                NFTState storage currentItem = idToNFTState[currentId];
                inMemItems[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return inMemItems;
    }

    // NOTE: Fetch Owned

    function fetchOwned() public view returns (NFTState[] memory) {
        uint256 totalCount = _tokenIds;
        uint256 ownedCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idToNFTState[i].currentOwner == msg.sender) {
                ownedCount++;
            }
        }

        NFTState[] memory inMemOwnedItems = new NFTState[](ownedCount);

        for (uint256 i = 0; i < ownedCount; i++) {
            if (idToNFTState[i].currentOwner == msg.sender) {
                uint256 currentId = idToNFTState[i].tokenId;
                NFTState storage currentItem = idToNFTState[currentId];
                inMemOwnedItems[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return inMemOwnedItems;
    }

    // NOTE: PENDING_INIT

    function fetchPendingInitOrders() public view returns (NFTState[] memory) {
        uint256 totalCount = _tokenIds;
        uint256 pendingInitCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (
                idToNFTState[i].itemState == ItemState.PENDING_INIT &&
                (idToNFTState[i].currentOwner == msg.sender ||
                    idToNFTState[i].nextOwner == msg.sender)
            ) {
                pendingInitCount++;
            }
        }

        NFTState[] memory inMemPendingItems = new NFTState[](pendingInitCount);

        for (uint256 i = 0; i < pendingInitCount; i++) {
            uint256 currentId = idToNFTState[i].tokenId;
            NFTState storage currentItem = idToNFTState[currentId];
            inMemPendingItems[currentIndex] = currentItem;
            currentIndex++;
        }
        return inMemPendingItems;
    }

    // NOTE: PENDING_TETHER Case in which just minted or just bought

    function fetchPendingTether() public view returns (NFTState[] memory) {
        uint256 totalCount = _tokenIds;
        uint256 pendingTetherCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (
                ((idToNFTState[i].itemState == ItemState.PENDING_TETHER &&
                    (idToNFTState[i].nextOwner == msg.sender)) ||
                    idToNFTState[i].nextOwner == address(0))
            ) {
                pendingTetherCount++;
            }
        }

        NFTState[] memory inMemPendingItems = new NFTState[](
            pendingTetherCount
        );

        for (uint256 i = 0; i < pendingTetherCount; i++) {
            if (idToNFTState[i].nextOwner == msg.sender) {
                uint256 currentId = idToNFTState[i].tokenId;
                NFTState storage currentItem = idToNFTState[currentId];
                inMemPendingItems[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return inMemPendingItems;
    }

    modifier priceMatch(uint256 _tokenId, uint256 _amount) {
        uint256 price = getPrice(_tokenId);
        require(price == _amount, "Wrong value was sent");
        _;
    }

    modifier ownerMatch(uint256 _tokenId) {
        require(msg.sender == idToNFTState[_tokenId].currentOwner, "Caller is not current owner");
        _;
    }

    modifier secretMatch(uint256 _tokenId, bytes32 _secret) {
        require(_secret == idToNFTState[_tokenId].secret, "Unauthorized");
        _;
    }

    // NOTE: Functions for Lit Protocol

    function getCurrentOwner(uint256 _tokenId) public view returns (address) {
        return idToNFTState[_tokenId].currentOwner;
    }

    function getNextOwner(uint256 _tokenId) public view returns (address) {
        return idToNFTState[_tokenId].nextOwner;
    }
}
