const datahub = artifacts.require("DataHub");

module.exports = async function (deployer) {
    await deployer.deploy(datahub);
};
