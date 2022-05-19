const identity = artifacts.require("IdentityContract");
const hfl = artifacts.require("HFLContract");

module.exports = async function (deployer) {
  const instance = await identity.deployed();
  await deployer.deploy(hfl, instance.address);
};
