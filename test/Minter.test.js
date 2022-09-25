const { assert, expect } = require('chai')
const chai = require('chai')
const BN = require('bn.js')
chai.use(require('chai-as-promised')).should()
chai.use(require('chai-bn')(BN))

describe("RoyaltySplitter", function () {
  /**
   * @dev Test deployment
   */
  describe("deployment", function () {
    it("should deploy successfully", async function () {
      // Owner address
      const owner = "0x7F234922543833d66694F530D4123f86888b50c6"
      // Royalty recipient address, get a hardhat account
      const [account, account1] = await ethers.getSigners()
      // Royalty cut 25%
      const royaltyCut = 2500
      // Deploy the contract
      const RoyaltySplitter = await ethers.getContractFactory("RoyaltySplitter");
      const royaltySplitter = await RoyaltySplitter.deploy(owner, account1.address, royaltyCut);
      contract = await royaltySplitter.deployed();
      const address = contract.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })
  })
  
  /**
   * @dev Test the constructor
   */
  describe("constructor", function () {
    it("should set the owner, recipient, and cut in basis points", async function () {
      // Owner address
      const owner = "0x7F234922543833d66694F530D4123f86888b50c6"
      // Royalty recipient address, get a hardhat account
      const [account, account1] = await ethers.getSigners()
      // Royalty cut 25%
      const royaltyCut = 2500
      // Deploy the contract
      const RoyaltySplitter = await ethers.getContractFactory("RoyaltySplitter");
      const royaltySplitter = await RoyaltySplitter.deploy(owner, account1.address, royaltyCut);
      contract = await royaltySplitter.deployed();
      // Get the owner, recipient, and cut
      const contractOwner = await contract.owner()
      const contractRecipient = await contract.royaltyReciever()
      const contractCut = await contract.split()
      assert.equal(contractOwner, owner)
      assert.equal(contractRecipient, account1.address)
      assert.equal(contractCut, royaltyCut)
    })
  })

  /**
   * @dev Test trying to change the fields
   */
  describe("changing fields", function () {
    it("should not be able to change the fields", async function () {
      // Owner address
      const owner = "0x7F234922543833d66694F530D4123f86888b50c6"
      // Royalty recipient address, get a hardhat account
      const [account, account1] = await ethers.getSigners()
      // Royalty cut 25%
      const royaltyCut = 2500
      // Deploy the contract
      const RoyaltySplitter = await ethers.getContractFactory("RoyaltySplitter");
      const royaltySplitter = await RoyaltySplitter.deploy(owner, account1.address, royaltyCut);
      contract = await royaltySplitter.deployed();
      
      // Try to change the owner through the global
      try {
        await contract.owner(account.address)
        assert.fail("Should not be able to change the owner")
      }
      catch (err) {
        assert.include(err.message, "UNEXPECTED_ARGUMENT")
      }

      // Try to change the recipient through the global
      try {
        await contract.royaltyReciever(account.address)
        assert.fail("Should not be able to change the recipient")
      }
      catch (err) {
        assert.include(err.message, "UNEXPECTED_ARGUMENT")
      }

      // Try to change the cut through the global
      try {
        await contract.split(1000)
        assert.fail("Should not be able to change the cut")
      }
      catch (err) {
        assert.include(err.message, "UNEXPECTED_ARGUMENT")
      }
    })
  })
})

