import Contract from "./contract.js";

const args = process.argv
const c = new Contract(args.length > 2 ? args[2] : 'Mpc');
const deployArgs = args.length > 3 ? args.slice(3): [];

c.deploy(deployArgs).then(() => {
    process.exit(0)
})
