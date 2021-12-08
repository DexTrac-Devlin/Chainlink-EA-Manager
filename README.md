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
