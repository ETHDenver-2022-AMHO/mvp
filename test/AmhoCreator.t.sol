// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import {EscrowRegistry} from "contracts/core/EscrowRegistry.sol";
import {AmhoNFT} from "contracts/core/AmhoNFT.sol";
import {MockToken} from "contracts/mock/MockToken.sol";
import {Utils} from "contracts/mock/MockUtils.sol";

contract BaseSetup is Test {
    EscrowRegistry internal escrow;
    AmhoNFT internal amho;
    MockToken internal dummyToken;

    function setUp() public virtual {
        // Setup AMHO address and token address
        escrow = new EscrowRegistry();
        amho = new AmhoNFT("Amho", "BAG", address(0x0), 10, payable(address(escrow)));
        escrow.setTokenAddresses(address(amho), address(escrow));
        dummyToken = new MockToken();
    }

    function getTokenAddress() public returns (address) {
        return address(dummyToken);
    }
}

contract AmhoCreator is MockToken, BaseSetup {
    event DepositedNFT(address indexed seller, address tokenAddress);
    function setUp() public override {
        // Setup AMHO address and token address
        BaseSetup.setUp();
        _mint(Utils.alice, 1000);
        _mint(Utils.bob, 1000);
    }

    function testToken() public {
        uint256 balAlice = balanceOf(Utils.alice);
        uint256 balBob = balanceOf(Utils.bob);
        console.log(balAlice);
        console.log(balBob);
    }

    function testTokenAddr() public {
        console.log(getTokenAddress());
    }


    // NOTE: Mint and Deposit into escrow contract

    function testMintAndDepositNft() public {
        string memory mockURI = Utils.mockURI;
        bytes32 mockSecret = Utils.mockVrf();
        uint256 tokenId = amho.mintNftTo(Utils.bob, mockSecret, mockURI, 1);
        address tokenOwner = amho.ownerOf(tokenId);
        assertEq(tokenOwner, Utils.bob);

        vm.startPrank(Utils.bob);
        amho.approve(address(escrow), tokenId);
        amho.depositNftToEscrow(tokenId, mockSecret);
        vm.stopPrank();
    }

}
