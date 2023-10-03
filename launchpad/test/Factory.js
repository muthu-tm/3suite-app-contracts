const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    const pricePerTxn = 5000000000000000;

    // Contracts are deployed using the first signer/account by default
    const [owner] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("LaunchpadFactory");
    const factory = await Factory.deploy(pricePerTxn);

    return { factory, pricePerTxn, owner };
  }

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { factory, pricePerTxn } = await loadFixture(deployOneYearLockFixture);

      console.log("pricePerTxn: ", pricePerTxn)
      expect(await factory.pricePerSale()).to.equal(pricePerTxn);
    });

    it("Should set the right owner", async function () {
      const { factory, owner } = await loadFixture(deployOneYearLockFixture);

      expect(await factory.owner()).to.equal(owner.address);
    });

    it("Should receive and store the funds to lock", async function () {
      const { factory, pricePerTxn } = await loadFixture(
        deployOneYearLockFixture
      );

      const _pricePerTxn = "500000000000000000";
      await factory.updatePricePerSale(_pricePerTxn);

      expect(await factory.pricePerSale()).to.equal(_pricePerTxn);
    });

    it("Should update the Token Whitelist", async function () {
      const { factory, pricePerTxn } = await loadFixture(
        deployOneYearLockFixture
      );

      const [addr1, addr2] = await ethers.getSigners();
      await factory.addTokenToWhitelist(addr1);
      expect(await factory.tokenWhitelist(addr1)).to.equal(true);
      expect(await factory.tokenWhitelist(addr2)).to.equal(false);
    });

    it("Should update and remove the Token Whitelist", async function () {
      const { factory, pricePerTxn } = await loadFixture(
        deployOneYearLockFixture
      );

      const [addr1, addr2] = await ethers.getSigners();
      await factory.addTokenToWhitelist(addr1);
      expect(await factory.tokenWhitelist(addr1)).to.equal(true);

      await factory.removeTokenFromWhitelist(addr1);
      expect(await factory.tokenWhitelist(addr1)).to.equal(false);
      expect(await factory.tokenWhitelist(addr2)).to.equal(false);
    });
  });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
