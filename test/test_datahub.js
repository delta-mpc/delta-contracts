const datahub = artifacts.require("DataHub");

contract("DataHub", (accounts) => {
    const name = "mnist";
    const commitment1 = "0x1230000000000000000000000000000000000000000000000000000000000000";
    it("register new data", async () => {
        const datahubInstance = await datahub.deployed();
        const res = await datahubInstance.register(name, 0, commitment1, { from: accounts[0] })
        const _owner = res.logs[0].args[0];
        const _name = res.logs[0].args[1];
        const _index = res.logs[0].args[2].toNumber();
        const _commitment = res.logs[0].args[3];

        assert.strictEqual(_owner, accounts[0]);
        assert.strictEqual(_name, name);
        assert.strictEqual(_index, 0);
        assert.strictEqual(_commitment, commitment1);
    })

    const newCommitment1 = "0x3210000000000000000000000000000000000000000000000000000000000000"

    it("update data", async () => {
        const datahubInstance = await datahub.deployed();
        const res = await datahubInstance.register(name, 0, newCommitment1, { from: accounts[0] })
        const _owner = res.logs[0].args[0];
        const _name = res.logs[0].args[1];
        const _index = res.logs[0].args[2].toNumber();
        const _commitment = res.logs[0].args[3];

        assert.strictEqual(_owner, accounts[0]);
        assert.strictEqual(_name, name);
        assert.strictEqual(_index, 0);
        assert.strictEqual(_commitment, newCommitment1);
    })

    const commitment2 = "0x3330000000000000000000000000000000000000000000000000000000000000"
    it("register new block data", async () => {
        const datahubInstance = await datahub.deployed();
        const res = await datahubInstance.register(name, 1, commitment2, { from: accounts[0] })
        const _owner = res.logs[0].args[0];
        const _name = res.logs[0].args[1];
        const _index = res.logs[0].args[2].toNumber();
        const _commitment = res.logs[0].args[3];

        assert.strictEqual(_owner, accounts[0]);
        assert.strictEqual(_name, name);
        assert.strictEqual(_index, 1);
        assert.strictEqual(_commitment, commitment2);
    })

    it("get commitment", async () => {
        const datahubInstance = await datahub.deployed();
        const _commitment1 = await datahubInstance.getDataCommitment.call(accounts[0], name, 0)
        assert.strictEqual(_commitment1, newCommitment1)

        const _commitment2 = await datahubInstance.getDataCommitment.call(accounts[0], name, 1)
        assert.strictEqual(_commitment2, commitment2)

    })

})