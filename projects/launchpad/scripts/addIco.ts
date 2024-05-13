import { ethers, network, run } from "hardhat";
import { formatEther, parseEther } from "ethers/lib/utils";
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

  const icoTokenAddress = "0x19E6FF42F72B05f5dBc7C8d2546B1D93697Ac0f0";
  const icoTreasury_ = "0x84Bf832c13eD2CA004cc2077170Aaabc893fd53a";
  const icoOwner_ = deployer.address;
  const treasuryFee_ = 100; // 1% fee

  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const _startTimestamp = currentTimestampInSeconds + 60;
  const _endTimestamp = _startTimestamp + 3600 * 24;
  const _claimTimestamp = _startTimestamp + 3600 * 26;
  console.log("currentTimestampInSeconds:", currentTimestampInSeconds, _startTimestamp, _endTimestamp);

  // IERC20 icoToken_,
  // address payable icoTreasury_,
  // address payable icoOwner_,
  // uint16 treasuryFee_,
  // uint256 startDate_,
  // uint256 endDate_

  const OWSICO = await ethers.getContractFactory("OWSICO", deployer);
  const owsIco = await OWSICO.deploy(
    icoTokenAddress,
    icoTreasury_,
    icoOwner_,
    treasuryFee_,
    _startTimestamp,
    _endTimestamp
  );

  await owsIco.deployed();
  console.log("owsIco deployed to:", owsIco.address);

  let tx;

  tx = await owsIco.updateIcoDates(_startTimestamp, _endTimestamp, _claimTimestamp);
  await tx.wait();
  console.log("updateIcoDates");

  tx = await owsIco.updateIcoPrice(parseEther("0.2"));
  await tx.wait();
  console.log("updateIcoPrice");

  tx = await owsIco.updateCap(parseEther("1000"), parseEther("100000"));
  await tx.wait();
  console.log("updateCap");

  tx = await owsIco.updateLimitation("0", parseEther("1000"));
  await tx.wait();
  console.log("updateLimitation");

  const icoToken = await ethers.getContractAt("OWSERC20", icoTokenAddress, deployer);

  tx = await icoToken.transfer(owsIco.address, parseEther("100"));
  await tx.wait();
  console.log("ico token to owsIco:", owsIco.address);

  // function updateCap(uint256 softcap_, uint256 hardcap_) external onlyOwner {
  // function updateIcoPrice(uint256 icoPrice_) external onlyOwner {
  // function updateIcoDates(uint256 startDate_, uint256 endDate_, uint256 claimDate_) external onlyOwner {
  // function updateLimitation(uint256 minPerUser_, uint256 maxPerUser_) external onlyOwner
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
