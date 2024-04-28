require("dotenv").config();
const { Web3 } = require("web3");
const fs = require("fs");
const { abi } = JSON.parse(fs.readFileSync("V3.json"));

const network = process.env.ETHEREUM_NETWORK;
const web3 = new Web3(
  new Web3.providers.HttpProvider(
    //   `https://${network}.infura.io/v3/${process.env.INFURA_API_KEY}`
    `https://${network}.infura.io/v3/9ce57e1fce514c57ab012890f0ba1bef`
  )
);
const signer = web3.eth.accounts.privateKeyToAccount(
  "0x" + process.env.SIGNER_PRIVATE_KEY
);
web3.eth.accounts.wallet.add(signer);
const contract = new web3.eth.Contract(abi, process.env.V3_CONTRACT);

const addSensorData = async (manufacturerName, temperature, humidity) => {
  try {
    const receipt = await contract.methods
      .addSensorData(manufacturerName, temperature, humidity, Date.now())
      .send({
        from: signer.address,
        gas: "3000000",
      });
    console.log(`addSensorData: TransactionHash: ${receipt.transactionHash}`);
  } catch (error) {
    console.log(error);
    return false;
  }
};

module.exports = { addSensorData };
