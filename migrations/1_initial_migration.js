const Migrations = artifacts.require("Migrations");
const MultiSig = artifacts.require("MultiSig");
const MoldNFT = artifacts.require("MoldNFT");
const AuctionSea = artifacts.require("AuctionSea");

module.exports = async function (deployer) {
  await deployer.deploy(Migrations);
  await deployer.deploy(MultiSig);
  await deployer.deploy(MoldNFT);
  await deployer.deploy(AuctionSea);
};
