const identity = artifacts.require("IdentityContract");

module.exports = async function (deployer) {
  await deployer.deploy(identity);
};
