## Disclaimer 👷‍♂️

This code is experimental and provided "as is", without warranty of any kind. Use it at your own risk. It's under development, and its features may change. Always back up your data before use. Contributions and feedback are welcome.

The script automates the setup and running of the Ore CLI for $ORE mining operations on Soylana Manlet, ensuring you're always running the latest version and simplifying the mining setup process.

ORE program address `oreV2ZymfyeXgNgBdqMkumTqqAprVqgBWQfoYkrtKWQ`

$ORE (V2) token address `oreoU2P8bN6jkk3jbaiVxYnG1dCXcYxwhwyK9jSybcp`

$ORE (V1) token address `oreoN2tQbHXVaZsr3pf66A48miqcBXCDJozganhEJgz` - mining paused, migrate to v2 if you have

## Oreminer script cli interface sample 

![ORE Miner Interface Sample](https://github.com/nodecattel/oreminer/blob/51a8793be37bc72f683ffd24bf8ec9e8ba79f510/oreminer-interface-sample.png)

## Quick Start 🛠️

To get started with the Ore Miner Auto Script, clone this repository to your local machine using the following command:

```bash
git clone https://github.com/nodecattel/oreminer.git
cd oreminer
```

### Prerequisites ✅

Before running the script, ensure you have the following installed:

- Rust and Cargo (The script will attempt to install these if they're not present)
- Solana CLI (Also installed by the script if not present)
- (Recommended) Private RPC endpoints for fast & secure mining hash submission. You can use our referal link for [Quicknode here](https://www.quicknode.com/?via=nodecattel)
### Give permission for script become executable

```bash
chmod +x install.sh ore.sh upgrade.sh
```
### Installation 💻

Navigate to the cloned repository directory and run the `install.sh` script to set up the necessary components:

```bash
./install.sh
```
We have added few options for installation which has mainnet (official ore-cli), jito dynamic tip (dannpl fork) and panda optimized cores (JustPandaEver fork)

Follow the on-screen instructions to complete the installation. The script will:

- Install Rust and Cargo
- Install the Solana CLI
- Create New Wallet if not exist : !!! note down your SEED PHRASE !!!
- Install and update the Ore CLI to the latest version
- Set executable permissions for `ore.sh`
- Optionally run `ore.sh` for further setup

### Running Ore Miner ⛏️

Fund your wallet with some sol

Show solana address on your machine : locate at $HOME/.config/solana/id.json
```
solana address
```

After installation, fund your wallet and you can start the mining process by running:

```bash
./ore.sh mine
```

See all available commands

```
./ore.sh
```

Upgrade ORE-CLI version
```
./upgrade.sh
```

### Change default variable config manually

To change your setting please set up in `ore.conf` located at `$HOME/.ore`
```bash
cd $HOME/.ore
nano ore.conf
```
### Export Private key to external wallet
```bash
cat $HOME/.config/solana/id.json
```
Then copy the output to your external wallet like Phantom, Backpack

### Useful Links

Ore Cli's creates

```
https://crates.io/crates/ore-cli
```

Official Ore-Cli repository

```
https://github.com/regolith-labs/ore-cli
```
Dune $ORE PoW Mining on Soylana Manlet

```
https://dune.com/rawrmaan/ore-mining-solana
```

`$ORE` Price chart

```
https://birdeye.so/token/oreoU2P8bN6jkk3jbaiVxYnG1dCXcYxwhwyK9jSybcp?chain=solana
```


If you find values to the scripts here please [Follow NodeCattel on X](https://twitter.com/nodecattel)
