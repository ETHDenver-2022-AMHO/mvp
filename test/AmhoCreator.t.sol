// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import {IERC721A} from "@thirdweb-dev/contracts/eip/interface/IERC721A.sol";

import {EscrowRegistry} from "contracts/core/EscrowRegistry.sol";

import {AmhoNFT} from "contracts/core/AmhoNFT.sol";
import {MockToken} from "contracts/mock/MockToken.sol";

import {Utils} from "contracts/mock/MockUtils.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BaseSetup is Test {
    EscrowRegistry internal setupEscrow;
    AmhoNFT internal setupAmhoNFT;
    ERC20 public setupToken;

    string setupName = "AMHO";
    string setupSymbol = "AMHO";
    address setupRoyalty = address(0x0);
    address setupRegistry = address(0x3);
    uint128 setupRoyaltyBps = 100;

    function setUp() public virtual {
        // Setup AMHO address and token address
    setupEscrow = new EscrowRegistry();
    address payable setupPayableEscrow = payable(address(setupEscrow));

        setupAmhoNFT = new AmhoNFT(
            setupName,
            setupSymbol,
            setupRoyalty,
            setupRoyaltyBps,
            setupPayableEscrow,
            setupRegistry
        );
        setupToken = new MockToken(Utils.bob, Utils.alice);
        setupEscrow.setTokenAddresses(address(setupAmhoNFT), address(setupToken));
    }

    function getTokenAddress() public view returns (address) {
        return address(setupToken);
    }
}

contract EscrowSetup is BaseSetup {
    uint256 startTokenId;
    uint256 currentTokenId;
    function escrowSetup() public virtual {
        BaseSetup.setUp();
    }
    function depositNFTSetup() internal {
        string memory mockURI = Utils.mockURI;
        bytes32 mockSecret = Utils.mockVrf();

        startTokenId = BaseSetup.setupAmhoNFT.getCurrentTokenId();
        currentTokenId = BaseSetup.setupAmhoNFT.mintNftTo(Utils.bob, mockSecret, mockURI, 1);

        vm.startPrank(Utils.bob);
        BaseSetup.setupAmhoNFT.approve(address(setupEscrow), currentTokenId);
        BaseSetup.setupAmhoNFT.depositNftToEscrow(currentTokenId, mockSecret);
        vm.stopPrank();


    }

    function depositTokenSetup() public {
        vm.startPrank(Utils.alice);
        address tokenAddress = BaseSetup.getTokenAddress();
        IERC20(tokenAddress).approve(address(setupEscrow), 1);
        BaseSetup.setupAmhoNFT.depositTokenToEscrow(currentTokenId, 1);
        vm.stopPrank();
    }
}

contract AmhoCreator is EscrowSetup {
    event DepositedNFT(address indexed seller, address tokenAddress);
    function setUp() public override {
        // Setup AMHO address and token address
        EscrowSetup.escrowSetup();
    }

    function testMintAndDepositNft() public {
        EscrowSetup.depositNFTSetup();
        address tokenOwner = BaseSetup.setupAmhoNFT.ownerOf(0);
        assertEq(tokenOwner, address(BaseSetup.setupEscrow));
    }

    function testMintAndDepositToken() public {
        EscrowSetup.depositNFTSetup();
        EscrowSetup.depositTokenSetup();
        address tokenAddress = BaseSetup.getTokenAddress();
        assertEq(IERC20(tokenAddress).balanceOf(Utils.alice), 999);
        assertEq(IERC20(tokenAddress).balanceOf(address(setupEscrow)), 1);
    }
}
