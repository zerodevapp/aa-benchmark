pragma solidity ^0.8.0;

import "solady/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    function name() public pure override returns (string memory) {
        return "MockERC20";
    }

    function symbol() public pure override returns (string memory) {
        return "MERC20";
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
