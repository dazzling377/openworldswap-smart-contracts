import { ethers, network } from "hardhat";
import { formatEther, parseEther } from "ethers/lib/utils";

const config = require("../config");
const currentNetwork = network.name;

async function main() {
  const deployer = new ethers.Wallet(process.env.KEY_MAINNET || "", ethers.provider);

  console.log("deployer:", deployer.address, formatEther(await deployer.getBalance()));
  console.log("Deploying to network:", currentNetwork);

  const CakeToken = await ethers.getContractFactory("CakeToken", deployer);
  const cakeToken = await CakeToken.deploy();

  console.log("cakeToken  deployed to:", cakeToken.address, cakeToken);

  const rewardTokenAddress = cakeToken.address;

  let tx: any;

  tx = await cakeToken.mint(deployer.address, parseEther("10000"));
  await tx.wait();

  console.log("cakeToken  mint to:", cakeToken.address);

  console.log("Deploying SmartChef...");

  const SmartChef = await ethers.getContractFactory("SmartChef");

  // IBEP20 _stakedToken,
  // IBEP20 _rewardToken,
  // uint256 _rewardPerBlock,
  // uint256 _startBlock,
  // uint256 _bonusEndBlock,
  // uint256 _poolLimitPerUser

  const smartChef = await SmartChef.deploy(
    rewardTokenAddress,
    rewardTokenAddress,
    String(parseEther("0.001")),
    1147094,
    1847094,
    0
  );

  console.log("SmartChef deployed to:", smartChef.address);

  tx = await cakeToken.transfer(smartChef.address, parseEther("3000"));
  await tx.wait();
  console.log("reward token to smartchef:", smartChef.address);


// cakeToken  mint to: 0x261391BAfCA48286259756Af40e62E675F2a277D
// Deploying SmartChef...
// SmartChef deployed to: 0xF2da6a64292fD530D1542835EDDebB492F59a837
// reward token to smartchef: 0xF2da6a64292fD530D1542835EDDebB492F59a837

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
