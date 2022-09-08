const identity = artifacts.require("IdentityContract");
const datahub = artifacts.require("DataHub");
const hlr = artifacts.require("HLR");

module.exports = async function (deployer) {
    const identityInstance = await identity.deployed()
    const datahubInstance = await datahub.deployed()
    await deployer.deploy(hlr, identityInstance.address, datahubInstance.address);
};
