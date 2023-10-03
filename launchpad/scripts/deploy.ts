import { ethers } from "hardhat";

async function main() {
  console.log("deploying...");
  // const SwapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564"; 

  const Manager = await ethers.getContractFactory("PoolManager");
  const manager = await Manager.deploy();

  await manager.waitForDeployment();

  console.log("Single Swap contract deployed: ", manager.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

