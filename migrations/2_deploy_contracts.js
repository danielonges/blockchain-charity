const CharityStorage = artifacts.require("CharityStorage");
const Charity = artifacts.require("Charity");
const DonorStorage = artifacts.require("DonorStorage");
const Donor = artifacts.require("Donor");
const ProjectMarketStorage = artifacts.require("ProjectMarketStorage");
const ProjectMarket = artifacts.require("ProjectMarket");
const CharityToken = artifacts.require("CharityToken");

module.exports = (deployer, network, accounts) => {
  deployer
    .deploy(CharityStorage)
    .then(() => deployer.deploy(DonorStorage))
    .then(() => deployer.deploy(CharityToken))
    .then(() =>
      deployer.deploy(Charity, CharityStorage.address, CharityToken.address)
    )
    .then(() =>
      deployer.deploy(Donor, DonorStorage.address, CharityToken.address)
    )
    .then(() => deployer.deploy(ProjectMarketStorage, Charity.address))
    .then(() =>
      deployer.deploy(
        ProjectMarket,
        ProjectMarketStorage.address,
        CharityToken.address,
        Charity.address,
        Donor.address
      )
    );
};
