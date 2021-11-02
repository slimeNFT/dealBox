pragma solidity ^0.8.0;

interface IBlindBox {
    function mint(address to_, uint boxID_, uint num_) external returns (bool);
    function mintBatch(address to_, uint[] memory boxIDs_, uint256[] memory nums_) external returns (bool);
    function burn(address from_, uint boxID_, uint256 num_) external;
    function burnBatch(address from_, uint[] memory boxIDs_, uint256[] memory nums_) external;
}
