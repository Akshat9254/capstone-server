// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract V2 {
    // Structure to represent a Medicine
    struct Medicine {
        string name;
        string[] chemicalNames;
        uint[] chemicalRatios;
        uint temperatureRangeMin;
        uint temperatureRangeMax;
        uint humidityRangeMin;
        uint humidityRangeMax;
    }

    // Structure to represent SensorData
    struct SensorData {
        uint temperature;
        uint humidity;
        string[] chemicalNames;
        uint[] chemicalWeights; 
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
    mapping(address => Manufacturer) public manufacturers;

    // Modifier to check if the caller is a registered manufacturer
    modifier onlyManufacturer() {
        require(manufacturers[msg.sender].isRegistered, "Only registered manufacturers can access this functionality");
        _;
    }

    // Function to register a medicine
    function registerMedicine(
        string memory _name,
        uint[] memory _chemicalRatios,
        string[] memory _chemicalNames,
        uint _temperatureRangeMin,
        uint _temperatureRangeMax,
        uint _humidityRangeMin,
        uint _humidityRangeMax
    ) external {
        require(medicines[_name].temperatureRangeMin == 0, "Medicine already registered");

        // Validate input lengths
        require(_chemicalRatios.length == _chemicalNames.length, "Invalid input lengths");

        Medicine storage newMedicine = medicines[_name];
        newMedicine.name = _name;
        newMedicine.temperatureRangeMin = _temperatureRangeMin;
        newMedicine.temperatureRangeMax = _temperatureRangeMax;
        newMedicine.humidityRangeMin = _humidityRangeMin;
        newMedicine.humidityRangeMax = _humidityRangeMax;

        // Assign chemical ratios
        for (uint i = 0; i < _chemicalNames.length; i++) {
            newMedicine.chemicalNames.push(_chemicalNames[i]);
            newMedicine.chemicalRatios.push(_chemicalRatios[i]);
        }

        medicineNames.push(_name);
    }

    // Function to register a manufacturer
    function registerManufacturer(string memory _name) external {
        require(!manufacturers[msg.sender].isRegistered, "Manufacturer already registered");

        manufacturers[msg.sender] = Manufacturer(_name, true);
    }

    // Function to add a batch with a medicineName
    function addBatch(
        string memory _batchId, 
        string memory _medicineName, 
        string memory _manufacturerName,
        uint _createdAt) external onlyManufacturer {
        // Check if the medicine is registered
        require(bytes(medicines[_medicineName].name).length != 0, "Medicine not registered");

        // Check if batchId is unique
        require(bytes(batches[_batchId].batchId).length == 0, "BatchId already exists");

        // Create a new batch
        Batch storage newBatch = batches[_batchId];
        newBatch.batchId = _batchId;
        newBatch.medicineName = _medicineName;
        newBatch.createdAt = _createdAt;

        // Add the batchId to the manufacturerBatches mapping
        manufacturerBatches[_manufacturerName].push(_batchId);

        // Emit event
        emit BatchAdded(msg.sender, _batchId, _medicineName);
    }

    // Function to add SensorData for a batch with batchId
    function addSensorData(
        string memory _batchId,
        uint _temperature,
        uint _humidity,
        uint[] memory _chemicalWeights,
        string[] memory _chemicalNames,
        uint _createdAt
    ) external returns (bool) {
        // Retrieve the batch for the given batchId
        Batch storage batch = batches[_batchId];
        Medicine storage medicine = medicines[batch.medicineName];

        // Check if the batch exists
        require(bytes(batch.batchId).length != 0, "Batch does not exist");

        // Check if _chemicalNames length matches Medicine's chemicalNames length
        require(_chemicalNames.length == medicine.chemicalNames.length, "Invalid chemical names length");

        // Initialize a flag to track validation result
        bool isValid = true;

        // Validate temperature and humidity ranges
        if(_temperature < medicines[batch.medicineName].temperatureRangeMin || _temperature > medicines[batch.medicineName].temperatureRangeMax) {
            isValid = false;
        }
        if(_humidity < medicines[batch.medicineName].humidityRangeMin || _humidity > medicines[batch.medicineName].humidityRangeMax) {
            isValid = false;
        }

        // Create a temporary array for chemical ratios
        uint[] memory chemicalRatios = new uint[](_chemicalNames.length);
        for (uint i = 0; i < medicine.chemicalNames.length; i++) {
            // Find the index of chemical name in _chemicalNames array
            uint index;
            for (uint j = 0; j < _chemicalNames.length; j++) {
                if (keccak256(bytes(_chemicalNames[j])) == keccak256(bytes(medicine.chemicalNames[i]))) {
                    index = j;
                    break;
                }
            }
            chemicalRatios[i] = medicine.chemicalRatios[index];
        }

        // Calculate total weight of chemicals
        uint totalWeight = 0;
        for (uint i = 0; i < _chemicalWeights.length; i++) {
            totalWeight += _chemicalWeights[i];
        }

        // Calculate total parts based on predefined ratios
        uint totalParts = 0;
        for (uint i = 0; i < chemicalRatios.length; i++) {
            totalParts += chemicalRatios[i];
        }

        // Validate chemical data against predefined ratios
        for (uint i = 0; i < _chemicalNames.length; i++) {
            // Validate chemical data against predefined ratios
            uint lhs = chemicalRatios[i] * totalWeight;
            uint rhs = _chemicalWeights[i] * totalParts;
            if(lhs != rhs) {
                isValid = false;
                break;
            }
        }

        // Access the newly created SensorData entry
        SensorData storage newSensorData = batch.sensorData.push();

        // Populate the new SensorData instance
        newSensorData.temperature = _temperature;
        newSensorData.humidity = _humidity;
        newSensorData.createdAt = _createdAt;

        // Add chemical data to the new SensorData instance
        for (uint i = 0; i < _chemicalNames.length; i++) {
            newSensorData.chemicalNames.push(_chemicalNames[i]);
            newSensorData.chemicalWeights.push(_chemicalWeights[i]);
        }

        return isValid;
    }


    // Function to get all SensorData for a batchId
    function getSensorData(string memory _batchId) external view returns (
        uint[] memory temperatures, uint[] memory humidities, uint[] memory createdAts, 
        uint[][] memory chemicalWeights, string[][] memory chemicalNames, 
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
        chemicalWeights = new uint[][](length);
        chemicalNames = new string[][](length);
        medicineName = batch.medicineName;

        // Iterate through the sensorData array and retrieve each SensorData entry
        for (uint i = 0; i < length; i++) {
            SensorData storage data = batch.sensorData[i];
            
            temperatures[i] = data.temperature;
            humidities[i] = data.humidity;
            createdAts[i] = data.createdAt;

            // Store chemical data
            uint[] memory weights = new uint[](data.chemicalNames.length);
            string[] memory names = new string[](data.chemicalNames.length);
            for (uint j = 0; j < data.chemicalNames.length; j++) {
                weights[j] = data.chemicalWeights[j];
                names[j] = data.chemicalNames[j];
            }
            chemicalWeights[i] = weights;
            chemicalNames[i] = names;
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

    // Function to get medicine details by name
    function getMedicineDetails(string memory _medicineName) external view returns (
        uint temperatureRangeMin,
        uint temperatureRangeMax,
        uint humidityRangeMin,
        uint humidityRangeMax,
        string[] memory chemicalNames,
        uint[] memory ratios
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
        chemicalNames = medicine.chemicalNames;
        ratios = medicine.chemicalRatios;
    }
}
