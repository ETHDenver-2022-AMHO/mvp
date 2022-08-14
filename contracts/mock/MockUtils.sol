pragma solidity ^0.8.0;
library Utils {
    address constant alice = address(0x1); 
    address constant bob = address(0x2); 
    address constant tokenAddr = address(0x3);
    string constant mockURI = "https://amho.xyz";
    function mockVrf() public view returns (bytes32) {
        return keccak256(abi.encode(block.timestamp));
    }
}