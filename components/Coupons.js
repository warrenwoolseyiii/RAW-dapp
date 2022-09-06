const {
    keccak256,
    toBuffer,
    ecsign,
    bufferToHex,
} = require("ethereumjs-util");
const { ethers } = require('ethers');

// Enumeration of coupon types that matches the smart contract in Minter.sol
const CouponTypeEnum = {
    Contributor: 0,
    BAYCHolder: 1,
    GiveAway: 2,
};

/** Generate a bunch of coupons in one go:
let coupons = {};
for (let i = 0; i < presaleAddresses.length; i++) {
    const userAddress = ethers.utils.getAddress(presaleAddresses[i]);
    const hashBuffer = generateHashBuffer(
        ["uint256", "address"],
        [CouponTypeEnum["Presale"], userAddress]
    );
    const coupon = createCoupon(hashBuffer, signerPvtKey);

    coupons[userAddress] = {
        coupon: serializeCoupon(coupon)
    };
}
*/

// Generate a single coupon from the command line
presaelAddress = "0x0000000000000000000000000000000000000000";
signerPrivateKey = "0x0000000000000000000000000000000000000000000000000000000000000000";
process.argv.forEach(function (val, index, array) {
    if (index == 2) {
        presaelAddress = val;
        console.log("Address: " + presaelAddress);
    }
    if (index == 3) {
        signerPrivateKey = val;
        console.log("Private Key: " + signerPrivateKey);
    }
});

// Convert the user address from a string to a buffer
const userAddress = ethers.utils.getAddress(presaelAddress);

// Convert the signer address from a string to a Uint8Array
const signerPvtKey = ethers.utils.arrayify(signerPrivateKey);

const hashBuffer = generateHashBuffer(["uint256", "address"], [CouponTypeEnum["Contributor"], userAddress]);
const coupon = createCoupon(hashBuffer, signerPvtKey);
console.log("Generated coupon for address: " + userAddress);
printCoupon(coupon);

// Create a coupon object from a hash and a private key
function createCoupon(hash, signerPvtKey) {
    return ecsign(hash, signerPvtKey);
}

// Generate a hash buffer from a list of types and values
function generateHashBuffer(typesArray, valueArray) {
    return keccak256(
        toBuffer(ethers.utils.defaultAbiCoder.encode(typesArray,
            valueArray))
    );
}

// Serialize the coupons object to a JSON string
function serializeCoupon(coupon) {
    return {
        r: bufferToHex(coupon.r),
        s: bufferToHex(coupon.s),
        v: coupon.v,
    };
}

// Print a coupon to hex strings format
function printCoupon(coupon) {
    console.log("r: " + bufferToHex(coupon.r));
    console.log("s: " + bufferToHex(coupon.s));
    console.log("v: " + coupon.v);
}