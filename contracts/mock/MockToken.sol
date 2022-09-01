pragma solidity ^0.8.0;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockToken is ERC20 {
    constructor(address _bob, address _alice) ERC20("MockToken", "MOCK") {
        _mint(_bob, 1000);
        _mint(_alice, 1000);
    }
}