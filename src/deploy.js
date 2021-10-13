import Contract from "./contract.js";

const args = process.argv
const c = new Contract(args.length > 2 ? args[2] : 'Mpc');

c.deploy().then(() => {
    process.exit(0)
})
