// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import {EscrowRegistry} from "contracts/core/EscrowRegistry.sol";
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

contract AmhoCreator is BaseSetup {
    event DepositedNFT(address indexed seller, address tokenAddress);

    function setUp() public override {
        // Setup AMHO address and token address
        BaseSetup.setUp();
    }

    function testMintAndDepositNft() public {
        string memory mockURI = Utils.mockURI;
        bytes32 mockSecret = Utils.mockVrf();
        uint256 startTokenId = amho.getCurrentTokenId();
        uint256 tokenId = amho.mintNftTo(Utils.bob, mockSecret, mockURI, 1);
        address tokenOwner = amho.ownerOf(tokenId);
        assertEq(tokenOwner, Utils.bob);
        assertEq(startTokenId, tokenId);

        vm.startPrank(Utils.bob);
        amho.approve(address(escrow), tokenId);
        amho.depositNftToEscrow(tokenId, mockSecret);
        vm.stopPrank();
    }

    function testBalance() public {
        address tokenAddress = BaseSetup.getTokenAddress();
        uint256 bobBal = IERC20(tokenAddress).balanceOf(Utils.alice);
        uint256 aliceBal = IERC20(tokenAddress).balanceOf(Utils.bob);
        assertEq(bobBal, 1000);
        assertEq(aliceBal, 1000);
    }

    function testMintAndDepositToken() public {
        string memory mockURI = Utils.mockURI;
        bytes32 mockSecret = Utils.mockVrf();
        uint256 tokenId = amho.mintNftTo(Utils.bob, mockSecret, mockURI, 1);
        address tokenAddress = BaseSetup.getTokenAddress();

        vm.startPrank(Utils.bob);
        amho.approve(address(escrow), tokenId);
        amho.depositNftToEscrow(tokenId, mockSecret);
        assertEq(amho.ownerOf(tokenId), address(escrow));
        vm.stopPrank();

        vm.startPrank(Utils.alice);
        IERC20(tokenAddress).approve(address(escrow), 1);
        amho.depositTokenToEscrow(tokenId, 1);
        assertEq(IERC20(tokenAddress).balanceOf(Utils.alice), 999);
        assertEq(IERC20(tokenAddress).balanceOf(address(escrow)), 1);
        vm.stopPrank();
    }
}
