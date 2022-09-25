const hre = require("hardhat");

async function main() {
  // TODO: read the admin signer from the config
  const adminSigner = "0x7F234922543833d66694F530D4123f86888b50c6"
  const Minter = await hre.ethers.getContractFactory("Minter");
  const minter = await Minter.deploy(adminSigner);
  await minter.deployed();
  console.log("Minter deployed to:", minter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
