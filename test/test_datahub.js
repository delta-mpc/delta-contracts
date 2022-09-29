const datahub = artifacts.require("DataHub");

contract("DataHub", (accounts) => {
    const name = "mnist";
    const commitment = "0x1230000000000000000000000000000000000000000000000000000000000000";
    it("register", async () => {
        const datahubInstance = await datahub.deployed();
        const res = await datahubInstance.register(name, commitment, { from: accounts[0] })
        const _owner = res.logs[0].args['0'];
        const _name = res.logs[0].args['1'];
        const _commitment = res.logs[0].args['2'];
        const version = res.logs[0].args['3'].toNumber();

        assert.strictEqual(_owner, accounts[0]);
        assert.strictEqual(_name, name);
        assert.strictEqual(_commitment, commitment);
        assert.strictEqual(version, 1);
    })

    it("get commitment and version", async () => {
        const datahubInstance = await datahub.deployed();
        const _commitment = await datahubInstance.getDataCommitment.call(accounts[0], name)
        const _version = (await datahubInstance.getDataVersion.call(accounts[0], name)).toNumber()
        assert.strictEqual(_commitment, commitment)
        assert.strictEqual(_version, 1);
    })

    const newCommitment = "0x3210000000000000000000000000000000000000000000000000000000000000"
    it("update", async () => {
        const datahubInstance = await datahub.deployed();
        await datahubInstance.register(name, newCommitment, { from: accounts[0] })
        const _commitment = await datahubInstance.getDataCommitment.call(accounts[0], name)
        const _version = (await datahubInstance.getDataVersion.call(accounts[0], name)).toNumber()
        assert.strictEqual(_commitment, newCommitment);
        assert.strictEqual(_version, 2);
    })
})