const { Web3 } = require("web3");

// Loading the contract ABI
// (the results of a previous compilation step)
const fs = require("fs");
const { abi } = JSON.parse(fs.readFileSync("Test.json"));

async function main() {
  // Configuring the connection to an Ethereum node
  const network = process.env.ETHEREUM_NETWORK;
  const web3 = new Web3(
    new Web3.providers.HttpProvider(
      //   `https://${network}.infura.io/v3/${process.env.INFURA_API_KEY}`
      `https://${network}.infura.io/v3/9ce57e1fce514c57ab012890f0ba1bef`
    )
  );
  // Creating a signing account from a private key
  const signer = web3.eth.accounts.privateKeyToAccount(
    "0x" + process.env.SIGNER_PRIVATE_KEY
  );
  web3.eth.accounts.wallet.add(signer);
  // Creating a Contract instance
  const contract = new web3.eth.Contract(
    abi,
    // Replace this with the address of your deployed contract
    process.env.DEMO_CONTRACT
  );

  // console.log({ signer });
  // Issuing a transaction that calls the `echo` method
  const start = Date.now();
  await contract.methods
    .setData(20)
    .send({ from: signer.address, gas: "1000000" });
  const end = Date.now();
  console.log(end - start);
  const data = await contract.methods.getData().call();
  console.log({ data });
}

require("dotenv").config();
main();
