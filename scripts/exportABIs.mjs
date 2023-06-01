import fs from 'fs';
import path from 'path';

async function processContract(baseArtifactsPath, contractName) {
  // Construct the artifact path for the specific contract
  const artifactsPath = path.join(baseArtifactsPath, `${contractName}.sol`);

  // Read the artifact file
  const contractPath = path.join(artifactsPath, `${contractName}.json`);
  console.log('Contract path:', contractPath);

  const contract = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

  // Extract the ABI
  const abi = contract.abi;

  // Save the ABI to a new file in the original directory
  const outputFilePath = path.join(artifactsPath, `${contractName}.abi.json`);
  fs.writeFileSync(outputFilePath, JSON.stringify(abi, null, 2));
  console.log(`ABI saved to ${outputFilePath}`);

  // Also save the ABI to a new file in the frontend directory
  const frontendDir = path.resolve('./frontend/src/contractABIs/');
  const frontendOutputFilePath = path.join(frontendDir, `${contractName}.abi.json`);
  fs.writeFileSync(frontendOutputFilePath, JSON.stringify(abi, null, 2));
  console.log(`ABI also saved to ${frontendOutputFilePath}`);
}

async function main() {
  const baseArtifactsPath = '/home/njdaniel/RockPaperSatoshiHardhat/artifacts/contracts/';
  console.log('Base Artifacts path:', baseArtifactsPath);

  // List of contract names
  const contractNames = [
    'RockPaperSatoshi',
    'RPSHashHealToken',
    'RPSRareItemsToken',
    'RPSatoshiToken'
  ];

  // Process each contract
  for (const contractName of contractNames) {
    await processContract(baseArtifactsPath, contractName);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
