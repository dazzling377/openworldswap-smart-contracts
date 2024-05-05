import { formatEther, parseEther } from "ethers/lib/utils";
import { ethers, network } from "hardhat";

const currentNetwork = network.name;

async function main() {
  console.log("Deploying to network:", currentNetwork);

  console.log("Deploying V2Wrapper...");
  const deployer = new ethers.Wallet(process.env.KEY_MAINNET || "", ethers.provider);
  console.log("deployer:", deployer.address, formatEther(await deployer.getBalance()));


  const OWS = await ethers.getContractFactory("OWS");
  const OWSToken = await OWS.deploy();

  console.log("OWSToken deployed to:", OWSToken.address);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
