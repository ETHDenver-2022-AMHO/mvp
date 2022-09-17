//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/LazyMint.sol";

import "./EscrowRegistry.sol";

contract AmhoNFT is ERC721Base, LazyMint {
    EscrowRegistry escrowContract;
    address physicalRegistry;
    uint256 private _tokenIds;

    // NOTE: Enum values will be used to show the state of the item on the frontend

    enum ItemState {
        NEW,
        PENDING_INIT,
        PENDING_TETHER,
        TETHERED,
        UNTETHERED
    }

    struct NFTMetadata {
        ItemState itemState;
        uint256 tokenId;
        uint256 price;
        address currentOwner;
        address nextOwner;
        bytes32 secretHash;
    }

    mapping(uint256 => NFTMetadata) idToNFTMetadata;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltySplitRecipient,
        uint128 _royaltySplitBps,
        address payable _escrowContractAddress,
        address _physicalRegistryAddress
    ) ERC721Base(_name, _symbol, _royaltySplitRecipient, _royaltySplitBps) {
        escrowContract = EscrowRegistry(_escrowContractAddress);
        physicalRegistry = _physicalRegistryAddress;
    }

    function getCurrentTokenId() public view returns (uint256) {
        uint256 currTokenId = nextTokenIdToMint();
        return currTokenId;
    }

    function getPrice(uint256 _tokenId) public view returns (uint256) {
        return getNFTMetadata(_tokenId).price;
    }

    function getNFTMetadata(uint256 _tokenId)
        public
        view
        returns (NFTMetadata memory)
    {
        return idToNFTMetadata[_tokenId];
    }

    function getSecret(uint256 _tokenId) public view returns (bytes32) {
        bytes32 _secretHash = idToNFTMetadata[_tokenId].secretHash;
        return _secretHash;
    }

    function depositTokenToEscrow(uint256 _tokenId, uint256 _amount)
        public
        priceMatch(_tokenId, _amount)
    {
        _depositTokenToEscrow(_tokenId, _amount);
    }

    function _depositTokenToEscrow(uint256 _tokenId, uint256 _amount) public {
        address _tokenAddr = escrowContract.getTokenAddress();
        require(
            escrowContract.depositToken(
                _tokenAddr,
                msg.sender,
                _tokenId,
                _amount
            ),
            "Tokens were not able to be deposited."
        );

        NFTMetadata storage nftState = idToNFTMetadata[_tokenId];
        nftState.nextOwner = msg.sender;
        nftState.itemState = ItemState.PENDING_INIT;
    }

    function depositNftToEscrow(uint256 _tokenId, bytes32 _secretHash)
        public
    {
        _depositNftToEscrow(_tokenId, _secretHash);
    }

    function _depositNftToEscrow(uint256 _tokenId, bytes32 _secretHash) public secretMatch(_tokenId, _secretHash) {
        require(
            escrowContract.depositNFT(msg.sender, _tokenId),
            "NFT was not able to be deposited."
        );

        NFTMetadata storage nftState = idToNFTMetadata[_tokenId];

        if (nftState.currentOwner != msg.sender) {
            nftState.currentOwner = msg.sender;
        }

        nftState.itemState = ItemState.PENDING_TETHER;
    }

    function releaseOrderToEscrow(uint256 _tokenId, bytes32 _secretHash)
        public
        secretMatch(_tokenId, _secretHash)
        returns (uint256)
    {
        _releaseOrderToEscrow(_tokenId, _secretHash);
    }

    function _releaseOrderToEscrow(uint256 _tokenId, bytes32 _secretHash)
        public
        returns (uint256)
    {
        require(
            msg.sender == idToNFTMetadata[_tokenId].nextOwner
        );
        NFTMetadata storage nftState = idToNFTMetadata[_tokenId];
        nftState.itemState = ItemState.TETHERED;
        nftState.currentOwner = msg.sender;
        uint256 retTokenId = escrowContract.releaseOrder(_tokenId, _secretHash);
        return retTokenId;
    }

    function mintNftTo(
        address _to,
        bytes32 _secretHash,
        string memory tokenURI,
        uint256 _price
    ) public payable onlyOwner returns (uint256) {
        uint256 id = getCurrentTokenId();

        setApprovalForAll(address(escrowContract), true);
        mintTo(_to, tokenURI);

        idToNFTMetadata[id] = NFTMetadata({
            price: _price,
            tokenId: id,
            itemState: ItemState.NEW,
            currentOwner: _to,
            nextOwner: address(0),
            secretHash:_secretHash 
        });

        return id;
    }

    // NOTE: Fetch On Sale

    function fetchOnSale() public view returns (NFTMetadata[] memory) {
        uint256 totalCount = getCurrentTokenId();
        uint256 ownedCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idToNFTMetadata[i].itemState == ItemState.NEW) {
                ownedCount++;
            }
        }

        NFTMetadata[] memory inMemItems = new NFTMetadata[](ownedCount);

        for (uint256 i = 0; i < ownedCount; i++) {
            if (idToNFTMetadata[i].itemState == ItemState.NEW) {
                uint256 currentId = idToNFTMetadata[i].tokenId;
                NFTMetadata storage currentItem = idToNFTMetadata[currentId];
                inMemItems[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return inMemItems;
    }

    // NOTE: Fetch Owned

    function fetchOwned() public view returns (NFTMetadata[] memory) {
        uint256 totalCount = getCurrentTokenId();
        uint256 ownedCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idToNFTMetadata[i].currentOwner == msg.sender) {
                ownedCount++;
            }
        }

        NFTMetadata[] memory inMemOwnedItems = new NFTMetadata[](ownedCount);

        for (uint256 i = 0; i < ownedCount; i++) {
            if (idToNFTMetadata[i].currentOwner == msg.sender) {
                uint256 currentId = idToNFTMetadata[i].tokenId;
                NFTMetadata storage currentItem = idToNFTMetadata[currentId];
                inMemOwnedItems[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return inMemOwnedItems;
    }

    // NOTE: PENDING_INIT

    function fetchPendingInitOrders() public view returns (NFTMetadata[] memory) {
        uint256 totalCount = getCurrentTokenId();
        uint256 pendingInitCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (
                idToNFTMetadata[i].itemState == ItemState.PENDING_INIT &&
                (idToNFTMetadata[i].currentOwner == msg.sender ||
                    idToNFTMetadata[i].nextOwner == msg.sender)
            ) {
                pendingInitCount++;
            }
        }

        NFTMetadata[] memory inMemPendingItems = new NFTMetadata[](pendingInitCount);

        for (uint256 i = 0; i < pendingInitCount; i++) {
            uint256 currentId = idToNFTMetadata[i].tokenId;
            NFTMetadata storage currentItem = idToNFTMetadata[currentId];
            inMemPendingItems[currentIndex] = currentItem;
            currentIndex++;
        }
        return inMemPendingItems;
    }

    // NOTE: PENDING_TETHER Case in which just minted or just bought

    function fetchPendingTether() public view returns (NFTMetadata[] memory) {
        uint256 totalCount = getCurrentTokenId();
        uint256 pendingTetherCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (
                ((idToNFTMetadata[i].itemState == ItemState.PENDING_TETHER &&
                    (idToNFTMetadata[i].nextOwner == msg.sender)) ||
                    idToNFTMetadata[i].nextOwner == address(0))
            ) {
                pendingTetherCount++;
            }
        }

        NFTMetadata[] memory inMemPendingItems = new NFTMetadata[](
            pendingTetherCount
        );

        for (uint256 i = 0; i < pendingTetherCount; i++) {
            if (idToNFTMetadata[i].nextOwner == msg.sender) {
                uint256 currentId = idToNFTMetadata[i].tokenId;
                NFTMetadata storage currentItem = idToNFTMetadata[currentId];
                inMemPendingItems[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return inMemPendingItems;
    }

    modifier priceMatch(uint256 _tokenId, uint256 _amount) {
        uint256 price = getPrice(_tokenId);
        require(price == _amount, "Wrong amount was sent");
        _;
    }

    modifier ownerMatch(uint256 _tokenId) {
        require(
            msg.sender == idToNFTMetadata[_tokenId].currentOwner,
            "Caller is not current owner"
        );
        _;
    }

    modifier nextOwnerMatch(uint256 _tokenId) {
        require(msg.sender == idToNFTMetadata[_tokenId].nextOwner);
        _;
    }

    modifier secretMatch(uint256 _tokenId, bytes32 _secretHash) {
        require(_secretHash == idToNFTMetadata[_tokenId].secretHash, "Unauthorized");
        _;
    }

    // NOTE: Functions for Lit Protocol

    function getCurrentOwner(uint256 _tokenId) public view returns (address) {
        return idToNFTMetadata[_tokenId].currentOwner;
    }

    function getApprovedOwner(uint256 _tokenId) public view returns (address) {
        return idToNFTMetadata[_tokenId].nextOwner;
    }
    function _canLazyMint() internal view override returns (bool) {
        // Your custom implementation here
    }
}
