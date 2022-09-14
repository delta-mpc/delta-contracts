const identity = artifacts.require("IdentityContract");
const hlr = artifacts.require("HLR")
const verifier = artifacts.require("PlonkVerifier3");
const datahub = artifacts.require("DataHub");
const chaiAsPromised = require("chai-as-promised")
const chai = require("chai")

chai.use(chaiAsPromised)
const assert = chai.assert

contract("hlr", (accounts) => {
    const dataset = "mnist"
    const taskCommitment = "0x1230000000000000000000000000000000000000000000000000000000000000"
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

        const datahubInstance = await datahub.deployed()
        await datahubInstance.register(dataset, "0x1b9e1999bd3aede0f518ac01efbbc4c6397f311f8fb1b4d9a789b92440e87790", { from: node1 })
        await datahubInstance.register(dataset, "0x2be97c3a6dff81e5db01463a44e2057d77cabb72c17510b523c759d237601940", { from: node2 })
        await datahubInstance.register(dataset, "0x241074e8fd5a7b5b87c23b76a2ab58b48054d84971a204b6d3ca02b87475cec9", { from: node3 })
    })

    after(async () => {
        const idInstance = await identity.deployed()
        await idInstance.leave({ from: node1 })
        await idInstance.leave({ from: node2 })
        await idInstance.leave({ from: node3 })
    })

    it("create task", async () => {
        const hlrInstance = await hlr.deployed()
        const receipt = await hlrInstance.createTask(dataset, taskCommitment, enableVerify, tolerance, { from: node1 })

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
        assert.strictEqual(_taskType, "hlr")
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
        assert.strictEqual(task.taskType, "hlr")
        assert.strictEqual(Number(task.currentRound), 0)
        assert.isNotTrue(task.finished)
        assert.strictEqual(task.enableVerify, enableVerify)
        assert.strictEqual(Number(task.tolerance), tolerance)
    })

    const weightCommitment = "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc"

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

async function runTask(nodes) {
    const [node1, node2, node3] = nodes.slice(0, 3)

    const dataset = "mnist"
    const taskCommitment = "0x1230000000000000000000000000000000000000000000000000000000000000"
    const enableVerify = true;
    const tolerance = 6;

    const idInstance = await identity.deployed()
    const datahubInstance = await datahub.deployed()
    const hlrInstance = await hlr.deployed()

    await idInstance.join("http://node1", "node1", { from: node1 })
    await idInstance.join("http://node2", "node2", { from: node2 })
    await idInstance.join("http://node3", "node3", { from: node3 })

    await datahubInstance.register(dataset, "0x1b9e1999bd3aede0f518ac01efbbc4c6397f311f8fb1b4d9a789b92440e87790", { from: node1 })
    await datahubInstance.register(dataset, "0x2be97c3a6dff81e5db01463a44e2057d77cabb72c17510b523c759d237601940", { from: node2 })
    await datahubInstance.register(dataset, "0x241074e8fd5a7b5b87c23b76a2ab58b48054d84971a204b6d3ca02b87475cec9", { from: node3 })
    // create task
    const r1 = await hlrInstance.createTask(dataset, taskCommitment, enableVerify, tolerance, { from: node1 })
    const taskId = r1.logs[0].args[1]
    // start round
    const weightCommitment = "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc"
    await hlrInstance.startRound(taskId, 1, 100, 3, weightCommitment)
    // join round
    const pk1 = "0x1230000000000000000000000000000000000000000000000000000000000000"
    const pk2 = "0x1230000000000000000000000000000000000000000000000000000000000000"
    for (const node of nodes) {
        await hlrInstance.joinRound(taskId, 1, pk1, pk2, { from: node })
    }
    // select candidates
    await hlrInstance.selectCandidates(taskId, 1, nodes, { from: node1 })
    // upload seed and sk commitments
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
    for (const node of nodes) {
        await hlrInstance.uploadSeedCommitment(taskId, 1, nodes, seedCommitments, { from: node })
        await hlrInstance.uploadSecretKeyCommitment(taskId, 1, nodes, skCommitments, { from: node })
    }
    // start calculate
    await hlrInstance.startCalculate(taskId, 1, nodes)
    // upload result commitments
    const resultCommitments = [
        "0x1110000000000000000000000000000000000000000000000000000000000000",
        "0x2220000000000000000000000000000000000000000000000000000000000000",
        "0x3330000000000000000000000000000000000000000000000000000000000000"
    ]
    for (const [i, node] of nodes.entries()) {
        const resultCommitment = resultCommitments[i]
        await hlrInstance.uploadResultCommitment(taskId, 1, resultCommitment, { from: node })
    }
    // start aggregate
    await hlrInstance.startAggregate(taskId, 1, nodes, { from: node1 })
    // upload seeds and sks
    const seeds = ["0x01", "0x02", "0x03"]
    const sks = ["0x11", "0x22", "0x33"]
    for (const node of nodes) {
        await hlrInstance.uploadSeed(taskId, 1, nodes, seeds, { from: node })
        await hlrInstance.uploadSecretkeyMask(taskId, 1, nodes, sks, { from: node })
    }
    await hlrInstance.endRound(taskId, 1, { from: node1 })
    await hlrInstance.finishTask(taskId)

    return taskId
}

