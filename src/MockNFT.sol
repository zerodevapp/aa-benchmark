pragma solidity ^0.8.0;

import "solady/tokens/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 public totalSupply;

    constructor() ERC721() {}

    function name() public view override returns(string memory) {
        return "MockNFT";
    }

    function symbol() public view override returns(string memory) {
        return "MNFT";
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        return string(abi.encodePacked("https://mocknft.com/", tokenId));
    }

    function safeMint(address to) external returns(uint256) {
        _safeMint(to, totalSupply++);
    }
}
