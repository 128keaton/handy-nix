// Output from `networksetup -listallhardwareports -xml`

let output = `

Hardware Port: USB 10/100/1000 LAN
Device: en12
Ethernet Address: d8:d0:90:05:90:75

Hardware Port: Wi-Fi
Device: en0
Ethernet Address: 78:4f:43:7b:44:4f

Hardware Port: Bluetooth PAN
Device: en6
Ethernet Address: 78:4f:43:7a:79:ed

Hardware Port: Thunderbolt 1
Device: en1
Ethernet Address: 82:4b:cb:c5:58:01

Hardware Port: Thunderbolt 2
Device: en2
Ethernet Address: 82:4b:cb:c5:58:00

Hardware Port: Thunderbolt 3
Device: en3
Ethernet Address: 82:4b:cb:c5:58:05

Hardware Port: Thunderbolt 4
Device: en4
Ethernet Address: 82:4b:cb:c5:58:04

Hardware Port: Thunderbolt Bridge
Device: bridge0
Ethernet Address: 82:4b:cb:c5:58:01

VLAN Configurations
===================`;

let devices = [];
let currentDevice = {};
let camelize = (str) => {
  return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function(word, index) {
    return index === 0 ? word.toLowerCase() : word.toUpperCase();
  }).replace(/\s+/g, '');
};


// Split the output by new lines, then filter the lines to make sure that we're getting a Property and Value
output.split("\n").filter(line => line.length > 0 && line.includes(":")).forEach((line, index) => {
  // Get a propertyValue array like ["Hardware Port", "Thunderbolt Bridge"]
  let propertyValue = line.split(": ");

  // Add the property to the currentDevice variable, then assign a value
  currentDevice[camelize(propertyValue[0])] = `${propertyValue[1]}`;
  
  // Check if this is the third iteration for this item, meaning that we need to start over as the next line is a different device
  if (index % 3 == 0) {

    // Add the current device to the devices array
    devices.push(currentDevice);

    // Then clear all properties and values for the next iteration
    currentDevice = {};
  }

});

console.log(`Devices (${devices.length}):`, devices);
