ZK Mining on Boundless
Generate proofs and climb the leaderboard.

➜  Start mining  ➜
Connect your GPUs to Boundless
Compete for 5M $ZKC (0.5% of supply)*
coming July 2025
Quick setup
Start proving on Boundless in under 30 minutes. Scale up to 100 GPUs per node.


Quick start guide
Tue
Wed
Thu
Fri
Sat
12:00 AM
Connect GPUs

Start mining

Add more GPUs

Set your strategy
Set your pricing and capacity limits. Smart bidding algorithms allow you to optimize your proving earnings 24/7, even while you sleep.


Configure trader
2,534 ETH
Earn market fees and climb the leaderboard
Earn marketplace fees as you prove and climb the leaderboard. Compete for token rewards while supporting critical blockchain infrastructure.


View leaderboard


Quick Start
Warning
Incentives for provers are not active for this phase.
Need Help?
If you encounter issues that need technical support, join our Discord community and claim the prover role via Guild.xyz to get access to the #prover-support-forum channel. The Boundless team and experienced provers are there to help troubleshoot issues and share best practices.

Video Walkthrough
To run your prover on Base Mainnet, follow the steps in the video below and make sure to set your RPC endpoint to Base mainnet i.e:

Terminal

export RPC_URL="https://base-mainnet.g.alchemy.com/v2/{YOUR_ALCHEMY_APP_ID}"`

Boundless is in Beta!
This video was recorded early July 2025; there may be some further changes to the setup process. For the latest commands, make sure to check the tutorial below.

Clone the Boundless Repo
Use Ubuntu 22.04
We recommend using Ubuntu 22.04 LTS for your proving node.

To get started, first clone the Boundless monorepo on your proving machine, and switch to the latest release:

Terminal

git clone https://github.com/boundless-xyz/boundless
cd boundless
git checkout release-0.12
Install Dependencies
Tip
This stage can be skipped if you already have docker and docker-nvidia installed.

To run a Boundless prover, you'll need the following dependencies:

Docker compose
Docker Nvidia Support (Note: the install process requires enabling NVIDIA’s experimental packages)
For a quick set up of Boundless dependencies on Ubuntu 22.04 LTS (see Operating System Requirements), please run:


sudo ./scripts/setup.sh
Setup Environment Variables
You'll need to set two environment variables:

Terminal

export PRIVATE_KEY=""
export RPC_URL=""
This is the private key to the wallet which will represent your prover on the market; make sure it has funds. For the RPC url, we recommend using an Alchemy endpoint for the network you want to prove on.

Running a Test Proof
See all just commands
We make use of just to make running complex commands easier. To see available just commands for Boundless, run just within the root boundless/ folder.

Boundless is comprised of two major components:

Bento is the local proving infrastructure. Bento will take requests, prove them and return the result.
The Broker interacts with the Boundless market. Broker can submit or request proves from the market.
To get started with a test proof on a new proving machine, you'll need to install the bento_cli:

Terminal

cargo install --locked --git https://github.com/risc0/risc0 bento-client --branch release-2.1 --bin bento_cli
Once installed, you can run bento with:

Terminal

just bento
This will spin up bento without the broker. You can check the logs at any time with:

Terminal

just bento logs
To run the test proof:

Terminal

RUST_LOG=info bento_cli -c 32
If everything works, you should see something like the following:

Bento CLI Test Proof Success

Running the Broker
Need technical support?
For technical support, please join the Boundless Discord and claim the prover role from Guild.xyz.

We have checked that bento successfully generated a test proof. We are now ready to run the broker so that we can start proving on Boundless.

Install the Boundless CLI
Before we start, we'll need to install the Boundless CLI (which is separate to the Bento CLI we installed earlier):

Terminal

cargo install --locked boundless-cli
Deposit Stake
Note
To read more about depositing funds to the market, please see Deposit / Balance.
If you need testnet USDC on Base Sepolia, please use the Circle Testnet Faucet.
With the environment variables set, you can now deposit USDC tokens as stake to your account balance:

Terminal

boundless account deposit-stake 10
Start Broker
You can now start broker (which runs both bento + broker i.e. the full proving stack!):

Terminal

just broker
To check the proving logs, you can use:

Terminal

just broker logs
Stop Broker
To stop broker, you can run:

Terminal

just broker down
Or remove all volumes and data from the service:

Terminal

just broker clean
Configuring Broker
Custom Environment
Instead of passing environment variables for each shell session as we did above, you can set them in .env.broker. There is an .env.broker-template available for you to get started:

Terminal

cp .env.broker-template .env.broker
After which, you can use a text editor to adjust the environment variables as required.

To run broker with a custom environment file:

Terminal

just broker up ./.env.broker
just broker down ./.env.broker
Broker.toml
Broker can be configured using the Broker.toml configuration file.

For example, to adjust the maximum number of proofs that can be processed at once, you can set:

boundless/Broker.toml

# Maximum number of concurrent proofs that can be processed at once
max_concurrent_proofs = 2 # change "2"
To see all Broker.toml configuration settings, please see Broker Configuration & Operation/Settings in Broker.toml.

Multi Host
Services can be run on other hosts, as long as the IP addresses for things link PostgreSQL / Redis / MinIO are updated on the remote host.

See the .env.broker-template HOST configuration options here to adjust them.

Configuring Bento
The compose.yml file defines all services within Bento. The Boundless repo includes a starter compose.yml which you can see here.

Multi GPU
Under the exec_agent service in compose.yml, the default configuration utilises a single GPU:

compose.yml

deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          device_ids: ['0']
          capabilities: [gpu]
To add a second GPU, first check your GPUs are recognised with:

Terminal

nvidia-smi -L
which should output something like:


GPU 0: NVIDIA GeForce RTX 3090 (UUID: GPU-abcde123-4567-8901-2345-abcdef678901)
GPU 1: NVIDIA GeForce RTX 3090 (UUID: GPU-fedcb987-6543-2109-8765-abcdef123456)
We can see that GPU 1 is listed with the device ID of 1. To add this GPU, uncomment gpu_prove_agent1 from compose.yml:

compose.yml

gpu_prove_agent1: 
  <<: *agent-common
  runtime: nvidia
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            device_ids: ['1'] 
            capabilities: [gpu]
For 3 or more GPUs, add the corresponding gpu_prove_agentX where X matches the device ID of each GPU, making sure that the device_ids field is populated with a matching X: ['X'].

Segment Size
Segment Sizes + Security
Larger SEGMENT_SIZE values also impact the proving systems conjectured security bits slightly (see RISC Zero - Cryptographic Security Model).

SEGMENT_SIZE is specified in powers-of-two (po2). Larger segment sizes are preferable for performance, but require more GPU VRAM. To pick the right SEGMENT_SIZE for your GPU VRAM, see the performance optimization page.

Setting SEGMENT_SIZE
The recommended way to change the segment size is to set the environment variable SEGMENT_SIZE, before running broker, to your specified value. This can be done through the .env.broker file.

You can also configure the SEGMENT_SIZE in compose.yml under the exec_agent service; it defaults to 21:

compose.yml

exec_agent:
  <<: *agent-common
  runtime: nvidia
 
  mem_limit: 4G
  cpus: 4
 
  environment:
    <<: *base-environment
    RISC0_KECCAK_PO2: ${RISC0_KECCAK_PO2:-17}
    entrypoint: /app/agent -t exec --segment-po2 ${SEGMENT_SIZE:-21}
What next?
Need technical support?
For technical support, please join the Boundless Discord and claim the prover role from Guild.xyz.

Next, you'll need to tune your Broker's settings, please see Broker Optimization.

If you'd like to learn more about the technical design of Bento, please see the Bento Technical Design.

To see your prover market statistics, check out the provers page on the Boundless Explorer.

Broker Configuration & Operation
Overview
The Broker is a service that runs within the Bento proving stack. It is responsible for market interactions including bidding on jobs, locking them, issuing job requests to the Bento proving cluster, and submitting proof fulfillments onchain.

Broker Configuration
Tip
Broker will live-reload the broker.toml when it changes. In most cases, you will not need to restart the Broker for the configuration to take effect.

Broker configuration is primarily managed through the broker.toml file in the Boundless directory. This file is mounted into the Broker container and it is used to configure the Broker daemon.

Deposit / Balance
The Boundless market requires funds (USDC) deposited as stake before a prover can bid on requests. Brokers must first deposit some USDC into the market contract to fund their account. These funds cover staking during lock-in. It is recommend that a broker keep a balance on the market >= max_stake (configured via broker.toml).

Deposit Stake to the Market
Note
You will need the Boundless CLI installed to deposit/check your balance. Please see Installing the Boundless CLI for instructions.

Terminal

export RPC_URL=<TARGET_CHAIN_RPC_URL>
export PRIVATE_KEY=<BROKER_PRIVATE_KEY>
# Use the env file based on the network you are connecting to
source .env.eth-sepolia
 
# Example: 'account deposit-stake 100'
boundless account deposit-stake <USDC_TO_DEPOSIT>
Check Current Stake Balance
Terminal

export RPC_URL=<TARGET_CHAIN_RPC_URL>
export PRIVATE_KEY=<BROKER_PRIVATE_KEY>
# Use the env file based on the network you are connecting to
source .env.eth-sepolia
 
boundless account stake-balance [wallet_address]
You can omit the PRIVATE_KEY environment variable here and specify your wallet_address as a optional parameter to the balance command, i.e., account balance 0x000....

Settings in Broker.toml
Warning
Quotation marks matter in TOML so please pay particular attention to the quotation marks for config values.

broker.toml contains the following settings for the market:

setting	initial value	description
mcycle_price	".001"	The price (in native token of target market) of proving 1M cycles.
assumption_price	"0.1"	Currently unused.
peak_prove_khz	500	This should correspond to the maximum number of cycles per second (in kHz) your proving backend can operate.
min_deadline	150	This is a minimum number of blocks before the requested job expiration that Broker will attempt to lock a job.
lookback_blocks	100	This is used on Broker initialization, and sets the number of blocks to look back for candidate proofs.
max_stake	"0.5"	The maximum amount used to lock in a job for any single order.
skip_preflight_ids	[]	A list of imageIDs that the Broker should skip preflight checks in format ["0xID1","0xID2"].
max_file_size	50_000_000	The maximum guest image size in bytes that the Broker will accept.
allow_client_addresses	[]	When defined, this acts as a firewall to limit proving only to specific client addresses.
lockin_priority_gas	100	Additional gas to add to the base price when locking in stake on a contract to increase priority.
Broker Operation
Terminal

2024-10-23T14:37:37.364844Z  INFO bento_cli: image_id: a0dfc25e54ebde808e4fd8c34b6549bbb91b4928edeea90ceb7d1d8e7e9096c7 | input_id: eccc8f06-488a-426c-ae3d-e5acada9ae22
2024-10-23T14:37:37.368613Z  INFO bento_cli: STARK job_id: 0d89e2ca-a1e3-478f-b89d-8ab23b89f51e
2024-10-23T14:37:37.369346Z  INFO bento_cli: STARK Job running....
2024-10-23T14:37:39.371331Z  INFO bento_cli: STARK Job running....
2024-10-23T14:37:41.373508Z  INFO bento_cli: STARK Job running....
2024-10-23T14:37:43.375780Z  INFO bento_cli: Job done!
Benchmarking Bento
Load environment variables for the target network:

Terminal

# For example, to benchmark an order on Ethereum Sepolia
source .env.eth-sepolia
 
# Load any other relevant env variables here, specifically `RPC_URL` and postgres env (if not default)
Start a bento cluster:

Terminal

just bento
Then, run the benchmark:

Terminal

boundless proving benchmark --request-ids <IDS>
where IDS is a comma-separated list of request IDs from the network or order stream configured.

It is recommended to pick a few requests of varying sizes and programs, biased towards larger proofs for a more representative benchmark.

To run programs manually, and for performance optimizations, see performance optimizations.

Running the Broker service with bento
Running a broker with just will also start the Bento cluster through docker compose.

Note
just installation instructions can be found here.

Terminal

just broker
Make sure Bento is running
Warning
A Broker needs a Bento instance to operate. Please follow the quick start guide to get Bento up and running.

To check Bento is running correctly, you can send a sample proof workload:

Before running this, install Bento CLI

Terminal

# In the bento directory
RUST_LOG=info bento_cli -c 32
Running a standalone broker
To run broker with an already initialized Bento cluster or with a different prover, you can build and run a broker directly with the following:

Terminal

cargo build --bin broker --release
# Run with flags or environment variables based on network/configuration
./target/release/broker
Stopping The Broker Service
Terminal

just broker down
Warning
If running the broker on a network, there may be locked proofs that have not been fulfilled yet. Follow the Safe Upgrade Steps to ensure shutdown and/or restart without loss of stake.

Safe Upgrade Steps
Breaking Changes
There can be subtle breaking changes between releases that may affect your broker's state. Following these upgrade steps helps minimize issues from state breaking changes.

When upgrading your Boundless broker to a new version, follow these steps to ensure a safe migration:

Stop the broker and optionally clean the database
Terminal

just broker clean
 
# Or stop the broker without clearing volumes
just broker down
This will wait for any committed orders to finalize before shutting down. Avoid sending kill signals to the broker process and ensure either through the broker logs or through indexer that your broker does not have any incomplete locked orders before proceeding.

Database Cleanup
While it is generally not necessary to clear volumes unless specifically noted in release, it is recommended to avoid any potential state breaking changes.

Update to the new version
See releases for latest tag to use.

Terminal

git checkout <new_version_tag>
# Example: git checkout v0.9.0
Start the broker with the new version
Terminal

just broker
Running Multiple Brokers
You can run multiple broker instances simultaneously to serve different networks at the same time while sharing the same Bento cluster. The Docker compose setup supports this through the broker2 service example.

Multi-Broker Configuration
Each broker instance requires:

Separate configuration file: Create different broker.toml files (e.g., broker.toml, broker2.toml, etc.)
Different RPC URL: Use different chain endpoints via setting respective RPC_URL environment variables, or modifying the compose.yml manually.
Optional separate private key: Use different PRIVATE_KEY variables if desired for different accounts on different networks.
Environment Variables for Multi-Broker Setup
If using the default compose.yml file and uncommenting the second broker config:

.env

# Export environment variables for the first broker
export RPC_URL=<URL for network 1>
export PRIVATE_KEY=0x...
 
# Export environment variables for the second broker
export RPC_URL_2=<URL for network 2>
Then, create the new broker config file that the second broker will use:

Terminal

# Copy from an existing broker config file
cp broker.toml broker2.toml
 
# Or creating one from a fresh template
cp broker-template.toml broker2.toml
Then, modify configuation values for each network, keeping the following in mind:

The peak_prove_khz setting is shared across all brokers
For example, if you have benchmarked your broker to be able to prove at 500kHz, the values in each config should not sum up to be more than 500kHz.
max_concurrent_preflights is set to a value that the bento cluster can keep up with
It is recommended that the max concurrent preflights across all networks is less than the number of exec agents you have specified in your compose.yml.
max_concurrent_proofs is a per-broker configuration, and is not shared across brokers
Then, just start the cluster as you normally would with:

Terminal

just broker
Broker Optimization
Increasing Lock-in Rate
Once your broker is running, there are a few methods to optimize the lock-in rate. These methods are aimed at making your broker service more competitive in the market through different means:

Decreasing the mcycle_price would tune your Broker to bid at lower prices for proofs.
Increasing lockin_priority_gas expedites your market operations by consuming more gas which could help outrun other bidders.
Tuning Service Settings
The [prover] settings in broker.toml are used to configure the prover service and significantly impact the operation of the service. The most important configuration variable to monitor and iteratively tune is txn_timeout. This is the number of seconds to wait for a transaction to be confirmed before timing out. Therefore, if you see timeouts in your logs, txn_timeout can be increased to wait longer for transaction confirmations onchain.