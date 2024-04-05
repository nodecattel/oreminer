This script automates the setup and running of the Ore CLI for $ORE mining operations on Soylana Manlet, ensuring you're always running the latest version and simplifying the mining setup process.

## Quick Start

To get started with the Ore Miner Auto Script, clone this repository to your local machine using the following command:

```bash
git clone https://github.com/nodecattel/ore.git
```

### Prerequisites

Before running the script, ensure you have the following installed:

- Rust and Cargo (The script will attempt to install these if they're not present)
- Solana CLI (Also installed by the script if not present)

### Give permission for script become executable

```bash
chmod +x install-ore.sh ore.sh
```
### Installation

Navigate to the cloned repository directory and run the `install-ore.sh` script to set up the necessary components:

```bash
cd ore
./install-ore.sh
```

Follow the on-screen instructions to complete the installation. The script will:

- Install Rust and Cargo
- Install the Solana CLI
- Install and update the Ore CLI to the latest version
- Set executable permissions for `ore.sh`
- Optionally run `ore.sh` for further setup

### Running Ore Miner

After installation, you can start the mining process by running:

```bash
chmod +x ore.sh
./ore.sh
```
