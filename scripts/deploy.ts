import { ethers } from "hardhat";
import { RPSatoshiToken } from '../typechain-types/contracts/RPSatoshiToken';

async function main() {
  const RockPaperSatoshi = await ethers.getContractFactory("RockPaperSatoshi");
  const rockPaperSatoshi = await RockPaperSatoshi.deploy();

  const RPSatoshiToken = await ethers.getContractFactory("RPSatoshiToken");
  const rPSatoshiToken = await RPSatoshiToken.deploy();

  const RPSHashHealToken = await ethers.getContractFactory("RPSHashHealToken");
  const rPSHashHealToken = await RPSHashHealToken.deploy();

  const RPSRareItemsToken = await ethers.getContractFactory("RPSRareItemsToken");
  const rPSRareItemsToken = await RPSRareItemsToken.deploy();

  await  rockPaperSatoshi.deployed();
  await  rPSatoshiToken.deployed();
  await  rPSHashHealToken.deployed();
  await  rPSRareItemsToken.deployed();

  console.log(
    "RockPaperSatoshi Deployed... to", rockPaperSatoshi.address
  );
  console.log(
    "RPSatoshiToken Deployed... to", rPSatoshiToken.address
  );
  console.log(
    "RPSHashHealToken Deployed... to", rPSHashHealToken.address
  );
  console.log(
    "RPSRareItemsToken Deployed... to", rPSRareItemsToken.address
  );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
