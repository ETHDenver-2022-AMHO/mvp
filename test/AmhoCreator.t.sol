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
        dummyToken = new MockToken();
    }

    function getTokenAddress() public returns (address) {
        return address(dummyToken);
    }
}

contract AmhoCreator is MockToken, BaseSetup {
    function setUp() public override {
        // Setup AMHO address and token address
        BaseSetup.setUp();
        vm.startPrank(Utils.alice);
        _mint(Utils.alice, 1000);
    }

    function testToken() public {
        uint256 bal = balanceOf(Utils.alice);
        console.log(bal);
    }

    function testTokenAddr() public {
        console.log(getTokenAddress());
    }

    // NOTE: Mint and Deposit into escrow contract

    // function testMintAndDeposit() public {
    //     string memory mockURI = Utils.mockURI;
    //     bytes32 mockSecret = Utils.mockVrf();
    //     vm.startPrank(Utils.bob);
    //     uint256 tokenId = amho.mintToken(mockSecret, mockURI, 1);
    //     address tokenOwner = amho.ownerOf(tokenId);
    //     assertEq(tokenOwner, Utils.bob);
    // }
}
