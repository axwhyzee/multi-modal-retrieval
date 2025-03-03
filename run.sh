#!/bin/bash

repos=(
    "multi-modal-retrieval-storage-service"
    "multi-modal-retrieval-gateway-service"
    "multi-modal-retrieval-embedding-service"
    "multi-modal-retrieval-preprocessor-service"
    "multi-modal-retrieval-frontend"
)

for repo in "${repos[@]}"; do
    if [ -d "$repo" ]; then
        echo "$repo already exists, skipping..."
    else
        git clone "https://github.com/axwhyzee/$repo.git" && echo "Cloned $repo"
    fi

docker-compose up -d

done
