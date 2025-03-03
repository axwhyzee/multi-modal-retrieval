#!/bin/bash

repos=(
    "git clone https://github.com/axwhyzee/multi-modal-retrieval-storage-service.git"
    "git clone https://github.com/axwhyzee/multi-modal-retrieval-gateway-service.git"
    "git clone https://github.com/axwhyzee/multi-modal-retrieval-embedding-service.git"
    "git clone https://github.com/axwhyzee/multi-modal-retrieval-preprocessor-service.git"
    "git clone https://github.com/axwhyzee/multi-modal-retrieval-frontend.git"
)

for repo in "${repos[@]}"; do
    if [ -d "$repo" ]; then
        echo "$repo already exists, skipping..."
    else
        git clone "https://github.com/axwhyzee/$repo.git" && echo "Cloned $repo
    fi

docker-compose up -d
