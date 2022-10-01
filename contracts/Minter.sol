// SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/RoyaltySplitter.sol";

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
contract Minter is ERC721Enumerable, ERC2981, Ownable {
    using SafeMath for uint256;

    // Declare an array of splitters to be stored in memory
    RoyaltySplitter[] public splitters;

    // Maximum allowable tokens that can be minted by caller
    uint256 public constant MAX_MINTABLE = 10;

    // Internal mapping of minters and the number of NFTs they have minted.
    mapping(address => uint8) internal minters;

    // Private admin signer of coupons
    address private immutable admin;

    // Public state variable to track the current minting phase
    MintPhase public mintPhase = MintPhase.Locked;

    // Public minting price
    uint256 public mintPrice = 0.05 ether;

    // Public number of available tokens
    uint256 public availableTokens = 1000;

    // Public minter royalty cut
    uint96 public minterRoyaltyCut = 2500;

    // Name token using inherited ERC721 constructor.
    constructor(address adminSigner) ERC721("Minter", "MINTER") {
        admin = adminSigner;
        setRoyaltyInfo(msg.sender, 1000);
    }

    /**
     * @dev Owner only function to set the minting phase.
     * @param _phase The phase to set the contract to.
     */
    function setMintPhase(MintPhase _phase) public onlyOwner {
        require(
            _phase >= MintPhase.Locked && _phase <= MintPhase.PublicSale,
            "Invalid mint phase"
        );
        mintPhase = _phase;
    }

    /**
     * @dev Owner only function to set the minting price.
     * @param price The price to set the contract to.
     */
    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    /**
     * @dev Owner only function to set the number of available tokens.
     * @param _availableTokens The number of available tokens to set the contract to.
     */
    function setAvailableTokens(uint256 _availableTokens) public onlyOwner {
        availableTokens = _availableTokens;
    }

    /**
     * @dev Owner only function to set the minter royalty cut.
     * @param _minterRoyaltyCut The minter royalty cut to set the contract to.
     */
    function setMinterRoyaltyCut(uint96 _minterRoyaltyCut) public onlyOwner {
        require(_minterRoyaltyCut <= 10000, "Royalty cut cannot exceed 100%");
        minterRoyaltyCut = _minterRoyaltyCut;
    }

    /**
     * @dev Owner only function to set the ERC2981 royalty information.
     * @param rcvAddress The address that recieves the royalties.
     * @param feeBasisPoints The fee basis points for the royalties, maximum 10% == 1000 bps.
     */
    function setRoyaltyInfo(address rcvAddress, uint96 feeBasisPoints)
        public
        onlyOwner
    {
        // Require the basis points field to be less then or equal to 10% (1000 bps).
        require(feeBasisPoints <= 1000);

        // Call the ERC2981 default royalty function
        _setDefaultRoyalty(rcvAddress, feeBasisPoints);
    }

    /**
     * @dev Public function to get the array of splitters
     * @return The array of splitters
     */
    function getSplitters() public view returns (RoyaltySplitter[] memory) {
        return splitters;
    }

    /**
     * @dev Get splitter information by index
     */
    function getSplitter(uint256 index)
        public
        view
        returns (
            address payable,
            address payable,
            uint96
        )
    {
        // Protect against over index
        require(index < splitters.length, "Index out of bounds");

        // Get the splitter
        RoyaltySplitter splitter = splitters[index];

        // Return the splitter information
        return (splitter.owner(), splitter.royaltyReciever(), splitter.split());
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
        // Ensure we are minting a legal amount of tokens, we are in the presale phase, and the caller has enough ether to cover the minting.
        require(
            _numberOfTokens > 0 &&
                _numberOfTokens + minters[msg.sender] <= MAX_MINTABLE &&
                mintPhase == MintPhase.PreSale &&
                msg.value >= mintPrice.mul(_numberOfTokens),
            "Invalid minting parameters"
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
        // Ensure we are minting a legal amount of tokens, we are in the public phase, and the caller has enough ether to cover the minting.
        require(
            _numberOfTokens > 0 &&
                _numberOfTokens + minters[msg.sender] <= MAX_MINTABLE &&
                mintPhase == MintPhase.PublicSale &&
                msg.value >= mintPrice.mul(_numberOfTokens),
            "Invalid minting parameters"
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
            // Get the next mint index.
            uint256 mintIndex = totalSupply();

            // Mint the token to the caller, if it's available.
            if (mintIndex < availableTokens) {
                // Update the minters mapping count.
                minters[_to] += 1;

                // Create a new RoyaltySplitter object, put it to the end of the array
                RoyaltySplitter splitter = new RoyaltySplitter(
                    payable(owner()),
                    payable(_to),
                    minterRoyaltyCut
                );
                splitters.push(splitter);

                // Set the token royalty info as specified in the ERC2981 standard - use the address
                // of the newly created splitter to handle the splitting of the royalty between the
                // owner and minter of the NFT.
                _setTokenRoyalty(
                    mintIndex,
                    address(splitters[splitters.length - 1]),
                    1000
                );

                // Mint the token.
                _safeMint(_to, mintIndex);
            }
        }
    }

    /**
     * @dev Pays out the royalties from the sale of an NFT.
     */
    function payRoyalties() public {
        // Loop through the splitters and pay out the royalties.
        for (uint256 i = 0; i < splitters.length; i++) {
            splitters[i].withdraw();
        }
    }

    /**
     * @dev returns true if the contract implements the interface defined by
     * @param interfaceId The interface identifier.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
