import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// Needed for __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const abiRoot = path.join(__dirname, "../frontend/src/abi/contracts/facets");
const outputPath = path.join(__dirname, "../frontend/src/abi/Diamond.json");

let merged = [];

// Recursively collect all .json files under facets/
function getAbiFiles(dir) {
  return fs.readdirSync(dir).flatMap(file => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      return getAbiFiles(fullPath);
    } else if (file.endsWith(".json")) {
      return [fullPath];
    } else {
      return [];
    }
  });
}

const files = getAbiFiles(abiRoot);

for (const file of files) {
  const abi = JSON.parse(fs.readFileSync(file));

  for (const item of abi) {
    if (!merged.find(existing => existing.name === item.name && existing.type === item.type)) {
      merged.push(item);
    }
  }
}

fs.writeFileSync(outputPath, JSON.stringify(merged, null, 2));
console.log(`✅ Merged ABI written to: ${outputPath}`);
