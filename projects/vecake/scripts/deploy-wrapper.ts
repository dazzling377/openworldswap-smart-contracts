import { formatEther, parseEther } from "ethers/lib/utils";
import { ethers, network } from "hardhat";

const currentNetwork = network.name;

async function main() {
  console.log("Deploying to network:", currentNetwork);

  console.log("Deploying V2Wrapper...");
  const deployer = new ethers.Wallet(process.env.KEY_MAINNET || "", ethers.provider);
  console.log("deployer:", deployer.address, formatEther(await deployer.getBalance()));


  // const V2Wrapper = await ethers.getContractFactory("V2Wrapper");
  // const v2Wrapper = await V2Wrapper.deploy();

  // console.log("v2Wrapper deployed to:", v2Wrapper.address);


  // const cakeAddress = "0x4De88a40bd5334aeCF573022a13C7C32E8086792";
  // const usdtOwsLp = "0x4D4320acA6ecE298e126e0cc01dB01CA68b42DdD";
  // const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  // const _startTimestamp = currentTimestampInSeconds + 60;
  // const _endTimestamp = _startTimestamp + 3600 * 24 * 365;
  // console.log("currentTimestampInSeconds:", currentTimestampInSeconds);

  // let tx = await v2Wrapper.initialize(
  //   usdtOwsLp,
  //   cakeAddress,
  //   String(parseEther("0.2")),
  //   _startTimestamp,
  //   _endTimestamp,
  //   deployer.address,
  //   "0x0000000000000000000000000000000000000000"
  // );
  // await tx.wait();

  // console.log("initialize usdtOwsLp wrapper ")


  // 0x9892D6bB304D2ec55E9cF6Ecdd422DDc2C08d6Cc

  const cakeToken = await ethers.getContractAt("ERC20", "0x4De88a40bd5334aeCF573022a13C7C32E8086792");
  let tx = await cakeToken.transfer("0x9892D6bB304D2ec55E9cF6Ecdd422DDc2C08d6Cc", parseEther("2000"));
  await tx.wait();
  console.log("reward token to cakeToken:", cakeToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
