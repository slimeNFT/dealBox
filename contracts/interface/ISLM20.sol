pragma solidity ^0.8.0;

interface ISLM20 {
    function mint(address to, uint256 amount) external returns (bool);
}
