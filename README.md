# Multi-Modal Retrieval System
This repo orchestrates the system on a single machine with containerized services. To run a distributed version, each service (each git repo) can run on its own box.

## Architecture
![FYP System Design v2 (1)](https://github.com/user-attachments/assets/e07a9ed7-b197-4422-941d-64fc88ab9628)
![FYP System Design v2 (2)](https://github.com/user-attachments/assets/4222c918-e64c-4c05-a03e-06897a834f1c)

The system is a hybrid of event-driven and request-response architecture. The write path is designed to be event-driven because processing bottlenecks like chunking and embedding can be called asynchronously, all steps within the write path are idempotent, and eventual consistency is sufficient. The read path however, is required to respond back to the user ASAP, and hence uses a traditional synchronous request-response design.


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
3. Run `source run.sh` to clone the services + build and/or start the docker containers
4. Insert dummy data by running `python insert.py`
5. Go to `http://localhost:3000` and make queries
