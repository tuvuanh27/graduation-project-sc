import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import dayjs from "dayjs";
import { ethers } from "hardhat";

import { NFT, NFT__factory } from "../types";

describe("NFT", async function () {
  let deployer: SignerWithAddress;
  let nftContract: NFT;

  //   beforeEach(async function () {
  //     [deployer] = await ethers.getSigners();
  //     const nftFactory: NFT__factory = <NFT__factory>await ethers.getContractFactory("NFT");
  //     nftContract = <NFT>await nftFactory.connect(deployer).deploy();
  //     await nftContract.connect(deployer).initialize("VuAnhTu", "VAT");
  //     console.log("nftContract.address", nftContract.address);
  //   });

  it("Should return the correct symbol", async function () {
    [deployer] = await ethers.getSigners();
    const nftFactory: NFT__factory = <NFT__factory>await ethers.getContractFactory("NFT");
    nftContract = <NFT>await nftFactory.connect(deployer).deploy();
    await nftContract.connect(deployer).initialize("VuAnhTu", "VAT");
    console.log("nftContract.address", nftContract.address);
    console.log("nftContract.address", nftContract.owner);

    expect(await nftContract.symbol()).to.equal("VAT");
  });

  //   it("Should return the correct name", async function () {
  //     expect(await nftContract.name()).to.equal("VuAnhTu");
  //   });
});
