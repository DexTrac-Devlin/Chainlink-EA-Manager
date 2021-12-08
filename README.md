# Chainlink-EA-Manager
Collection of scripts for deploying and managing Chainlink External Adapters

---

#### This has been tested on Debian 10 & 11.

(use at your own risk, consider this as 100% untested)

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
  * Deploy a new external adapter of the desired release.
  
```bash
sudo ./eaManager.sh -d coingecko 1.0.0
```


--
### Upgrade an Existing External Adapter
* This will:
  * Stop the current container.
  * Remove the container image.
  * Deploy a new container based on the desired iamge version.

```bash
sudo ./eaManager.sh -u coingecko 1.0.4
```


--

### Generael Directions
* Update the api_keys file with the keys for each of your external adapters.
* Modify the file(s) for the external adapter(s) you want deployed located in their respective directories.
  * standardEAs contains the standard external adapters.
  * compositeEAs contains the composite external adapters. 
