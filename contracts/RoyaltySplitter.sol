// SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.8.4;

/**
 * @title Royalty splitter
 * @dev Just split the royalties
 */
contract RoyaltySplitter {
    // Public payable owner address
    address payable public immutable owner;

    // Royalty reciever
    address payable public immutable royaltyReciever;

    // Split
    uint96 public split;

    /**
     * @dev Constructor, set the owner address, royalty reciever address and split.
     */
    constructor(
        address payable _owner,
        address payable _royaltyReciever,
        uint96 _split
    ) {
        owner = _owner;
        royaltyReciever = _royaltyReciever;
        // Split cannot exceed 100%
        if (_split <= 10000) split = _split;
        else split = 10000;
    }

    /**
     * @dev Withdraw the balance of this contract to the owner and royalty reciever.
     */
    function withdraw() public {
        // Get the balance of this contract in wei
        uint256 balance = address(this).balance;

        // Calculate the split
        uint256 royaltySplit = (balance * split) / 10000;
        uint256 ownerSplit = balance - royaltySplit;

        // Send the ether to the correct parties
        (bool royaltyRec, ) = royaltyReciever.call{value: royaltySplit}("");
        (bool ownerRec, ) = owner.call{value: ownerSplit}("");
        
        // Revert if ether transfer fails
        require(royaltyRec && ownerRec, "Transfer failed");
    }

    /**
     * @dev Recieve Ether.
     */
    receive() external payable {
        // As soon as its received, split it
        withdraw();
    }
}
