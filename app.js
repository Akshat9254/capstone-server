require("dotenv").config();
const express = require("express");
const { addSensorData } = require("./blockchain");
const app = express();

app.use(express.json());

const PORT = process.env.PORT || 3001;

let addSensorEnabled = false;

app.post("/sensor/data", async (req, res) => {
  console.log({ body: req.body });
  const { manufacturerName, temperature, humidity } = req.body;
  if (!addSensorEnabled) {
    return res.status(400).json({ msg: "add sensor data flag is disabled!" });
  }
  try {
    res.json({ message: "batch add request pending..." });
    addSensorEnabled = false;
    await addSensorData(manufacturerName, temperature, humidity);
  } catch (error) {
    res.status(500).json({ msg: "something went wrong", error });
  }
});

app.put("/sensor/data/enable", (req, res) => {
  addSensorEnabled = true;
  return res.status(200).json({ msg: "add sensor data flag is enabled :)" });
});

app.listen(PORT, () => console.log(`server started at ${PORT}`));