async function nodesLeave(nodes) {
    const [node1, node2, node3] = nodes.slice(0, 3)

    const idInstance = await identity.deployed()
    await idInstance.leave({ from: node1 })
    await idInstance.leave({ from: node2 })
    await idInstance.leave({ from: node3 })

}
contract("hlr verify", (accounts) => {
    const nodes = accounts.slice(0, 3)
    const [node1, node2, node3] = nodes
    let taskId;

    before(async () => {
        taskId = await runTask(nodes)
    })

    after(async () => {
        await nodesLeave(nodes)
    })

    const proofs = [
        "0x12657b15f1d56b80b39042d44c150f5678b52bdde96fae5bf59031850e6a62e90f0004ee8321a1cd297db050eccca474bbbe1141fcb1d05536cd0d2c5b8638d92ed0c205583d22b10c971357269de3f4d163e41a4605fb63a67b0062bdb816f40e056a22dd1a7b4c095f34c99835b5a3c2c70bb934ac90194905e0cb60fd67490c66fb3c3de42eaa1b9a8f3045b89e412efbb98bd35e75320e6cae88257789581c59f7375f86f45dae5c3602c7e4b2751a2e598f1ca9dc57281c11b65a538d830bf29cb843ced7d5b8c786ee9b73db05c0c5fd7d9297b9694eb85e06c5bb014e15f4b898ef419a35746fcc678a66b6aefe2cebd6dd034a53f6d64321d544e3ff244c4d0d60522baf4d8f18246ed6db9c05bd039f6096838fe5d760cd86ccb70415f34ccb7b797851e90f607cfffb342ba327cbddd6a68df9ebe2089ff179d45b2976057ac29154a74123f03b54bc9982b8229c224b04a9b75a5b5ee832ef5c5d2b5ca7ba74bc5dee52dbb2a217d7cfd460c24d673e937d84ad936898babd6ebe1e217dcd268872fc7e8eec662c37ce186d71910e14af3d2dc901aa61d991d30c26bd158edb19db94d516b8c50f92ff4f5da8b724881ffa044c767d58261b81071afe612d1538501fac6995deb8b5178c8704c5e11eb6a800320efab3c74fc1421fbbb0330d58499cf465ee67e011971d3f880d675ea98a98d33202a3e7f130080a7b12f3710c6dbea94d56ab5e6da5f2ebe78bf69c3ae1317967b33fe08640c523e5dbe78869cd50b1dc6e5843f9571927fc97476a8da53eea8ef292d539c67e26252fdab93c8a474e6eb7ece07e196bff09aa18fb5a30b3b9c9a12624e0a9441b7d74e7bd8930351e0f4a3df311c2ed90ad3e23acb75883ee7d01b016eba57d087e6248a2d9e3d7de6c7cb7da4f0de34b7298b4c85b7dbf07e726194dd3b3dd0c1d2b0c18c4eb6f4e46d35616668fe746cc509a70669c881f50afd285923cc619a772aafeceaacaa81c0920f38684b2b6867183108d3e811135223242b2ca7724be4eee1842c65a2c9ac9474a061445d34befaf2fc50e962f6a438a6acecab116ff629df2f452b053eea2d6a94bd5c4185ac6e68134e8d89885f32364768f5b",
        "0x0194501bfdcebfb0ea46b2b4c503eb9b70666007e1bc0685aa9a6ac72784d9bd0447c86d02221272b627a4adf0f7f969ac987f72860d51a9356c75ac0e1e7f0321340975a0a49454406d7f80b90f5f1382fe3529f8e082fa30a12815abea99f82cd9b16d7709d8aeaca0a28bfbbe571c5a7669f3b7f79ec39dceb8e7bd47c0e2120b2ed8eed686fc7838661f56fc9af2dbecac824ce6849afd9ca738ae975b750b3fea2b746b2278c6352159d1f27480661ce96b8b832c38545aa1f252a0cee32c55f90feace2db2ce78c0197adf056a728f3e94e9bb6402a6fa4a4d43bfb03d1af4e7b1ff0fe85ef5a126eec87cb0a8037da449ef90cf7b5d75e25d0ae59fdc1f969612efb411002f26746f8d3fe76668ba83a7e036b61bbe8d51e0cd1ada9016ea5dd6daf325f2a6759bbfdf52223f71c4819d9ebeae0c2f1f0304be88952923a5bd3f58c9ea98df1e47789ab887650ed332c4410092ecf319209becc4b22629d89343decffb5750e699aa6e4944f8bcf07734b15f8ea63ec28317ac5959141f74521de59b2c874cb4430f23ccc15a87218830203ff05a52ef8cf8f479f26e16cad86b7de0b420028e65b54f9c0ee35e43d0e04d259397138a3c4bbc479cb71b06f9c322e0471292dfcee2bb5b39b1cfc740cce665024d1cb09272ba44d94002ecb406bf22a4d4b2cb1073b18abfead773a2ce1e6c1c3db787bed425356937203cfd27e37f0b39f8c725968cee3164f131695905bc2e97bad6ebcd4290110526a447cbcc372bc325e4faf5025696607b7f83116466a35c03735501931df8db26f2999c51518340249c9a49ca317dc055bcbe0d778bb36d887e2e16a8d469c30d24c8f129bafbe57a799f2fadbf26457e1103f97d2cd38f2628b843e2878afe101e89ba5293cf208f7c09dd9fcb271ac1bb22c063bf6acdcd171c06dd0e3a3a16868d0ce2ad197d2ae3b0a36c39f3ef3c761dc85d520d136ce90f3b7d7478ee00f361405046ac7b7e98c74961a9ed13e2a354676260ecdefb51dea89bc7089d1fc1c68d2f1f6d4dc4db9d9d936180c8ca50d532ca99db344e27ebc0aa8069082af977c57d56882c811d5e042573ac6dc8c008a42f703f5d0f1c44950bdc13d7",
        "0x07fbe8333989a28f187dbde2985af5a34224b8ee1a68527d527f0f72837a2e1c0a62cd907c6c25f78fdc8abfa0e22dc5c7385fcc907c7a8c26cd20d6ddb3636026a1ec87de7b9160374e0d1df965b174c27f8b1894b26b2132bb5fd1a779fc5b0067a68f09176e3286aaec790ebf213e8542760c89d500c9d3b685b58e3423f818cd82cb9abc05ec9c60a4b0a712d1da2521fc731080f274b6cd520f36dc620c0fe443472dc0e27b3b86ce551b33163472dc6837371dfbaeb29dd2227df2252e0907479f3457632d7ce9cf0c4eafc1b86698e5d3bc005f81aaae598dcb095f5115e9d59e64848051422b0a5f7b7e381d5026a8a6137b39e841724e6ebd32890708f7ec1e028089abca8d72bdb6c3d3af3c302d6f1e12d071cced1041a6de380010cb6dcc850de3ea19772a89fa299f5292d3e1b59e46f1310d7e2c95175be85c17f2ac991893437fc2791de2aa7a0bbf0260148637a85e3a3d187b74dbed01211049d1e7b24188a94e086d233f8c056f8f18b2424f996061110f3eb3d490898b0c551cd20474002e95f6bc9ca11b108ddd877c6babdc5a8e40a2b4471e45be6917702eddee82f06b79f7cc2fa52cced068737c5830ddfb6f89efeb738a6b92852fdd3f90f2d56e4795e6cdf3a6e1eaac1e8e4dd1a8894d7c478a3463dc5520b82866aed98cd9db07a94f2fc2f2e7efddb89a885a9724311ca65e2cc4c0faf35d28d2516d35f2d0322a830f7e821cf9c593b9d5f01a6565a0f160a04136fe09b41bffd52279e0a6a4afc71b8b84e65da262a32a1f415b630020d42b1c741ec36625ea68653c1ac362fee6206ecbb6dc9296fb7f8d105ad7954d8eb9746a3e4d941d2d706d50e42fc0a2547cf847726281cb14bf25aecb67b12f1d9f62f5a453a60280bcf328b8a4ed7331b383bdf22a11457b8ffdcfa8766b0681e40bd1100af8281e465aef5e63862c87c740045b169d917ffd6efaee6595ba4dfa3bc0eafa001c32048eae1b9d27e93be897f05e427388eac7547293b6e9da9f56debd15390f2e8748fa292c564aeb37e2a9b431999ef2f612615c4836160d8e5596275c64c111fec36a2f9dfb15681873ffac72acdf1bee55ecedc0c849e5854db218f78f9f"
    ]
    const pubSignals = [
        ["0x0000000000000000000000000000000000000000a8ddf87093b5b09c2b10c000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x0000000000000000000000000000000000000003eff1a3d33cc434dc387c0000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x0000000000000000000000000000000000000000000000000000000000000000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc", "0x1b9e1999bd3aede0f518ac01efbbc4c6397f311f8fb1b4d9a789b92440e87790"],
        ["0x30644e72e131a029b85045b68181585d2833e845ff9193037f6d4acba0804001", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x30644e72e131a029b85045b68181585d2833e8395c03653d409383e2b4110001", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x30644e72e131a029b85045b68181585d2833e84862f49a5543223ed6ff180001", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc", "0x2be97c3a6dff81e5db01463a44e2057d77cabb72c17510b523c759d237601940"],
        ["0x0000000000000000000000000000000000000001ce482df1943d48e78d2b4000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x000000000000000000000000000000000000000afc760c73ff359d4927920000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x00000000000000000000000000000000000000000a2999e6cabec76bf2290000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc", "0x241074e8fd5a7b5b87c23b76a2ab58b48054d84971a204b6d3ca02b87475cec9"]
    ]

    it("verify", async () => {
        const hlrInstance = await hlr.deployed()
        const verifierInstance = await verifier.deployed()

        for (let i = 0; i < 3; i++) {
            const node = accounts[i]
            const proof = proofs[i]
            const pubSignal = pubSignals[i]
            const receipt = await hlrInstance.verify(taskId, verifierInstance.address, proof, pubSignal, { from: node })

            const taskMemeberEvent = receipt.logs[0]

            assert.isTrue(taskMemeberEvent.args[2])
            if (i == 2) {
                const taskEvent = receipt.logs[1]
                assert.isTrue(taskEvent.args[1])
            }
        }
    })

    it("get verifier state", async () => {
        const hlrInstance = await hlr.deployed()

        const state = await hlrInstance.getVerifierState.call(taskId)
        assert.lengthOf(state.unfinishedClients, 0)
        assert.lengthOf(state.invalidClients, 0)
        assert.isTrue(state.valid)
    })

    it("verify rejected", async () => {
        const hlrInstance = await hlr.deployed()
        const verifierInstance = await verifier.deployed()

        await assert.isRejected(hlrInstance.verify(taskId, verifierInstance.address, proofs[0], pubSignals[0], { from: node1 }))
        await assert.isRejected(hlrInstance.verify(taskId, verifierInstance.address, proofs[0], pubSignals[0], { from: accounts[4] }))
    })
})


contract("hlr verify failed ", (accounts) => {
    const nodes = accounts.slice(0, 3)
    const [node1, node2, node3] = nodes
    let taskId;

    before(async () => {
        taskId = await runTask(nodes)
    })

    after(async () => {
        await nodesLeave(nodes)
    })

    const proofs = [
        "0x12657b15f1d56b80b39042d44c150f5678b52bdde96fae5bf59031850e6a62e90f0004ee8321a1cd297db050eccca474bbbe1141fcb1d05536cd0d2c5b8638d92ed0c205583d22b10c971357269de3f4d163e41a4605fb63a67b0062bdb816f40e056a22dd1a7b4c095f34c99835b5a3c2c70bb934ac90194905e0cb60fd67490c66fb3c3de42eaa1b9a8f3045b89e412efbb98bd35e75320e6cae88257789581c59f7375f86f45dae5c3602c7e4b2751a2e598f1ca9dc57281c11b65a538d830bf29cb843ced7d5b8c786ee9b73db05c0c5fd7d9297b9694eb85e06c5bb014e15f4b898ef419a35746fcc678a66b6aefe2cebd6dd034a53f6d64321d544e3ff244c4d0d60522baf4d8f18246ed6db9c05bd039f6096838fe5d760cd86ccb70415f34ccb7b797851e90f607cfffb342ba327cbddd6a68df9ebe2089ff179d45b2976057ac29154a74123f03b54bc9982b8229c224b04a9b75a5b5ee832ef5c5d2b5ca7ba74bc5dee52dbb2a217d7cfd460c24d673e937d84ad936898babd6ebe1e217dcd268872fc7e8eec662c37ce186d71910e14af3d2dc901aa61d991d30c26bd158edb19db94d516b8c50f92ff4f5da8b724881ffa044c767d58261b81071afe612d1538501fac6995deb8b5178c8704c5e11eb6a800320efab3c74fc1421fbbb0330d58499cf465ee67e011971d3f880d675ea98a98d33202a3e7f130080a7b12f3710c6dbea94d56ab5e6da5f2ebe78bf69c3ae1317967b33fe08640c523e5dbe78869cd50b1dc6e5843f9571927fc97476a8da53eea8ef292d539c67e26252fdab93c8a474e6eb7ece07e196bff09aa18fb5a30b3b9c9a12624e0a9441b7d74e7bd8930351e0f4a3df311c2ed90ad3e23acb75883ee7d01b016eba57d087e6248a2d9e3d7de6c7cb7da4f0de34b7298b4c85b7dbf07e726194dd3b3dd0c1d2b0c18c4eb6f4e46d35616668fe746cc509a70669c881f50afd285923cc619a772aafeceaacaa81c0920f38684b2b6867183108d3e811135223242b2ca7724be4eee1842c65a2c9ac9474a061445d34befaf2fc50e962f6a438a6acecab116ff629df2f452b053eea2d6a94bd5c4185ac6e68134e8d89885f32364768f5b",
        "0x0194501bfdcebfb0ea46b2b4c503eb9b70666007e1bc0685aa9a6ac72784d9bd0447c86d02221272b627a4adf0f7f969ac987f72860d51a9356c75ac0e1e7f0321340975a0a49454406d7f80b90f5f1382fe3529f8e082fa30a12815abea99f82cd9b16d7709d8aeaca0a28bfbbe571c5a7669f3b7f79ec39dceb8e7bd47c0e2120b2ed8eed686fc7838661f56fc9af2dbecac824ce6849afd9ca738ae975b750b3fea2b746b2278c6352159d1f27480661ce96b8b832c38545aa1f252a0cee32c55f90feace2db2ce78c0197adf056a728f3e94e9bb6402a6fa4a4d43bfb03d1af4e7b1ff0fe85ef5a126eec87cb0a8037da449ef90cf7b5d75e25d0ae59fdc1f969612efb411002f26746f8d3fe76668ba83a7e036b61bbe8d51e0cd1ada9016ea5dd6daf325f2a6759bbfdf52223f71c4819d9ebeae0c2f1f0304be88952923a5bd3f58c9ea98df1e47789ab887650ed332c4410092ecf319209becc4b22629d89343decffb5750e699aa6e4944f8bcf07734b15f8ea63ec28317ac5959141f74521de59b2c874cb4430f23ccc15a87218830203ff05a52ef8cf8f479f26e16cad86b7de0b420028e65b54f9c0ee35e43d0e04d259397138a3c4bbc479cb71b06f9c322e0471292dfcee2bb5b39b1cfc740cce665024d1cb09272ba44d94002ecb406bf22a4d4b2cb1073b18abfead773a2ce1e6c1c3db787bed425356937203cfd27e37f0b39f8c725968cee3164f131695905bc2e97bad6ebcd4290110526a447cbcc372bc325e4faf5025696607b7f83116466a35c03735501931df8db26f2999c51518340249c9a49ca317dc055bcbe0d778bb36d887e2e16a8d469c30d24c8f129bafbe57a799f2fadbf26457e1103f97d2cd38f2628b843e2878afe101e89ba5293cf208f7c09dd9fcb271ac1bb22c063bf6acdcd171c06dd0e3a3a16868d0ce2ad197d2ae3b0a36c39f3ef3c761dc85d520d136ce90f3b7d7478ee00f361405046ac7b7e98c74961a9ed13e2a354676260ecdefb51dea89bc7089d1fc1c68d2f1f6d4dc4db9d9d936180c8ca50d532ca99db344e27ebc0aa8069082af977c57d56882c811d5e042573ac6dc8c008a42f703f5d0f1c44950bdc13d7",
        "0x07fbe8333989a28f187dbde2985af5a34224b8ee1a68527d527f0f72837a2e1c0a62cd907c6c25f78fdc8abfa0e22dc5c7385fcc907c7a8c26cd20d6ddb3636026a1ec87de7b9160374e0d1df965b174c27f8b1894b26b2132bb5fd1a779fc5b0067a68f09176e3286aaec790ebf213e8542760c89d500c9d3b685b58e3423f818cd82cb9abc05ec9c60a4b0a712d1da2521fc731080f274b6cd520f36dc620c0fe443472dc0e27b3b86ce551b33163472dc6837371dfbaeb29dd2227df2252e0907479f3457632d7ce9cf0c4eafc1b86698e5d3bc005f81aaae598dcb095f5115e9d59e64848051422b0a5f7b7e381d5026a8a6137b39e841724e6ebd32890708f7ec1e028089abca8d72bdb6c3d3af3c302d6f1e12d071cced1041a6de380010cb6dcc850de3ea19772a89fa299f5292d3e1b59e46f1310d7e2c95175be85c17f2ac991893437fc2791de2aa7a0bbf0260148637a85e3a3d187b74dbed01211049d1e7b24188a94e086d233f8c056f8f18b2424f996061110f3eb3d490898b0c551cd20474002e95f6bc9ca11b108ddd877c6babdc5a8e40a2b4471e45be6917702eddee82f06b79f7cc2fa52cced068737c5830ddfb6f89efeb738a6b92852fdd3f90f2d56e4795e6cdf3a6e1eaac1e8e4dd1a8894d7c478a3463dc5520b82866aed98cd9db07a94f2fc2f2e7efddb89a885a9724311ca65e2cc4c0faf35d28d2516d35f2d0322a830f7e821cf9c593b9d5f01a6565a0f160a04136fe09b41bffd52279e0a6a4afc71b8b84e65da262a32a1f415b630020d42b1c741ec36625ea68653c1ac362fee6206ecbb6dc9296fb7f8d105ad7954d8eb9746a3e4d941d2d706d50e42fc0a2547cf847726281cb14bf25aecb67b12f1d9f62f5a453a60280bcf328b8a4ed7331b383bdf22a11457b8ffdcfa8766b0681e40bd1100af8281e465aef5e63862c87c740045b169d917ffd6efaee6595ba4dfa3bc0eafa001c32048eae1b9d27e93be897f05e427388eac7547293b6e9da9f56debd15390f2e8748fa292c564aeb37e2a9b431999ef2f612615c4836160d8e5596275c64c111fec36a2f9dfb15681873ffac72acdf1bee55ecedc0c849e5854db218f78f9f"
    ]
    const pubSignals = [
        ["0x0000000000000000000000000000000000000000a8ddf87093b5b09c2b10c000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x0000000000000000000000000000000000000003eff1a3d33cc434dc387c0000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x0000000000000000000000000000000000000000000000000000000000000000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc", "0x1b9e1999bd3aede0f518ac01efbbc4c6397f311f8fb1b4d9a789b92440e87790"],
        ["0x30644e72e131a029b85045b68181585d2833e845ff9193037f6d4acba0804001", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x30644e72e131a029b85045b68181585d2833e8395c03653d409383e2b4110001", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x30644e72e131a029b85045b68181585d2833e84862f49a5543223ed6ff180001", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc", "0x2be97c3a6dff81e5db01463a44e2057d77cabb72c17510b523c759d237601940"],
        ["0x0000000000000000000000000000000000000001ce482df1943d48e78d2b4000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x000000000000000000000000000000000000000afc760c73ff359d4927920000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x00000000000000000000000000000000000000000a2999e6cabec76bf2290000", "0x000000000000000000000000000000000000000000000000000000000000001d", "0x111da4b536325aca16982ce6fbcb52c06e6708b4976e0b0dbddb022776ff9ffc", "0x241074e8fd5a7b5b87c23b76a2ab58b48054d84971a204b6d3ca02b87475cec9"]
    ]

    it("verify", async () => {
        const hlrInstance = await hlr.deployed()
        const verifierInstance = await verifier.deployed()

        const receipt = await hlrInstance.verify(taskId, verifierInstance.address, proofs[0], pubSignals[1], { from: node1 })
        const taskMemeberEvent = receipt.logs[0]
        assert.isNotTrue(taskMemeberEvent.args[2])
        const taskEvent = receipt.logs[1]
        assert.isNotTrue(taskEvent.args[1])
    })

    it("get verifier state", async () => {
        const hlrInstance = await hlr.deployed()

        const state = await hlrInstance.getVerifierState.call(taskId)
        assert.lengthOf(state.unfinishedClients, 2)
        assert.includeMembers(state.unfinishedClients, [node2, node3])
        assert.lengthOf(state.invalidClients, 1)
        assert.includeMembers(state.invalidClients, [node1])
        assert.isNotTrue(state.valid)
    })

    it("verify rejected", async () => {
        const hlrInstance = await hlr.deployed()
        const verifierInstance = await verifier.deployed()

        await assert.isRejected(hlrInstance.verify(taskId, verifierInstance.address, proofs[1], pubSignals[1], { from: node2 }))
    })
})
