// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {DSTest} from "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {ProxyTester} from "contracts/test/ProxyTester.sol";
import {AmhoNFT} from "contracts/core/AmhoNFT.sol";

/*
TODO:
- Create a test to showcase the library
- Go over the cheatcodes + OZ docs and think of tests you can add into the code
- Add cheatcodes for added functionality (e.g storage slot) into the tester
*/

contract UpgradeTest is DSTest {
    string testName = "test";    
    string testSym = "TEST";
    address testRoyaltySplitRecipient = address(100);
    uint128 testRoyaltySplitBps = uint128(10000);
    address payable testEscrowContractAddress = payable(address(99));

    ProxyTester proxy;

    AmhoNFT impl;

    address proxyAddress;

    address admin;

    Vm constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function setUp() public {
        proxy = new ProxyTester();
        impl = new AmhoNFT(testName, testSym, testRoyaltySplitRecipient, testRoyaltySplitBps, testEscrowContractAddress);
        admin = vm.addr(69);
    }

    function testDeployUUPS() public {
        proxy.setType("uups");
        proxyAddress = proxy.deploy(address(impl), admin);
        assertEq(proxyAddress, proxy.proxyAddress());
        assertEq(proxyAddress, address(proxy.uups()));
        bytes32 implSlot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );
        bytes32 proxySlot = vm.load(proxyAddress, implSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }
        assertEq(address(impl), addr);
    }

    function testUpgradeUUPS() public {
        testDeployUUPS();
        AmhoNFT newImpl = new AmhoNFT(testName, testSym, testRoyaltySplitRecipient, testRoyaltySplitBps, testEscrowContractAddress);
        /// Since the admin is an EOA, it doesn't have an owner
        proxy.upgrade(address(newImpl), admin, address(0));
        bytes32 implSlot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );
        bytes32 proxySlot = vm.load(proxyAddress, implSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }
        assertEq(address(newImpl), addr);
    }

    function testDeployBeacon() public {
        proxy.setType("beaconProxy");
        // I will need an extra ProxyTester to become the beacon
        ProxyTester beaconTester = new ProxyTester();
        beaconTester.setType("beacon");
        beaconTester.deploy(address(impl));
        proxy.deploy(address(beaconTester.beacon()));
        assertEq(address(impl), beaconTester.beacon().implementation());
        bytes32 beaconSlot = bytes32(
            uint256(keccak256("eip1967.proxy.beacon")) - 1
        );
        bytes32 proxySlot = vm.load(proxy.proxyAddress(), beaconSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }
        assertEq(addr, beaconTester.beaconAddress());
    }
}
