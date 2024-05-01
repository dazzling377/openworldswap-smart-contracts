import { formatEther, parseEther } from "ethers/lib/utils";
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
  const factoryAddress = "0x1db943C82d331f102eBeD97256dD8dDaF8DaEF90"
  const wethAddress = "0x8Ce4B67b08c147572c463c894Ff5b540FB58C42a"

  const PancakeRouter = await ethers.getContractFactory("PancakeRouter");
  const router = await PancakeRouter.deploy(factoryAddress,wethAddress);
  await router.deployed();
  console.log("router deployed to:", router.address);



  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const token = await MockERC20.deploy("Test","Test",parseEther("10000"));
  await token.deployed();
  console.log("mockToken deployed to:", token.address);

  const unifactory = await ethers.getContractAt(
    "PancakeFactory",
    factoryAddress,
    deployer
  );

  let tx;

  const  uniswapRouter = router.address;

  console.log(
    "token balance",
    formatEther(await token.balanceOf(deployer.address))
  );

  tx = await token.approve(uniswapRouter, parseEther("100000000000000000"));
  await tx.wait();

  console.log("approve token to uniswap router");
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  tx = await router.addLiquidityETH(
    token.address,
    parseEther("1000"),
    0,
    0,
    deployer.address,
    unlockTime,
    { value: parseEther("0.1") }
  );
  await tx.wait();

  console.log("add liquidity with 1 eth");

  const pairaddress = await unifactory.getPair(token.address, wethAddress);

  console.log("pairaddress", pairaddress);

  const lptoken = await ethers.getContractAt("ERC20", pairaddress, deployer);
  const lpBalance = await lptoken.balanceOf(deployer.address);

  console.log(
    "deployer lpBalance ",
    formatEther(lpBalance)
  );

  console.log(
    "deployer token balance",
    formatEther(await token.balanceOf(deployer.address))
  );

  tx = await router
    .swapExactETHForTokens(
      0,
      [wethAddress, token.address],
      deployer.address,
      unlockTime,
      { value: parseEther("0.01") }
    );
  await tx.wait();

  console.log("success token buy")

  console.log(
    "deployer token balance s:",
    formatEther(await token.balanceOf(deployer.address))
  );


  tx = await router
  .swapExactTokensForETH(
    parseEther("10"),
    0,
    [token.address, wethAddress],
    deployer.address,
    unlockTime,

  );
  
  await tx.wait();
  
  console.log("success token sell")

  console.log(
    "deployer token balance s:",
    formatEther(await token.balanceOf(deployer.address))
  );
// factory deployed to: 0x1db943C82d331f102eBeD97256dD8dDaF8DaEF90
// deployer: 0x261391BAfCA48286259756Af40e62E675F2a277D 7.9983604565
// router deployed to: 0x813605069Aa78C01AEE5eb27d6CdeE21797040da
// mockToken deployed to: 0xb166B4e48D7711Ba5CAa33f7B6Bd7232FaD34513
// const wethAddress = "0x8Ce4B67b08c147572c463c894Ff5b540FB58C42a"

// 


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