describe("Minter", function () {
  describe('deployment', async function () {
    it('deploys successfully', async function () {
      const adminSigner = "0x7F234922543833d66694F530D4123f86888b50c6"
      const Minter = await ethers.getContractFactory("Minter")
      const minter = await Minter.deploy(adminSigner)
      const contract = await minter.deployed()
      const address = contract.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })
  })

  /**
   * @dev Test setting the mint phase
   */
  describe('setMintPhase', async function () {
    it('sets the mint phase', async function () {
      const adminSigner = "0x7F234922543833d66694F530D4123f86888b50c6"
      const Minter = await ethers.getContractFactory("Minter")
      const minter = await Minter.deploy(adminSigner)
      const contract = await minter.deployed()

      // Make a bunch of mint phases
      const locked = 0
      const preSale = 1
      const publicSale = 2
      const illegal = 3
      const illegal2 = -1

      // Initial state should be locked
      let phase = await contract.mintPhase()
      expect(phase).to.equal(locked)

      // Set the mint phase to preSale
      await contract.setMintPhase(preSale)
      phase = await contract.mintPhase()
      expect(phase).to.equal(preSale)

      // Set the mint phase to publicSale
      await contract.setMintPhase(publicSale)
      phase = await contract.mintPhase()
      expect(phase).to.equal(publicSale)

      // Set the mint phase to locked
      await contract.setMintPhase(locked)
      phase = await contract.mintPhase()
      expect(phase).to.equal(locked)

      // Set the mint phase to illegal, the require() statement should revert
      try {
        await contract.setMintPhase(illegal)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }

      // Set the mint phase to illegal2, the require() statement should revert
      try {
        await contract.setMintPhase(illegal2)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'value out-of-bounds')
      }

      // Try to set the mintPhase through the global
      try {
        await contract.mintPhase(preSale)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'UNEXPECTED_ARGUMENT')
      }

      // Get an account from hardhat
      const [account0, account1] = await ethers.getSigners()

      // Try calling setMintPhase() from an account that is not the admin
      try {
        await contract.connect(account1).setMintPhase(preSale)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }
    })
  })

  /**
   * @dev Test setting and getting the mint price
   */
  describe('setMintPrice', async function () {
    it('sets the mint price', async function () {
      const adminSigner = "0x7F234922543833d66694F530D4123f86888b50c6"
      const Minter = await ethers.getContractFactory("Minter")
      const minter = await Minter.deploy(adminSigner)
      const contract = await minter.deployed()
      
      // Set the mint price to 0.1 ETH
      const mintPrice = ethers.utils.parseEther('0.1')
      await contract.setMintPrice(mintPrice)
      let price = await contract.mintPrice()
      expect(price).to.equal(mintPrice)

      // Try to set the mint phase through the global
      try {
        await contract.mintPrice(mintPrice)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'UNSUPPORTED_OPERATION')
      }

      // Get an account from hardhat
      const [account0, account1] = await ethers.getSigners()

      // Try calling setMintPrice() from an account that is not the admin
      try {
        await contract.connect(account1).setMintPrice(mintPrice)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }
    })
  })

  /**
   * @dev Test setting and getting the royalty information.
   */
  describe('setRoyalty', async function () {
    it('sets the royalty', async function () {
      const adminSigner = "0x7F234922543833d66694F530D4123f86888b50c6"
      const Minter = await ethers.getContractFactory("Minter")
      const minter = await Minter.deploy(adminSigner)
      const contract = await minter.deployed()

      // Check the default royalty information
      // Set a fake sale price of 1 ether
      const salePrice = ethers.utils.parseEther('1')
      // Take 10% of the sale price which is the default
      const royaltyAmt = ethers.utils.parseEther('0.1')
      // Get the address of the contract deployer
      const royaltyAddr = await contract.owner()
      // Make a fake transaction and get the royalty information
      let royalty = await contract.royaltyInfo(0, salePrice)
      expect(royalty[0]).to.equal(royaltyAddr)
      expect(royalty[1]._hex).to.equal(royaltyAmt)

      // Set the royalty address to the admin signer, and the royalty basis points to 500
      const newRoyaltyBasis = 500
      await contract.setRoyaltyInfo(adminSigner, newRoyaltyBasis)
      // Make the new royalty amount
      const newRoyaltyAmt = ethers.utils.parseEther('0.05')
      royalty = await contract.royaltyInfo(0, salePrice)
      expect(royalty[0]).to.equal(adminSigner)
      expect(royalty[1]._hex).to.equal(newRoyaltyAmt)

      // Try to set the royalty information to an illegal value
      try {
        await contract.setRoyaltyInfo(adminSigner, 1001)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }

      // Get an account from hardhat
      const [account0, account1] = await ethers.getSigners()

      // Try calling setRoyaltyInfo() from an account that is not the admin
      try {
        await contract.connect(account1).setRoyaltyInfo(adminSigner, newRoyaltyBasis)
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }
    })
  })

  /**
   * @dev Test public sale minting
   */
  describe('publicMint', async function () {
    it('mints a token in the public sale', async function () {
      const adminSigner = "0x7F234922543833d66694F530D4123f86888b50c6"
      const Minter = await ethers.getContractFactory("Minter")
      const minter = await Minter.deploy(adminSigner)
      const contract = await minter.deployed()

      // Make a bunch of mint phases
      const locked = 0
      const preSale = 1
      const publicSale = 2

      // Get the minting price
      const mintPrice = await contract.mintPrice()
      const badMintPrice = mintPrice.sub(1)

      // Try to mint when the mint phase is not public sale
      try {
        await contract.publicMint(1, {value: mintPrice})
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }

      // Set the mint phase to public sale
      await contract.setMintPhase(publicSale)

      // Try to mint an illegal number of tokens
      try {
        await contract.publicMint(0, {value: mintPrice})
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }

      // Get the maximum number of tokens that can be minted
      const maxMint = await contract.MAX_MINTABLE()

      // Try to mint more than the maximum number of tokens
      try {
        await contract.publicMint(maxMint + 1, {value: mintPrice})
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }

      // Try to mint without paying enough
      try {
        await contract.publicMint(1, { value: badMintPrice })
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }

      // Try to mint multiple without paying enough
      try {
        await contract.publicMint(2, { value: badMintPrice })
        assert.fail('should have thrown before')
      }
      catch (error) {
        assert.include(error.message, 'revert')
      }

      // Get some accounts from hardhat
      const [account0, account1] = await ethers.getSigners()

      // Mint a single token using the non-owner account
      await contract.connect(account1).publicMint(1, { value: mintPrice })

      // Get the splitter array and assert the length
      const splitters = await contract.getSplitters()
      expect(splitters.length).to.equal(1)
      
      // Get the splitter information
      const splitter = await contract.getSplitter(0)

      // Assert the owner address is the owner of the minter contract
      expect(splitter[0]).to.equal(account0.address)

      // Assert the splitter address is the account that minted the token
      expect(splitter[1]).to.equal(account1.address)

      // Assert the splitter amount 2500
      expect(splitter[2].toString()).to.equal("2500")

    })
  })

  describe('fetching', async function () {
    it('fetches data as expected', async function () {
      const adminSigner = "0x7F234922543833d66694F530D4123f86888b50c6"
      const Minter = await ethers.getContractFactory("Minter")
      const minter = await Minter.deploy(adminSigner)
      const contract = await minter.deployed()
      // Request totalSupply from contract.
      const totalSupply = await contract.totalSupply()
      expect(new BN(totalSupply.toString())).to.be.a.bignumber.that.is.at.most('10000')
    })
  })
})

