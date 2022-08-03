// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import {Escrow} from "contracts/Escrow.sol";
import {Amho} from "contracts/Amho.sol";
import {Utils} from "contracts/MockUtils.sol";

contract AmhoCreator is Test {
    Escrow escrow;
    Amho amho;
    function setUp() public {
        escrow = new Escrow();
        amho = new Amho(payable(address(escrow)));
    }

    function testDeal() public {
        vm.startPrank(Utils.alice);
        vm.deal(Utils.alice, 1 ether);
        console.log(Utils.alice.balance);
    }

    function testMintAndDeposit() public {
        string memory mockURI = Utils.mockURI;
        bytes32 mockSecret = Utils.mockVrf();
        vm.startPrank(Utils.bob);
        uint256 tokenId = amho.mintToken(mockSecret, mockURI, 1);
        address tokenOwner = amho.ownerOf(tokenId);
        assertEq(tokenOwner, Utils.bob);
    }

}
