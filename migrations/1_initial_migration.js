const Migrations = artifacts.require("Migrations");
const MultiSig = artifacts.require("MultiSig");
const MoldNFT = artifacts.require("MoldNFT");
const AuctionSea = artifacts.require("AuctionSea");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(MultiSig);
  deployer.deploy(MoldNFT);
  deployer.deploy(AuctionSea);
};
