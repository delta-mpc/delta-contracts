import Contract from "./contract.js";

const c = new Contract('Mpc');

c.deploy().then(() => {
    process.exit(0)
})
