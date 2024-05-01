import { formatEther, parseEther } from "ethers/lib/utils";
import { ethers, network } from "hardhat";

const config = require("../config");
const currentNetwork = network.name;

async function main() {
  console.log("Deploying to network:", currentNetwork);

  console.log("Deploying MasterChef...");
  const deployer = new ethers.Wallet(process.env.KEY_MAINNET || "", ethers.provider);

  console.log("deployer:", deployer.address, formatEther(await deployer.getBalance()));
  console.log("Deploying to network:", currentNetwork);

  // const CakeToken = await ethers.getContractFactory("CakeToken", deployer);
  const cakeToken = await ethers.getContractAt("CakeToken", "0x4De88a40bd5334aeCF573022a13C7C32E8086792");

  console.log("cakeToken  deployed to:", cakeToken.address);

  const SyrupBar = await ethers.getContractFactory("SyrupBar", deployer);
  const syrupBar = await SyrupBar.deploy(cakeToken.address);

  console.log("syrupBar  deployed to:", syrupBar.address);

  const MasterChef = await ethers.getContractFactory("MasterChef");
  // CakeToken _cake,
  // SyrupBar _syrup,
  // address _devaddr,
  // uint256 _cakePerBlock,
  // uint256 _startBlock

  const masterChef = await MasterChef.deploy(
    cakeToken.address,
    syrupBar.address,
    deployer.address,
    String(parseEther("1")),
    1147553
  );

  console.log("masterChef deployed to:", masterChef.address);

  const usdtOwsLp = "0x4D4320acA6ecE298e126e0cc01dB01CA68b42DdD";

  // function add(
  //   uint256 _allocPoint,
  //   IBEP20 _lpToken,
  //   bool _withUpdate
  let tx = await masterChef.add(100, usdtOwsLp, false);
  await tx.wait();

  tx = await cakeToken.transferOwnership(masterChef.address);
  await tx.wait();

  console.log("sent cake ownership to masterchef:");

  // cakeToken  deployed to: 0x4De88a40bd5334aeCF573022a13C7C32E8086792
  // syrupBar  deployed to: 0x4A84b39CE7218A3F38304F0c10C3020C4601CeF4
  // masterChef deployed to: 0x03735d53f16629EfA6E950Bd29E0ad56bFc6635b
  // sent cake ownership to masterchef:
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
