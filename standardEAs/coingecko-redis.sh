#!/bin/bash

docker run \
--name coingecko-redis \
--restart=unless-stopped \
--net eas-net \
--link redis-cache \
-p 1113:1113 \
-e EA_PORT=1113 \
-e TIMEOUT=30000 \
-e API_KEY=$COINGECKO_API_KEY \
-e CACHE_ENABLED=true \
-e CACHE_TYPE=redis \
-e CACHE_KEY_GROUP=coingecko \
-e CACHE_KEY_IGNORED_PROPS=meta \
-e CACHE_REDIS_HOST="192.168.1.1" \
-e CACHE_REDIS_PORT=6379 \
-e REQUEST_COALESCING_ENABLED=true \
-e REQUEST_COALESCING_INTERVAL=100 \
-e REQUEST_COALESCING_INTERVAL_MAX=1000 \
-e REQUEST_COALESCING_INTERVAL_COEFFICIENT=2 \
-e REQUEST_COALESCING_ENTROPY_MAX=0 \
-e LOG_LEVEL=info \
-e DEBUG=false \
-e API_VERBOSE=false \
-e EXPERIMENTAL_METRICS_ENABLED=true \
-e METRICS_NAME=coingecko \
-d public.ecr.aws/chainlink/adapters/coingecko-adapter:$1
# (With the shift in deploy option, the version moves to $1)
