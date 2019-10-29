const fs = require('fs');
const conf = require('../../src/config');
const path = require('path');
const Contract = require('../../src/contract');
const utils = require('./utils');
const jsonfile = require('jsonfile');

const vkIdsFile = path.join(path.resolve(__dirname), 'vkIds.json');
const NFT_MINT_VK = path.join(path.resolve(__dirname, '..', 'gm17/nft-mint/nft-mint-vk.json'));
const NFT_TRANSFER_VK = path.join(path.resolve(__dirname, '..', 'gm17/nft-transfer/nft-transfer-vk.json'));
const NFT_BURN_VK = path.join(path.resolve(__dirname, '..', 'gm17/nft-burn/nft-burn-vk.json'));

let vkIds = {};

/**
 Reads the vkIds json from file
 */
async function getVkIds() {
    if (fs.existsSync(vkIdsFile)) {
        console.log('从json文件中读取vkIds...');
        try {
            vkIds = await jsonfile.readFile(vkIdsFile)
        } catch (err) {
            console.log('读取vkIds失败');
        }
    }
}

async function loadVk(vkJsonFile, vkDescription, account) {
    console.log('\n正在为' + vkDescription + '部署 VK');

    const verifier = new Contract('GM17_v0');
    const verifierRegistry = new Contract('Verifier_Registry');
    if (!verifier.deployed() || !verifierRegistry.deployed()) {
        console.log('请先部署合约！');
        return
    }
    let vk = {};
    try {
        vk = await jsonfile.readFile(vkJsonFile);
    } catch (err) {
        console.log('读取vk json文件失败');
        return
    }

    vk = Object.values(vk);
    // convert to flattened array:
    vk = utils.flattenDeep(vk);
    // convert to decimal, as the solidity functions expect uints
    vk = vk.map(el => utils.hexToDec(el));

    // upload the vk to the smart contract
    let receipt = await verifierRegistry.method('registerVk', [vk, [verifier.address]], {
        gasPrice: 1000000000,
        gasLimit: 6500000
    });

    const log = verifierRegistry.decodeEvent(receipt.logs, 'NewVkRegistered');
    if (log === null) {
        return
    }
    const vkId = log._vkId;

    // add new vkId's to the json
    vkIds[vkDescription] = {};
    vkIds[vkDescription].vkId = vkId;
    vkIds[vkDescription].Address = account;


    try {
        await jsonfile.writeFile(vkIdsFile, vkIds);
    } catch (err) {
        console.log('保存 vkIds.json 失败', err)
    }
}

async function vkController() {
    // read existing vkIds (if they exist)
    await getVkIds();

    const account = conf.account;

    // load each vk to the Verifier Registry
    if (!vkIds.hasOwnProperty('MintToken')) {
        await loadVk(NFT_MINT_VK, 'MintToken', account);
    }
    if (!vkIds.hasOwnProperty('TransferToken')) {
        await loadVk(NFT_TRANSFER_VK, 'TransferToken', account);
    }
    if (!vkIds.hasOwnProperty('BurnToken')) {
        await loadVk(NFT_BURN_VK, 'BurnToken', account);
    }

    console.log('VK setup 完成');
}

vkController().then(() => {
    process.exit();
});
