const compileOutput = require('./src/compile');
const deploy = require('./src/delpoy');
let Verifier_Registry_address = "0x357a53C5a2161C5bCfDE2A62D084554C5944bB23";
let Pairing_v1_BN256G2_address = '';
let GM17_v0_address = "";
let NFTokenMetadata_address = "";
let NFTokenShield_address = "";
let FTokenShield_address = "";
let FToken_address = "";
let receipt = null;
async function deployContracts() {
    receipt = await deploy('Verifier_Registry', '', null, []);
    if (receipt === 0) return;
    Verifier_Registry_address = receipt.contractAddress;

    receipt = await deploy('BN256G2',  'Pairing_v1.sol', null, []);
    if (receipt === 0) return;
    Pairing_v1_BN256G2_address = receipt.contractAddress;

    let BN256G2_lib = {'Pairing_v1.sol':{'BN256G2':Pairing_v1_BN256G2_address}};

    receipt = await deploy('GM17_v0',  '', BN256G2_lib, [Verifier_Registry_address]);
    if (receipt === 0) return;
    GM17_v0_address = receipt.contractAddress;

    receipt = await deploy('NFTokenMetadata',  '', null, []);
    if (receipt === 0) return;
    NFTokenMetadata_address = receipt.contractAddress;

    receipt = await deploy('NFTokenShield',  '', null, [Verifier_Registry_address, GM17_v0_address, NFTokenMetadata_address]);
    if (receipt === 0) return;
    NFTokenShield_address = receipt.contractAddress;

    receipt = await deploy('FToken',  '', null, []);
    if (receipt === 0) return;
    FToken_address = receipt.contractAddress;

    receipt = await deploy('FTokenShield',  '', null, [Verifier_Registry_address, GM17_v0_address, FToken_address]);
    if (receipt === 0) return;
    FTokenShield_address = receipt.contractAddress;

}
deployContracts().then(() => {
    console.log('所有操作已完成！');
});
