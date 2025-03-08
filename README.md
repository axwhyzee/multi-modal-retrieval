# Multi-Modal Retrieval System
This repo orchestrates the system on a single machine with containerized services. To run a distributed version, each service (each git repo) can run on its own box.

## Architecture
![FYP System Design v2 (1)](https://github.com/user-attachments/assets/e07a9ed7-b197-4422-941d-64fc88ab9628)
![FYP System Design v2 (2)](https://github.com/user-attachments/assets/4222c918-e64c-4c05-a03e-06897a834f1c)

The system is a hybrid of event-driven and request-response architecture. The write path is designed to be event-driven because processing bottlenecks like chunking and embedding can be called asynchronously; all steps within the write path are idempotent; and eventual consistency is sufficient. The read path however, is required to respond back to the user ASAP, and hence uses a traditional synchronous request-response design.

To support retrieval of documents of various modalalities using text, the `Embedding Service` is designed with dual-modal `text-<MODAL>` embedder and reranker models.

![FYP System Design v2 (5)](https://github.com/user-attachments/assets/7e8f49ba-d170-407d-a2c5-60a03bcbc01e)

For the write path, when there is a request to index an object, the `Embedder Factory` creates the corresponding embedder to embed the object, then insert the embedding into the corresponding namespace in Pinecone.

![FYP System Design v2 (6)](https://github.com/user-attachments/assets/f5805b56-acf1-44b8-afff-d3b90ca67056)

For the read path, when there is a request to query using a text, the `Embedding Service` iterates through all supported modals, and for each modal, the `Embedder Factory` creates the corresponding embedder to embed the text, then fetch the `top_k` most relevant objects from the namespace associated with the user and modal. Next, the `Reranker factory` creates the reranker corresponding to the modal and reranks the candidates, yielding only the `top_n` ranked objects.

*Note: `top_k` = `top_n` * MULTIPLIER, where MULTIPLIER is an int > 1*


## Setup
1. Create a `.env` file with the following env vars:
```
AWS_S3_BUCKET_ACCESS_KEY=...
AWS_S3_BUCKET_NAME=...
AWS_S3_BUCKET_REGION=...
AWS_S3_BUCKET_SECRET_ACCESS_KEY=...
EMBEDDING_SERVICE_API_URL=http://embedding_service_api-1:5000/  # use generated name of docker container
ENV=DEV                                                         # use local file system instead of S3 for object storage
PINECONE_API_KEY=...
REACT_APP_API_URL=http://localhost:5001                         # URL to Gateway Service, has port forwarding 5001:5000 by default (configure in `docker-compose.yml`)
REACT_APP_USER=...
REDIS_HOST=...
REDIS_PASSWORD=...
REDIS_PORT=...
REDIS_USERNAME=...
STORAGE_SERVICE_API_URL=http://storage_service_api-1:5000/      # use generated name of docker container
```

2. Install Docker
3. Increase Docker memory limit to at least 12GB
4. Run `source run.sh` to clone the services + build and/or start the docker containers
5. Insert dummy data by running `python insert.py`
6. Go to `http://localhost:3000` to access the web-based GUI

## Workers
To scale up a particular service like `embedding_service_event_consumer`, change the docker command in `run.sh` as shown
```
docker-compose up -d --scale embedding_service_event_consumer=3
```
