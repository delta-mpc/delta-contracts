const identity = artifacts.require("IdentityContract");
const hlr = artifacts.require("HLR")

contract("hlr", (accounts) => {
    const dataset = "mnist"
    const taskCommitment = "0x1230000000000000000000000000000000000000000000000000000000000000"
    const taskType = "hlr"
    const enableVerify = true;
    const tolerance = 6;

    let taskId;

    const node1 = accounts[0]
    const node2 = accounts[1]
    const node3 = accounts[2]
    const nodes = [node1, node2, node3]

    before(async () => {
        const idInstance = await identity.deployed()
        await idInstance.join("http://node1", "node1", { from: node1 })
        await idInstance.join("http://node2", "node2", { from: node2 })
        await idInstance.join("http://node3", "node3", { from: node3 })
    })

    after(async () => {
        const idInstance = await identity.deployed()
        await idInstance.leave({ from: node1 })
        await idInstance.leave({ from: node2 })
        await idInstance.leave({ from: node3 })
    })

    it("create task", async () => {
        const hlrInstance = await hlr.deployed()
        const receipt = await hlrInstance.createTask(dataset, taskCommitment, taskType, enableVerify, tolerance, { from: node1 })

        const creator = receipt.logs[0].args['0']
        taskId = receipt.logs[0].args['1']
        const _dataset = receipt.logs[0].args['2']
        const _taskCommitment = receipt.logs[0].args['4']
        const _taskType = receipt.logs[0].args['5']
        const _enableVerify = receipt.logs[0].args['6']
        const _tolerance = receipt.logs[0].args['7'].toNumber()

        assert.strictEqual(creator, node1)
        assert.strictEqual(_dataset, dataset)
        assert.strictEqual(_taskCommitment, taskCommitment)
        assert.strictEqual(_taskType, taskType)
        assert.strictEqual(_enableVerify, enableVerify)
        assert.strictEqual(_tolerance, tolerance)
    })

    it("get task", async () => {
        const hlrInstance = await hlr.deployed()
        const task = await hlrInstance.getTask.call(taskId)

        assert.strictEqual(task.creator, node1)
        assert.strictEqual(task.creatorUrl, "http://node1")
        assert.strictEqual(task.dataSet, dataset)
        assert.strictEqual(task.commitment, taskCommitment)
        assert.strictEqual(task.taskType, taskType)
        assert.strictEqual(Number(task.currentRound), 0)
        assert.isNotTrue(task.finished)
        assert.strictEqual(task.enableVerify, enableVerify)
        assert.strictEqual(Number(task.tolerance), tolerance)
    })

    const weightCommitment = "0x1230000000000000000000000000000000000000000000000000000000000000"

    it("start round", async () => {
        const hlrInstance = await hlr.deployed()
        const receipt = await hlrInstance.startRound(taskId, 1, 100, 3, weightCommitment)

        assert.strictEqual(receipt.logs[0].args['0'], taskId)
        assert.strictEqual(receipt.logs[0].args['1'].toNumber(), 1)
    })

    const pk1 = "0x1230000000000000000000000000000000000000000000000000000000000000"
    const pk2 = "0x1230000000000000000000000000000000000000000000000000000000000000"
    it("join round", async () => {
        const hlrInstance = await hlr.deployed()
        for (const node of nodes) {
            await hlrInstance.joinRound(taskId, 1, pk1, pk2, { from: node })
        }

        const r = await hlrInstance.getTaskRound.call(taskId, 1)
        assert.lengthOf(r.joinedAddrs, 3)
        assert.includeMembers(r.joinedAddrs, nodes)
        assert.strictEqual(Number(r.status), 0)
    })

    it("get weight commitment", async () => {
        const hlrInstance = await hlr.deployed()
        const _weightCommitment = await hlrInstance.getWeightCommitment.call(taskId, 1)
        assert.strictEqual(_weightCommitment, weightCommitment)
    })

    it("get public keys", async () => {
        const hlrInstance = await hlr.deployed()
        const pks = await hlrInstance.getClientPublickeys.call(taskId, 1, nodes)
        for (const pk of pks) {
            assert.strictEqual(pk.pk1, pk1)
            assert.strictEqual(pk.pk2, pk2)
        }
    })

    it("select candidates", async () => {
        const hlrInstance = await hlr.deployed()
        const receipt = await hlrInstance.selectCandidates(taskId, 1, nodes, { from: node1 })
        assert.includeMembers(receipt.logs[0].args['2'], nodes)

        const r = await hlrInstance.getTaskRound.call(taskId, 1)
        assert.strictEqual(Number(r.status), 1)
    })

    const seedCommitments = [
        "0x1000000000000000000000000000000000000000000000000000000000000000",
        "0x2000000000000000000000000000000000000000000000000000000000000000",
        "0x3000000000000000000000000000000000000000000000000000000000000000"
    ]
    const skCommitments = [
        "0x1100000000000000000000000000000000000000000000000000000000000000",
        "0x2100000000000000000000000000000000000000000000000000000000000000",
        "0x3100000000000000000000000000000000000000000000000000000000000000"

    ]
    it("upload seed commitments", async () => {
        const hlrInstance = await hlr.deployed()
        for (const node of nodes) {
            const receipt = await hlrInstance.uploadSeedCommitment(taskId, 1, nodes, seedCommitments, { from: node })

            for (const [i, log] of receipt.logs.entries()) {
                assert.strictEqual(log.args['2'], node)
                assert.strictEqual(log.args['3'], nodes[i])
                assert.strictEqual(log.args['5'], seedCommitments[i])
            }
        }
    })

    it("upload sk commitments", async () => {
        const hlrInstance = await hlr.deployed()
        for (const node of nodes) {
            const receipt = await hlrInstance.uploadSecretKeyCommitment(taskId, 1, nodes, skCommitments, { from: node })

            for (const [i, log] of receipt.logs.entries()) {
                assert.strictEqual(log.args['2'], node)
                assert.strictEqual(log.args['3'], nodes[i])
                assert.strictEqual(log.args['5'], skCommitments[i])
            }
        }
    })

    it("start calculate", async () => {
        const hlrInstance = await hlr.deployed()
        const receipt = await hlrInstance.startCalculate(taskId, 1, nodes)
        assert.strictEqual(receipt.logs[0].args[0], taskId)
        assert.strictEqual(receipt.logs[0].args[1].toNumber(), 1)
        assert.includeMembers(receipt.logs[0].args[2], nodes)
        assert.lengthOf(receipt.logs[0].args[2], 3)

        const r = await hlrInstance.getTaskRound.call(taskId, 1)
        assert.strictEqual(Number(r.status), 2)
    })

    it("get secret sharing data", async () => {
        const hlrInstance = await hlr.deployed()
        for (const [i, node] of nodes.entries()) {
            const ssDatas = await hlrInstance.getSecretSharingDatas.call(taskId, 1, nodes, node)

            for (const ssData of ssDatas) {
                assert.strictEqual(ssData.seedCommitment, seedCommitments[i])
                assert.strictEqual(ssData.secretKeyMaskCommitment, skCommitments[i])
            }
        }
    })

    const resultCommitments = [
        "0x1110000000000000000000000000000000000000000000000000000000000000",
        "0x2220000000000000000000000000000000000000000000000000000000000000",
        "0x3330000000000000000000000000000000000000000000000000000000000000"
    ]
    it("upload result commitments", async () => {
        const hlrInstance = await hlr.deployed()
        for (const [i, node] of nodes.entries()) {
            const resultCommitment = resultCommitments[i]
            const receipt = await hlrInstance.uploadResultCommitment(taskId, 1, resultCommitment, { from: node })
            assert.strictEqual(receipt.logs[0].args[2], node)
            assert.strictEqual(receipt.logs[0].args[5], resultCommitment)
        }
    })

    it("get result commitments", async () => {
        const hlrInstance = await hlr.deployed()
        for (const [i, node] of nodes.entries()) {
            const commitment = await hlrInstance.getResultCommitment.call(taskId, 1, node)
            assert.strictEqual(commitment, resultCommitments[i])
        }
    })

    it("start aggregate", async () => {
        const hlrInstance = await hlr.deployed()
        const receipt = await hlrInstance.startAggregate(taskId, 1, nodes, { from: node1 })
        assert.strictEqual(receipt.logs[0].args[0], taskId)
        assert.strictEqual(receipt.logs[0].args[1].toNumber(), 1)
        assert.includeMembers(receipt.logs[0].args[2], nodes)
        assert.lengthOf(receipt.logs[0].args[2], 3)

        const r = await hlrInstance.getTaskRound.call(taskId, 1)
        assert.strictEqual(Number(r.status), 3)
    })

    const seeds = ["0x01", "0x02", "0x03"]
    it("upload seed", async () => {
        const hlrInstance = await hlr.deployed()

        for (const node of nodes) {
            const receipt = await hlrInstance.uploadSeed(taskId, 1, nodes, seeds, { from: node })
            for (const [i, log] of receipt.logs.entries()) {
                assert.strictEqual(log.args[2], nodes[i])
                assert.strictEqual(log.args[3], node)
                assert.strictEqual(log.args[5], seeds[i])
            }
        }
    })

    const sks = ["0x11", "0x22", "0x33"]
    it("upload sk", async () => {
        const hlrInstance = await hlr.deployed()

        for (const node of nodes) {
            const receipt = await hlrInstance.uploadSecretkeyMask(taskId, 1, nodes, sks, { from: node })
            for (const [i, log] of receipt.logs.entries()) {
                assert.strictEqual(log.args[2], nodes[i])
                assert.strictEqual(log.args[3], node)
                assert.strictEqual(log.args[5], sks[i])
            }
        }
    })

    it("end round", async () => {
        const hlrInstance = await hlr.deployed()
        const receipt = await hlrInstance.endRound(taskId, 1, { from: node1 })
        assert.strictEqual(receipt.logs[0].args[0], taskId)
        assert.strictEqual(receipt.logs[0].args[1].toNumber(), 1)

        const r = await hlrInstance.getTaskRound.call(taskId, 1)
        assert.strictEqual(Number(r.status), 4)
        assert.lengthOf(r.finishedAddrs, 3)
        assert.includeMembers(r.finishedAddrs, nodes)
    })

    it("finish task", async () => {
        const hlrInstance = await hlr.deployed()

        await hlrInstance.finishTask(taskId)

        const task = await hlrInstance.getTask.call(taskId)
        assert.strictEqual(Number(task.currentRound), 1)
        assert.isTrue(task.finished)
    })
})