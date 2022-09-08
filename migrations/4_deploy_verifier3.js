const v = artifacts.require("PlonkVerifier3");

module.exports = async function (deployer) {
  await deployer.deploy(v);
};
