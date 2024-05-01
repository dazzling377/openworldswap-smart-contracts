import { formatEther } from "ethers/lib/utils";
import { ethers, network } from "hardhat";

const currentNetwork = network.name;

async function main() {
  if (currentNetwork == "mainnet") {
    if (!process.env.KEY_MAINNET) {
      throw new Error("Missing private key, refer to README 'Deployment' section");
    }

  }

  console.log("Deploying to network:", currentNetwork);

  console.log("Deploying Factory...");

  const deployer = new ethers.Wallet(
    process.env.KEY_MAINNET || "",
    ethers.provider
  );

  console.log(
    "deployer:",
    deployer.address,
    formatEther(await deployer.getBalance())
  );

  const PancakeFactory = await ethers.getContractFactory("PancakeFactory");
  const factory = await PancakeFactory.deploy(deployer.address);
  await factory.deployed();
  console.log("factory deployed to:", factory.address);
  console.log("init code hash:",await factory.INIT_CODE_PAIR_HASH())

//   factory deployed to: 0x1db943C82d331f102eBeD97256dD8dDaF8DaEF90
// init code hash: 0xd7c05e4979420f92dee27e9b0a3a75181a1881b263eee1ee5b9f56242394f414
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
