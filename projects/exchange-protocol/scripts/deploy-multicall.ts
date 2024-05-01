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


  const deployer = new ethers.Wallet(
    process.env.KEY_MAINNET || "",
    ethers.provider
  );

  console.log(
    "deployer:",
    deployer.address,
    formatEther(await deployer.getBalance())
  );

  const Multicall3 = await ethers.getContractFactory("Multicall3");
  const multicall3 = await Multicall3.deploy();
  await multicall3.deployed();
  console.log("multicall3 deployed to:", multicall3.address);

  const PancakeInterfaceMulticallV2 = await ethers.getContractFactory("PancakeInterfaceMulticallV2");
  const pancakeInterfaceMulticallV2 = await PancakeInterfaceMulticallV2.deploy();
  await pancakeInterfaceMulticallV2.deployed();
  console.log("pancakeInterfaceMulticallV2 deployed to:", pancakeInterfaceMulticallV2.address);
  // deployer: 0x261391BAfCA48286259756Af40e62E675F2a277D 6.883622503813298077
  // multicall3 deployed to: 0xB904DBbD2B4af731c7be81665a38eA817094e926
  // pancakeInterfaceMulticallV2 deployed to: 0x81F8Fac752EE9387fc8FFAA0b5EDb31c6C2FA8c4
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
