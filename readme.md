# Solidity智能合约工具集
> 基于web3.js, solc,ethereumjs-tx,secp256k1等项目
>
> 用于实现智能合约操作的一些流程自动化
## 主要功能
1. 智能合约代码编译、链接、部署；
2. 智能合约方法调用
3. 智能合约eventLog解析
## 使用方法
1. npm install
2. 配置 ./src/config.js
3. 在项目根目录新建compile文件夹，用于存放合约编译信息
4. 将合约代码全部放到项目根目录的contracts文件夹中
5. 使用工具集编写部署和调用的js脚本
## Example
1. 部署
```javascript
const Contract = require('../src/contract');

const Verifier_Registry = new Contract('Verifier_Registry');
const BN256G2 = new Contract('BN256G2');
const GM17_v0 = new Contract('GM17_v0');

async function deployContracts() {
    let gasConfig = {gasPrice: 1000000000};
    await Verifier_Registry.deploy([], gasConfig);
    await BN256G2.deploy([], gasConfig);
    GM17_v0.link(BN256G2);
    await GM17_v0.deploy([Verifier_Registry.address], gasConfig);
}

deployContracts().then(() => {
    console.log('所有操作已完成！');
    process.exit();
});
```
2.方法调用 & eventLog解析
```javascript
async function mint(A) {
  const Contract = require('../src/contract');
  console.log('mint一个 NF Token', A);
  const nfToken = new Contract('NFTokenMetadata');
  await nfToken.method('mint', [A, 'http://nightfall.nft.token/'+A]);
  return nfToken.decodeEvent('Transfer')
}
mint(1).then(() => {
    console.log('mint操作已完成！');
    process.exit();
});
```
