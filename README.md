# Chainlink-EA-Manager
Collection of scripts for deploying and managing Chainlink External Adapters

---

#### This has been tested on Debian 10, 11, & 12.

(use at your own risk, consider this as 100% untested)

---
## General Directions
* Update the ```api_keys``` file with the keys for each of your external adapters.
* Update the ```misc_vars``` file with the environment variables that you need for your ExternalAdapters
* Modify the file(s) for the external adapter(s) you want deployed.

---
## Utilization
### Initialize a New Docker Environment for Chainlink External Adapters
* This will:
  * Install Docker-CE if it is not already installed.
  * Create a Docker Network for your external adapters
  * Deploy a Redis container for your external adapters' caching

```bash
sudo ./eaManager.sh -i
```


--
### Deploy New External Adapter With Specific Version
* This will:
  * Deploy a new external adapter of the selected release.

```bash
./eaManager.sh -d coingecko
```


--
### Upgrade an Existing External Adapter
* This will:
  * Stop the current container.
  * Remove the container.
  * Deploy a new container based on the selected image version.

```bash
./eaManager.sh -u coingecko
```


--
### Test an External Adapter
* This will:
  * Send a test request to an external adapter
  * Validate JSON payload (if `jq` is available)
  * Display the formatted response

#### Test by EA Name (Auto-Discovery)
The script will automatically discover the EA's endpoint from comments in the adapter script:

```bash
./eaManager -t --ea coingecko --file requests/generic
```

If the EA name is not found in the configuration, you'll be prompted to enter a URL for one-time use.

#### Test by Direct URL
Bypass auto-discovery and test a specific endpoint directly:

```bash
./eaManager -t --url http://192.168.1.113:1113 --file requests/generic
```

#### Test with Interactive Payload
Omit the `--file` option to paste JSON payload directly (press Ctrl-D when done):

```bash
./eaManager -t --ea coingecko
# Paste your JSON payload, then press Ctrl-D
```

#### How EA Auto-Discovery Works
The script scans `externalAdapters/` scripts for special comment headers:
```bash
# ea-name: coingecko-redis
# endpoint: http://192.168.1.113:1113
```

These are cached in `ea_endpoints` for quick lookup. The script will try exact matches first, then fall back to `-redis` suffix variants.

#### Test Options
- `-e, --ea <name>` - EA name for auto-discovery
- `-u, --url <URL>` - Direct URL (bypasses auto-discovery)
- `-f, --file <path>` - JSON payload file
- `-h, --help` - Show detailed test usage

```bash
# For detailed test options
./eaManager -t --help
```


--
### List all Supported External Adapter
* This will:
  * List all supported external adapter names

```bash
./eaManager.sh -l
```


--
