// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract V3 {
    // Structure to represent a Medicine
    struct Medicine {
        string name;
        uint temperatureRangeMin;
        uint temperatureRangeMax;
        uint humidityRangeMin;
        uint humidityRangeMax;
    }

    // Structure to represent SensorData
    struct SensorData {
        uint temperature;
        uint humidity;
        uint createdAt; 
    }

    // Structure to represent a Manufacturer
    struct Manufacturer {
        string name;
        bool isRegistered;
    }

    // Structure to represent a Batch
    struct Batch {
        string batchId;
        string medicineName;
        SensorData[] sensorData;
        uint createdAt;
    }

     // Mapping to store batches for each manufacturer
    mapping(string => string[]) public manufacturerBatches;

    // Mapping to store batch details
    mapping(string => Batch) public batches;

    // Event to emit when a new batch is added
    event BatchAdded(address indexed manufacturer, string batchId, string medicineName);

    // Mapping to store medicines
    mapping(string => Medicine) public medicines;

    // Array to store medicine names
    string[] public medicineNames;


    // Mapping to store manufacturers
    mapping(string => Manufacturer) public manufacturers;


    // Function to register a medicine
    function registerMedicine(
        string memory _name,
        uint _temperatureRangeMin,
        uint _temperatureRangeMax,
        uint _humidityRangeMin,
        uint _humidityRangeMax
    ) external {
        require(medicines[_name].temperatureRangeMin == 0, "Medicine already registered");

        Medicine storage newMedicine = medicines[_name];
        newMedicine.name = _name;
        newMedicine.temperatureRangeMin = _temperatureRangeMin;
        newMedicine.temperatureRangeMax = _temperatureRangeMax;
        newMedicine.humidityRangeMin = _humidityRangeMin;
        newMedicine.humidityRangeMax = _humidityRangeMax;

        medicineNames.push(_name);
    }

    // Function to register a manufacturer
    function registerManufacturer(string memory _name) external {
        require(!manufacturers[_name].isRegistered, "Manufacturer already registered");

        manufacturers[_name] = Manufacturer(_name, true);
    }

    function isRegisteredUser(string memory _name) external view returns (bool) {
        // Check if the user is a registered manufacturer
        return manufacturers[_name].isRegistered;
    }

    // Function to add a batch with a medicineName
    function addBatch(
        string memory _medicineName, 
        string memory _manufacturerName,
        uint _createdAt
    ) external {
        // Check if the medicine is registered
        require(bytes(medicines[_medicineName].name).length != 0, "Medicine not registered");

        // Get the current batchId
        uint batchIndex = manufacturerBatches[_manufacturerName].length;
        string memory batchId;

        // Generate the batchId
        if (batchIndex == 0) {
            batchId = string(abi.encodePacked(_manufacturerName, "$b0"));
        } else {
            batchId = string(abi.encodePacked(_manufacturerName, "$b", uintToString(batchIndex)));
        }

        // Check if batchId is unique
        require(bytes(batches[batchId].batchId).length == 0, "BatchId already exists");

        // Create a new batch
        Batch storage newBatch = batches[batchId];
        newBatch.batchId = batchId;
        newBatch.medicineName = _medicineName;
        newBatch.createdAt = _createdAt;

        // Add the batchId to the manufacturerBatches mapping
        manufacturerBatches[_manufacturerName].push(batchId);

        // Emit event
        emit BatchAdded(msg.sender, batchId, _medicineName);
    }

    // Function to convert uint to string
    function uintToString(uint v) internal pure returns (string memory) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        return string(s);
    }

    // Function to add SensorData for a batch with batchId
    function addSensorData(
        string memory _manufacturerName,
        uint _temperature,
        uint _humidity,
        uint _createdAt
    ) external returns (bool) {
        // Check if the batch exists
        require(manufacturerBatches[_manufacturerName].length != 0, "Batch does not exist");

        // Get the current batchId
        uint lastIndex = manufacturerBatches[_manufacturerName].length - 1;
        string memory batchId = manufacturerBatches[_manufacturerName][lastIndex];

        // Retrieve the batch for the given batchId
        Batch storage batch = batches[batchId];

        // Initialize a flag to track validation result
        bool isValid = true;

        // Validate temperature and humidity ranges
        if (_temperature < medicines[batch.medicineName].temperatureRangeMin || _temperature > medicines[batch.medicineName].temperatureRangeMax) {
            isValid = false;
        }
        if (_humidity < medicines[batch.medicineName].humidityRangeMin || _humidity > medicines[batch.medicineName].humidityRangeMax) {
            isValid = false;
        }

        // Access the newly created SensorData entry
        SensorData storage newSensorData = batch.sensorData.push();

        // Populate the new SensorData instance
        newSensorData.temperature = _temperature;
        newSensorData.humidity = _humidity;
        newSensorData.createdAt = _createdAt;

        return isValid;
    }



    // Function to get all SensorData for a batchId
    function getSensorData(string memory _batchId) external view returns (
        uint[] memory temperatures, uint[] memory humidities, uint[] memory createdAts, 
        string memory medicineName) {
        // Retrieve the batch for the given batchId
        Batch storage batch = batches[_batchId];

        // Check if the batch exists
        require(bytes(batch.batchId).length != 0, "Batch does not exist");

        // Get the length of the sensorData array
        uint length = batch.sensorData.length;

        // Initialize arrays to store sensor data
        temperatures = new uint[](length);
        humidities = new uint[](length);
        createdAts = new uint[](length);
        medicineName = batch.medicineName;

        // Iterate through the sensorData array and retrieve each SensorData entry
        for (uint i = 0; i < length; i++) {
            SensorData storage data = batch.sensorData[i];
            
            temperatures[i] = data.temperature;
            humidities[i] = data.humidity;
            createdAts[i] = data.createdAt;
        }
    }

    // Function to get all medicine names
    function getAllMedicineNames() external view returns (string[] memory) {        
        return medicineNames;
    }

    // Function to get all batch details of a manufacturer
    function getAllBatchDetailsOfManufacturer(string memory _manufacturerName) external view returns (string[] memory, string[] memory, uint[] memory, uint[] memory) {
        // Retrieve the batch IDs of the manufacturer
        string[] memory batchIds = manufacturerBatches[_manufacturerName];

        // Initialize arrays to store batch details
        string[] memory batchIdDetails = new string[](batchIds.length);
        string[] memory medicineNamesArr = new string[](batchIds.length);
        uint[] memory numReadings = new uint[](batchIds.length);
        uint[] memory createdAts = new uint[](batchIds.length);

        // Iterate through batch IDs
        for (uint i = 0; i < batchIds.length; i++) {
            // Retrieve batch details from batches mapping
            Batch storage batch = batches[batchIds[i]];

            // Store batch details
            batchIdDetails[i] = batch.batchId;
            medicineNamesArr[i] = batch.medicineName;
            numReadings[i] = batch.sensorData.length;
            createdAts[i] = batch.createdAt;
        }

        return (batchIdDetails, medicineNamesArr, numReadings, createdAts);
    }

    function getNumberBatchesForManufacturer(string memory _manufacturerName) external view returns(uint) {
        return manufacturerBatches[_manufacturerName].length;
    }

    // Function to get medicine details by name
    function getMedicineDetails(string memory _medicineName) external view returns (
        uint temperatureRangeMin,
        uint temperatureRangeMax,
        uint humidityRangeMin,
        uint humidityRangeMax
    ) {
        // Retrieve medicine details by name
        Medicine storage medicine = medicines[_medicineName];

        // Check if the medicine exists
        require(bytes(medicine.name).length != 0, "Medicine not found");

        // Get medicine details
        temperatureRangeMin = medicine.temperatureRangeMin;
        temperatureRangeMax = medicine.temperatureRangeMax;
        humidityRangeMin = medicine.humidityRangeMin;
        humidityRangeMax = medicine.humidityRangeMax;
    }
}
