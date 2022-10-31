const identity = artifacts.require("IdentityContract");
const chaiAsPromised = require("chai-as-promised");
const chai = require("chai");

chai.use(chaiAsPromised);
const assert = chai.assert;

contract("Identity", (accounts) => {
    const address1 = accounts[0];
    const name1 = "node1";
    const url1 = "http://127.0.0.1:6700";

    const address2 = accounts[1];
    const name2 = "node2";
    const url2 = "http://127.0.0.1:6800";

    it("join", async () => {
        const identityInstance = await identity.deployed();
        const res1 = await identityInstance.join(url1, name1, { from: address1 });
        assert.strictEqual(res1.logs[0].args[0], address1);
        assert.strictEqual(res1.logs[0].args[1], url1);
        assert.strictEqual(res1.logs[0].args[2], name1);

        const res2 = await identityInstance.join(url2, name2, { from: address2 });
        assert.strictEqual(res2.logs[0].args[0], address2);
        assert.strictEqual(res2.logs[0].args[1], url2);
        assert.strictEqual(res2.logs[0].args[2], name2);
    })

    const newName1 = "node11";
    const newUrl1 = "http://127.0.0.1:6701";
    it("update name and url", async () => {
        const identityInstance = await identity.deployed();
        const res1 = await identityInstance.updateName(newName1, { from: address1 });
        assert.strictEqual(res1.logs[0].args[0], address1);
        assert.strictEqual(res1.logs[0].args[1], url1);
        assert.strictEqual(res1.logs[0].args[2], newName1);

        const res2 = await identityInstance.updateUrl(newUrl1, { from: address1 });
        assert.strictEqual(res2.logs[0].args[0], address1);
        assert.strictEqual(res2.logs[0].args[1], newUrl1);
        assert.strictEqual(res2.logs[0].args[2], newName1);
    })

    it("get node info", async () => {
        const identityInstance = await identity.deployed();
        const node1 = await identityInstance.getNodeInfo.call(address1);
        assert.strictEqual(node1.addr, address1);
        assert.strictEqual(node1.url, newUrl1);
        assert.strictEqual(node1.name, newName1);

        const node2 = await identityInstance.getNodeInfo.call(address2);
        assert.strictEqual(node2.addr, address2);
        assert.strictEqual(node2.url, url2);
        assert.strictEqual(node2.name, name2);
    })

    it("get nodes", async () => {
        const identityInstance = await identity.deployed();
        const res = await identityInstance.getNodes.call(1, 20);
        const nodes = res[0];
        const count = res[1];
        assert.strictEqual(count.toNumber(), 2);
        assert.lengthOf(nodes, 2);

        assert.strictEqual(nodes[0].addr, address1);
        assert.strictEqual(nodes[0].url, newUrl1);
        assert.strictEqual(nodes[0].name, newName1);
        assert.strictEqual(nodes[1].addr, address2);
        assert.strictEqual(nodes[1].url, url2);
        assert.strictEqual(nodes[1].name, name2);
    })

    it("join again", async () => {
        const identityInstance = await identity.deployed();
        const res1 = await identityInstance.join(newUrl1, newName1, { from: address1 });
        assert.strictEqual(res1.logs[0].args[0], address1);
        assert.strictEqual(res1.logs[0].args[1], newUrl1);
        assert.strictEqual(res1.logs[0].args[2], newName1);

        const res2 = await identityInstance.join(url2, name2, { from: address2 });
        assert.strictEqual(res2.logs[0].args[0], address2);
        assert.strictEqual(res2.logs[0].args[1], url2);
        assert.strictEqual(res2.logs[0].args[2], name2);
    })

    it("leave node1", async () => {
        const identityInstance = await identity.deployed();
        const res = await identityInstance.leave({ from: address1 });
        assert.strictEqual(res.logs[0].args[0], address1);
        assert.strictEqual(res.logs[0].args[1], newUrl1);
        assert.strictEqual(res.logs[0].args[2], newName1);
    })

    it("get node info after node1's leaving", async () => {
        const identityInstance = await identity.deployed();
        assert.isRejected(identityInstance.getNodeInfo.call(address1));

        const node2 = await identityInstance.getNodeInfo.call(address2);
        assert.strictEqual(node2.addr, address2);
        assert.strictEqual(node2.url, url2);
        assert.strictEqual(node2.name, name2);
    })

    it("get nodes after node1's leaving", async () => {
        const identityInstance = await identity.deployed();
        const res = await identityInstance.getNodes.call(1, 20);
        const nodes = res[0];
        const count = res[1];
        assert.strictEqual(count.toNumber(), 1);
        assert.lengthOf(nodes, 1);

        assert.strictEqual(nodes[0].addr, address2);
        assert.strictEqual(nodes[0].url, url2);
        assert.strictEqual(nodes[0].name, name2);
    })
})