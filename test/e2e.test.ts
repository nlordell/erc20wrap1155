import { expect } from "chai";
import { BigNumberish, Contract } from "ethers";
import { ethers } from "hardhat";

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

describe("Wrappable1155", function () {
  let wrappable: Contract;

  beforeEach(async () => {
    const Wrappable1155 = await ethers.getContractFactory("Wrappable1155");
    wrappable = await Wrappable1155.deploy();
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
});
