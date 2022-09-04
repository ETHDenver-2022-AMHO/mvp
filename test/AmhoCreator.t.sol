// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import {EscrowRegistry} from "contracts/core/EscrowRegistry.sol";
import {EscrowVerifier} from "contracts/core/EscrowVerifier.sol";
import {AmhoNFT} from "contracts/core/AmhoNFT.sol";
import {MockToken} from "contracts/mock/MockToken.sol";
import {Utils} from "contracts/mock/MockUtils.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721A} from "@thirdweb-dev/contracts/eip/interface/IERC721A.sol";

contract BaseSetup is Test {
    EscrowRegistry internal escrow;
    AmhoNFT internal amho;
    ERC20 public dummyToken;

    function setUp() public virtual {
        // Setup AMHO address and token address
        escrow = new EscrowRegistry();
        amho = new AmhoNFT(
            "Amho",
            "BAG",
            address(0x0),
            10,
            payable(address(escrow))
        );
        dummyToken = new MockToken(Utils.bob, Utils.alice);
        escrow.setTokenAddresses(address(amho), address(dummyToken));
    }

    function getTokenAddress() public view returns (address) {
        return address(dummyToken);
    }
}

contract EscrowSetup is BaseSetup {
    function baseSetup() public virtual {
        BaseSetup.setUp();
    }
    function depositSetup() internal {
        string memory mockURI = Utils.mockURI;
        bytes32 mockSecret = Utils.mockVrf();
        uint256 startTokenId = BaseSetup.amho.getCurrentTokenId();
        uint256 tokenId = BaseSetup.amho.mintNftTo(Utils.bob, mockSecret, mockURI, 1);

        vm.startPrank(Utils.bob);
        BaseSetup.amho.approve(address(escrow), tokenId);
        BaseSetup.amho.depositNftToEscrow(tokenId, mockSecret);
        vm.stopPrank();


        vm.startPrank(Utils.alice);
        address tokenAddress = BaseSetup.getTokenAddress();
        IERC20(tokenAddress).approve(address(escrow), 1);
        amho.depositTokenToEscrow(tokenId, 1);
        vm.stopPrank();
    }
}

contract AmhoCreator is EscrowSetup {
    event DepositedNFT(address indexed seller, address tokenAddress);

    function setUp() public override {
        // Setup AMHO address and token address
        EscrowSetup.baseSetup();
    }

    function testMintAndDepositNft() public {
        EscrowSetup.depositSetup();
        address tokenOwner = BaseSetup.amho.ownerOf(0);
        assertEq(tokenOwner, address(BaseSetup.escrow));
    }

    function testMintAndDepositToken() public {
        EscrowSetup.depositSetup();
        address tokenAddress = BaseSetup.getTokenAddress();
        assertEq(IERC20(tokenAddress).balanceOf(Utils.alice), 999);
        assertEq(IERC20(tokenAddress).balanceOf(address(escrow)), 1);
    }
}
