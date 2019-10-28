# Solidity智能合约工具集
> 基于web3.js, solc等项目的智能合约自动化流程
## 主要功能
1. 合约代码编译、链接、部署；
2. 合约方法调用
## 使用方法
1. npm install
2. 配置 ./src/config.js
3. 将合约代码全部放到项目根目录的contracts文件夹中
4. 使用工具集编写部署和调用的js脚本
## Example
```javascript 1.8
const Contract = require('../src/contract');

const Verifier_Registry = new Contract('Verifier_Registry');
const BN256G2 = new Contract('BN256G2');
const GM17_v0 = new Contract('GM17_v0');

async function deployContracts() {
    await Verifier_Registry.deploy();
    await BN256G2.deploy();
    GM17_v0.link(BN256G2);
    await GM17_v0.deploy([Verifier_Registry.address]);
}

deployContracts().then(() => {
    console.log('所有操作已完成！');
    process.exit();
});
```
