import { ethers, network } from "hardhat";

const config = require("../config");
const currentNetwork = network.name;

async function main() {
  if (currentNetwork == "mainnet") {
    if (!process.env.KEY_MAINNET) {
      throw new Error("Missing private key, refer to README 'Deployment' section");
    }
    if (
      !config.Admin[currentNetwork] ||
      config.Admin[currentNetwork] === "0x0000000000000000000000000000000000000000"
    ) {
      throw new Error("Missing admin address, refer to README 'Deployment' section");
    }
  }

  console.log("Deploying to network:", currentNetwork);

  console.log("Deploying Factory...");

  const SmartChefFactory = await ethers.getContractFactory("SmartChefFactory");
  const smartChefFactory = await SmartChefFactory.deploy();

  console.log("SmartChef deployed to:", smartChefFactory.address);

  // SmartChef deployed to: 0xfA97c39965eBFc7179E29DB59Fd46d6183cA212A
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
