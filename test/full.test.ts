import { expect } from "chai";
import { BigNumberish, Contract } from "ethers";
import { ethers, waffle } from "hardhat";

async function getWrapper(
  wrappable: Contract,
  id: BigNumberish
): Promise<Contract> {
  const Wrapper20 = await ethers.getContractFactory("Wrapper20");
  const bytecode = Wrapper20.getDeployTransaction([id]).data || "0x";
  const address = ethers.utils.getCreate2Address(
    wrappable.address,
    `0x${"baadc0de".repeat(8)}`,
    ethers.utils.keccak256(bytecode)
  );
  return Wrapper20.attach(address);
}

describe("Wrappable1155", () => {
  let wrappable: Contract;

  beforeEach(async () => {
    const Wrappable1155 = await ethers.getContractFactory("Wrappable1155");
    wrappable = await Wrappable1155.deploy(0, 0);
  });

  describe("deployWrapper", () => {
    it("should deploy wrapper contract to a predictable address", async () => {
      const id = 42;
      const wrapper = await getWrapper(wrappable, id);

      expect(await ethers.provider.getCode(wrapper.address)).to.equal("0x");
      await wrappable.deployWrapper(id);
      expect(await ethers.provider.getCode(wrapper.address)).to.not.equal("0x");
    });
  });

  describe("getWrapper", () => {
    it("should compute the CREATE2 address for a wrapper", async () => {
      const id = 42;
      const wrapper = await getWrapper(wrappable, id);

      expect(await wrappable.getWrapper(id)).to.equal(wrapper.address);
    });
  });

  describe("sudoUnsetApprovalForAll", () => {
    it("should revert when not called from a Wrapper", async () => {
      await expect(
        wrappable.sudoUnsetApprovalForAll(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          0
        )
      ).to.be.revertedWith("wrapper only");
    });
  });

  describe("sudoTransferFrom", () => {
    it("should revert when not called from a Wrapper", async () => {
      await expect(
        wrappable.sudoTransferFrom(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          0,
          0
        )
      ).to.be.revertedWith("wrapper only");
    });
  });
});

describe("Wrapper20", () => {
  const [unpriviledged, owner, recipient] = waffle.provider.getWallets();
  const ID = 42;
  const AMOUNT = ethers.utils.parseEther("1.0");

  let wrappable: Contract;
  let wrapper: Contract;

  beforeEach(async () => {
    const Wrappable1155 = await ethers.getContractFactory("Wrappable1155");
    wrappable = await Wrappable1155.connect(owner).deploy(ID, AMOUNT);
    wrappable = wrappable.connect(unpriviledged);
    await wrappable.deployWrapper(ID);
    wrapper = await getWrapper(wrappable, ID);
  });

  describe("allowance", () => {
    it("should return 0 for unapproved operators", async () => {
      expect(
        await wrapper.allowance(owner.address, recipient.address)
      ).to.equal(ethers.constants.Zero);
    });

    it("should return max uin256 for approved operators", async () => {
      await wrappable.connect(owner).setApprovalForAll(recipient.address, true);
      expect(
        await wrapper.allowance(owner.address, recipient.address)
      ).to.equal(ethers.constants.MaxUint256);
    });
  });

  describe("approve", () => {
    it("should set allowance", async () => {
      await wrapper.connect(owner).approve(recipient.address, AMOUNT);
      expect(
        await wrapper.allowance(owner.address, recipient.address)
      ).to.equal(AMOUNT);
    });

    it("should remove ERC1155 approval", async () => {
      await wrappable.connect(owner).setApprovalForAll(recipient.address, true);
      await wrapper.connect(owner).approve(recipient.address, AMOUNT);
      expect(
        await wrappable.isApprovedForAll(owner.address, recipient.address)
      ).to.equal(false);
    });
  });

  describe("balanceOf", () => {
    it("should return balance amount", async () => {
      expect(await wrapper.balanceOf(owner.address)).to.equal(AMOUNT);
      expect(await wrapper.balanceOf(recipient.address)).to.equal(
        ethers.constants.Zero
      );
    });
  });

  describe("totalSupply", () => {
    it("should return the total supply", async () => {
      expect(await wrapper.totalSupply()).to.equal(AMOUNT);
    });
  });

  describe("transfer", () => {
    it("should transfer to recipient", async () => {
      const partialAmount = AMOUNT.div(4);

      await wrapper.connect(owner).transfer(recipient.address, partialAmount);
      expect(await wrapper.balanceOf(owner.address)).to.equal(
        AMOUNT.sub(partialAmount)
      );
      expect(await wrapper.balanceOf(recipient.address)).to.equal(
        partialAmount
      );
    });

    it("should not update allowance", async () => {
      await wrapper.connect(owner).approve(recipient.address, AMOUNT);
      await wrapper.connect(owner).transfer(recipient.address, AMOUNT);
      expect(
        await wrapper.allowance(owner.address, recipient.address)
      ).to.equal(AMOUNT);
    });

    it("should revert on insufficient balances", async () => {
      await expect(wrapper.transfer(recipient.address, AMOUNT.add(1))).to.be
        .reverted;
    });
  });

  describe("transferFrom", () => {
    it("should transfer when initiated from approved operator", async () => {
      await wrappable.connect(owner).setApprovalForAll(recipient.address, true);
      await wrapper
        .connect(recipient)
        .transferFrom(owner.address, recipient.address, AMOUNT);

      expect(await wrapper.balanceOf(owner.address)).to.equal(
        ethers.constants.Zero
      );
      expect(await wrapper.balanceOf(recipient.address)).to.equal(AMOUNT);

      expect(
        await wrapper.allowance(owner.address, recipient.address)
      ).to.equal(ethers.constants.MaxUint256);
    });

    it("should transfer when initiated from operator with allowance", async () => {
      const transferAmount = ethers.utils.parseEther("0.42");

      await wrapper.connect(owner).approve(recipient.address, AMOUNT);
      await wrapper
        .connect(recipient)
        .transferFrom(owner.address, recipient.address, transferAmount);

      expect(await wrapper.balanceOf(owner.address)).to.equal(
        AMOUNT.sub(transferAmount)
      );
      expect(await wrapper.balanceOf(recipient.address)).to.equal(
        transferAmount
      );

      expect(
        await wrapper.allowance(owner.address, recipient.address)
      ).to.equal(AMOUNT.sub(transferAmount));
    });

    it("should revert on insufficent allowance", async () => {
      await wrapper.connect(owner).approve(recipient.address, AMOUNT.sub(1));
      await expect(
        wrapper.transferFrom(owner.address, recipient.address, AMOUNT)
      ).to.be.revertedWith("insufficient allowance");
    });

    it("should revert on insufficent allowance even from owner", async () => {
      // NOTE: The OpenZeppelin ERC20 behaves this way.
      await expect(
        wrapper
          .connect(owner)
          .transferFrom(owner.address, recipient.address, AMOUNT)
      ).to.be.revertedWith("insufficient allowance");
    });

    it("should revert when transaction from unapproved operator", async () => {
      await expect(
        wrapper.transferFrom(owner.address, recipient.address, AMOUNT)
      ).to.be.reverted;
    });

    it("should revert on insufficient balances", async () => {
      await expect(
        wrapper
          .connect(owner)
          .transferFrom(owner.address, recipient.address, AMOUNT.add(1))
      ).to.be.reverted;
    });
  });
});
