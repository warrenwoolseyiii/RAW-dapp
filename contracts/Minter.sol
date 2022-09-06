// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * This is the coupon structure. Coupons are generated off chain so just model the structure here.
 */
struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

/**
 * Enum for the different phases of minting.
 */
enum MintPhase {
    Locked,
    PreSale,
    PublicSale
}

/**
 * Enumeration for coupon types
 */
enum CouponType {
    Contributor,
    BAYCHolder,
    GiveAway
}

/**
 * @title Minter contract
 * @dev Extends ERC721Enumerable Non-Fungible Token Standard
 */
contract Minter is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    // Maximum allowable tokens that can be minted by caller
    uint256 public constant MAX_MINTABLE = 10;

    // Internal mapping of minters and the number of NFTs they have minted.
    mapping(address => uint8) internal minters;

    // Private admin signer of coupons
    address private admin;

    // Internal state variable to track the current minting phase
    MintPhase private mintPhase = MintPhase.Locked;

    // Internal minting price
    uint256 private mintPrice = 0.05 ether;

    // Internal number of available tokens
    uint256 private availableTokens = 1000;

    // Name token using inherited ERC721 constructor.
    constructor(address adminSigner) ERC721("Minter", "MINTER") {
        admin = adminSigner;
    }

    /**
     * @dev Owner only function to set the minting phase.
     * @param phase The phase to set the contract to.
     */
    function setMintPhase(MintPhase phase) public onlyOwner {
        mintPhase = phase;
    }

    /**
     * @dev Owner only function to set the minting price.
     * @param price The price to set the contract to.
     */
    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    /**
     * @dev This internal function is used to take the bytes digest and coupon passed in, and verify if its valid or not.
     * @param digest - The digest of the coupon
     * @param coupon - The coupon itself
     * @return bool - True if valid, false if not
     */
    function _verifyCoupon(bytes32 digest, Coupon memory coupon)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == admin;
    }

    /**
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

        // Ensure we are currently in the presale phase.
        require(mintPhase == MintPhase.PreSale, "Presale is not active.");

        // Ensure that there are enough tokens left to mint.
        require(
            totalSupply().add(_numberOfTokens) <= availableTokens,
            "Not enough tokens left to mint."
        );

        // Ensure the calling address has not minted more then their allowed amount.
        require(
            _numberOfTokens + minters[msg.sender] <= MAX_MINTABLE,
            "You cannot mint more than 10 tokens per address."
        );

        // Ensure the caller has sent enough ether to cover the minting price.
        require(
            msg.value >= mintPrice.mul(_numberOfTokens),
            "You must send enough ether to cover the minting price."
        );

        // TODO: Verify the coupon is valid.

        // Call the internal mint function
        _mintTokens(_numberOfTokens, msg.sender);
    }

    /**
     * @dev Mints the number of tokens specified by the caller.
     * @param _numberOfTokens The number of tokens the caller wishes to mint.
     */
    function publicMint(uint256 _numberOfTokens) public payable {
        // Ensure we are minting at least one token.
        require(_numberOfTokens > 0, "You must mint at least one token.");

        // Ensure we are currently in the public sale phase.
        require(
            mintPhase == MintPhase.PublicSale,
            "Public sale is not active."
        );

        // Ensure that there are enough tokens left to mint.
        require(
            totalSupply().add(_numberOfTokens) <= availableTokens,
            "Not enough tokens left to mint."
        );

        // Ensure the calling address has not minted more then their allowed amount.
        require(
            _numberOfTokens + minters[msg.sender] <= MAX_MINTABLE,
            "You cannot mint more than 10 tokens per address."
        );

        // Ensure the caller has sent enough ether to cover the minting price.
        require(
            msg.value >= mintPrice.mul(_numberOfTokens),
            "You must send enough ether to cover the minting price."
        );

        // Call the internal mint function
        _mintTokens(_numberOfTokens, msg.sender);
    }

    /**
     * @dev Mints the number of tokens specified by the caller.
     * @param _numberOfTokens The number of tokens the caller wishes to mint.
     * @param _to The address of the caller.
     */
    function _mintTokens(uint256 _numberOfTokens, address _to) internal {
        // For each token requested, mint one.
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < availableTokens) {
                /**
                 * Mint token using inherited ERC721 function
                 * _to is the wallet address of mint requester
                 * mintIndex is used for the tokenId (must be unique)
                 */
                _safeMint(_to, mintIndex);
            }
        }
    }
}
