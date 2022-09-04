// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * This is the coupon structure. Coupons are generated off chain so just model the structure here.
 */
struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

/**
 * @title Minter contract
 * @dev Extends ERC721Enumerable Non-Fungible Token Standard
 */
contract Minter is ERC721Enumerable {
    // Maximum allowable tokens that can be minted by caller
    uint256 public constant MAX_MINTABLE = 10;

    // Internal mapping of minters and the number of NFTs they have minted.
    mapping(address => uint8) internal minters;

    // Name token using inherited ERC721 constructor.
    constructor() ERC721("Minter", "MINTER") {}

    /**
     * TODO: This is thie presale minting function. It takes in the number of tokens the caller wishes to mint, and the coupon the caller wishes to use.
     * @dev Mints the number of tokens specified by the caller.
     * @param _numberOfTokens The number of tokens the caller wishes to mint.
     * @param _coupon The coupon the caller wishes to use.
     */
    function presaleMint(uint256 _numberOfTokens, Coupon memory _coupon)
        public
        payable
    {
        // Ensure we are minting at least one token.
        require(_numberOfTokens > 0, "You must mint at least one token.");

        // Ensure the caling address has not minted more then their allowed amount.
        require(
            _numberOfTokens + minters[msg.sender] <= MAX_MINTABLE,
            "You cannot mint more than 10 tokens per address."
        );
    }

    /**
     * TODO: This is the public minting function. It takes in the number of tokens the caller wishes to mint.
     * @dev Mints the number of tokens specified by the caller.
     * @param _numberOfTokens The number of tokens the caller wishes to mint.
     */
    function publicMint(uint256 _numberOfTokens) public payable {}

    /**
     * TODO: This is the internal minting function. It takes the number of tokens the caller wishes to mint and the address of the caller.
     * @dev Mints the number of tokens specified by the caller.
     * @param _numberOfTokens The number of tokens the caller wishes to mint.
     * @param _to The address of the caller.
     */
    function _mintTokens(uint256 _numberOfTokens, address _to) internal {}
}
