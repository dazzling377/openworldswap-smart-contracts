import { formatEther } from "ethers/lib/utils";
import { ethers, network, run } from "hardhat";

const currentNetwork = network.name;

const main = async () => {
  // Get network name: hardhat, testnet or mainnet.
  const { name } = network;
  console.log(`Deploying to ${name} network...`);

  console.log("Deploying to network:", currentNetwork);

  const deployer = new ethers.Wallet(process.env.KEY_MAINNET || "", ethers.provider);
  console.log("deployer:", deployer.address, formatEther(await deployer.getBalance()));

  const oldOWSTokenForPay = "0x4De88a40bd5334aeCF573022a13C7C32E8086792";

  const OWSTokenFactory = await ethers.getContractFactory("OWSTokenFactory", deployer);
  const coinFactory = await OWSTokenFactory.deploy(oldOWSTokenForPay, deployer.address);

  await coinFactory.deployed();
  console.log("OWSTokenFactory deployed to:", coinFactory.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
