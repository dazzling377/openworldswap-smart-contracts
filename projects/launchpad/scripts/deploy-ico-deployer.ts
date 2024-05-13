import { ethers, network, run } from "hardhat";
import { formatEther } from "ethers/lib/utils";
import config from "../config";

const currentNetwork = network.name;

const main = async () => {
  // Get network name: hardhat, testnet or mainnet.
  const { name } = network;
  console.log(`Deploying to ${name} network...`);

  // Compile contracts.
  await run("compile");
  console.log("Compiled contracts");


  console.log("Deploying to network:", currentNetwork);

  const deployer = new ethers.Wallet(process.env.KEY_MAINNET || "", ethers.provider);
  console.log("deployer:", deployer.address, formatEther(await deployer.getBalance()));


  const ICODeployer = await ethers.getContractFactory("ICODeployer");
  const icoDeployer = await ICODeployer.deploy();

  await icoDeployer.deployed();
  console.log("icoDeployer deployed to:", icoDeployer.address);
  
  
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
