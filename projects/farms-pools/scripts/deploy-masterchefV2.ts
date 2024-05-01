import { formatEther, parseEther } from "ethers/lib/utils";
import { ethers, network } from "hardhat";

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

  const syrupBar = await ethers.getContractAt("SyrupBar", "0x4A84b39CE7218A3F38304F0c10C3020C4601CeF4");

  console.log("syrupBar  deployed to:", syrupBar.address);

  const masterChef = await ethers.getContractAt("MasterChef", "0x03735d53f16629EfA6E950Bd29E0ad56bFc6635b", deployer);

  // poolInfo
  console.log("cake vault", await masterChef.poolInfo(0));
  let tx;
  // tx = await masterChef.set(0, 0, false);
  // await tx.wait();
  console.log('cake vault alloc into 0')

  console.log("cake vault", await masterChef.poolInfo(0));


  // poolInfo
  console.log("cake vault 1", await masterChef.poolInfo(1));

  console.log("cake vault 2 ", await masterChef.poolInfo(2));

  // const masterChefV2 = await ethers.getContractAt(
  //   "MasterChefV2",
  //   "0xb915Ac86EfeB25c2096eeaE28046288792d72f47",
  //   deployer
  // );
  // console.log("lpinfo", await masterChefV2.lpToken(0));
  // console.log("poolInfo", await masterChefV2.poolInfo(0));

  // tx = await masterChefV2.set(0, 0, false);
  // await tx.wait();
  // console.log("lp farm alloc into 0 in chef2");

  // console.log("lpinfo", await masterChefV2.lpToken(0));
  // console.log("poolInfo", await masterChefV2.poolInfo(0));



  console.log("masterChef  deployed to:", masterChef.address);

  const MockBEP20 = await ethers.getContractFactory("MockBEP20", deployer);
  const mockBEP20 = await MockBEP20.deploy("dMCV2", "dMCV2", String(parseEther("10")));

  console.log("mockBEP20  deployed to:", mockBEP20.address);

  tx = await masterChef.add(100, mockBEP20.address, false);
  await tx.wait();
  console.log("add mock lp pool into masterchef:");

  tx = await masterChef.set(0, 0, false);
  await tx.wait();

  console.log("set first pool alloc into zero");

  const poolId = await masterChef.poolLength();
  console.log("add mock lp pool into masterchef poolId:", poolId);
  
  const _MASTER_PID = Number(poolId) - 1;
  console.log(" _MASTER_PID:", _MASTER_PID);

  const MasterChefV2 = await ethers.getContractFactory("MasterChefV2");
  // IMasterChef _MASTER_CHEF,
  // IBEP20 _CAKE,
  // uint256 _MASTER_PID,
  // address _burnAdmin

  const masterChefV2 = await MasterChefV2.deploy(masterChef.address, cakeToken.address, _MASTER_PID, deployer.address);

  console.log("masterChefV2 deployed to:", masterChefV2.address);

  tx = await mockBEP20.approve(masterChefV2.address, String(parseEther("10000000000000")));
  await tx.wait();
  console.log("approve mock to masterchefV2:");

  tx = await masterChefV2.init(mockBEP20.address);
  await tx.wait();

  console.log("init masterchefV2:");

  const usdtOwsLp = "0x4D4320acA6ecE298e126e0cc01dB01CA68b42DdD";

  // uint256 _allocPoint,
  // IBEP20 _lpToken,
  // bool _isRegular,
  // bool _withUpdate

  tx = await masterChefV2.add(0, cakeToken.address, true, false);
  await tx.wait();
  console.log(" masterchefV2 cake lp add:");
  tx = await masterChefV2.add(100, usdtOwsLp, true, false);
  await tx.wait();

  console.log(" masterchefV2 usdtOwsLp add:");
  // mockBEP20  deployed to: 0xD289D4EBCacA25ad224e2B5Bb76096DEA529738c
  // masterChefV2 deployed to: 0xb915Ac86EfeB25c2096eeaE28046288792d72f47
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
