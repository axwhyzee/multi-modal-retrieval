# Multi-Modal Retrieval System
This project is a demonstration of a Multi-Modal Retrieval System, where documents of various modalities like image, text, video, image+text, can be retrieved using text in natural language. It can be used in corporate intranet document lookup, cloud storage search, or even enhancing Google search by going beyond simple text matching.

| **Component** | **Description** | **GitHub Repo** |
| --------- | ----------- | ----------- |
| Event Core | Common code for:<ul><li>Domain models</li><li>Event schemas</li><li>API clients for:</li><ul><li>Storage Service</li><li>Embedding Service</li><li>Mapping Service</li></ul></li></ul> | https://github.com/axwhyzee/multi-modal-retrieval-event-core |
| Gateway Service | <ul><li>API gateway</li><li>Coordinate calls to various services to aggregate a response</li></ul> | https://github.com/axwhyzee/multi-modal-retrieval-gateway-service
| Storage Service | Remote object repository using AWS S3 buckets | https://github.com/axwhyzee/multi-modal-retrieval-storage-service
| Embedding Service | <ul><li>On ChunkStored events, index the chunk using Pinecone</li><li>Given a query, fetch most relevant objects in 2-stage retrieval</li> | https://github.com/axwhyzee/multi-modal-retrieval-embedding-service
| Preprocessor Service | On DocStored events, chunk document, carry out text and image preprocessing on chunks, and generate thumbnails | https://github.com/axwhyzee/multi-modal-retrieval-preprocessor-service
| Meta Service | Holds mapping of objects to their meta data | N/A (using Redis server)
| Frontend | GUI | https://github.com/axwhyzee/multi-modal-retrieval-frontend


This repo orchestrates the system on a single machine with containerized services. To run a distributed version, each service (each git repo) can run on its own box.
<hr/>

# 1. Demo

## 1.1 Sony WH-1000XM4 Help Guide
Use case: Customer support<br/>
Dataset:
- PDFs scraped from [Sony WH-1000XM4 Help Guide](https://helpguide.sony.net/mdr/wh1000xm4/v1/en/index.html)
- Videos from [Sony Europe Youtube Channel](https://www.youtube.com/@SonyEuro)

https://github.com/user-attachments/assets/d47c62df-6495-4882-8019-eff8320f2cfd

<br/>

## 1.2 Pinecone Python Client Codebase
Use case: Internal technical documentation search<br/>
Dataset:
- [Pinecone GitHub Code Base](https://github.com/pinecone-io/pinecone-python-client)

https://github.com/user-attachments/assets/d1782548-c8f8-4c92-8ab5-a7cba4692d87

<hr/>

# 2. System
## 2.1 System Overview

![FYP System Design v2 (14)](https://github.com/user-attachments/assets/ae77d94a-ffa7-4671-9a88-1da1154d8365)

## 2.2 Detailed Architecture
The hybrid architecture can be divided into the write and read paths, which are event-driven and request-response based respectively.
<br/><br/>

### 2.2.1 Write Path

![FYP System Design v2 (11)](https://github.com/user-attachments/assets/54752d42-7838-4444-a6c7-6790932351ec)

The write path is designed to be event-driven because processing bottlenecks like chunking and embedding can be called asynchronously; all steps within the write path are idempotent; and eventual consistency is sufficient.
<br/><br/>

#### 2.2.1.1 Write Path: Document Upload
When a document is uploaded to the Gateway Service (API gateway), the Gateway Service stores the document into the Storage Service, which emits a DocStored event.
<br/><br/>

#### 2.2.1.2 Write Path: Pre-processing

![FYP System Design v2 (8)](https://github.com/user-attachments/assets/aee8bb7c-8251-41ff-891d-9e80d1c660da)

DocStored events are received by the Preprocessor Service, which extracts elements like images, texts, plots and code blocks are from the document. Assets like document thumbnails and element thumbnails are also generated. All these objects are stored in the Storage Service, and meta data is inserted into the Meta Service where applicable. When element objects are inserted into the Storage Service, ElementStored events are emitted.
<br/><br/>

#### 2.2.1.3 Write Path: Indexing

![FYP System Design v2 (10)](https://github.com/user-attachments/assets/f518a7d1-06cb-4f26-aaba-23ab390e7117)

ElementStored events are received by the Embedding Service, which embeds the elements using the corresponding embedding models. The embeddings are indexed in the corresponding {ELEMENT_TYPE}/{USER} namespace in vector database Pinecone which allows multi-tenancy.
<br/><br/>

### 2.2.2 Read Path

![FYP System Design v2 (13)](https://github.com/user-attachments/assets/a6e17bb3-617f-4f82-bda0-db8837c10283)

The read path is synchronous because it must respond back to the user ASAP. Hence, it follows a simple and traditional request-response design.
<br/><br/>

#### 2.2.2.1 Read Path: Query

User sends a text query to the Gateway Service, which forwards the request to the Embedding Service. 
<br/><br/>

#### 2.2.2.2 Read Path: Retrieval

![FYP System Design v2 (12)](https://github.com/user-attachments/assets/1010cefa-89b7-47c3-9668-0b9ad01cc584)

For each element type, Embedding Service embeds the text query using the corresponding embedding model. The text embedding is used to query in the namespace corresponding to the element type and user, fetching top-k elements most similar to the text query. The top-k elements are reranked by the element-specific rerankers, and only the top-n ranked elements are returned as response.

*Note: `top_k` = `top_n` * MULTIPLIER, where MULTIPLIER is an int > 1*
<br/><br/>

#### 2.2.2.3 Read Path: Transform & Aggregate

On receiving the results from the Embedding Service, the Gateway Service transforms the response and fetches corresponding asset and element meta data from the Meta Service.
<br/><br/>

<hr/>

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
<hr/>

## Expansion
In this project, a single `openai/clip-vit-base-patch32` model suffices to index image, text, video and image + text documents. However, this system is designed such that it is not required to have documents of all modalities live in the same embedding space. This means that new modalities can be introduced, as long as there exists a dual-modal `text-<NEW MODAL> ` model. For instance, the audio modality can be introduced as long as there exists a suitable `text-audio` embedding model and reranker.
