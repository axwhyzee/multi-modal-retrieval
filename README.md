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


This repo orchestrates the system on a single machine with containerized services. To run a distributed version, each service (each git repo) can run on its own box.
<hr/>

## Demo
In the following demo, the object repo consists of:
- Random sampling of 30 videos from the [tiktok-trending-december-2020 dataset](https://www.kaggle.com/datasets/erikvdven/tiktok-trending-december-2020)
- Random sampling of 30 PDFs from [dataset-of-pdf-files](https://www.kaggle.com/datasets/manisha717/dataset-of-pdf-files)
- Random sampling of 60 text files from [wikipedia-small-3000-embedded](https://huggingface.co/datasets/not-lain/wikipedia-small-3000-embedded)
- Random sampling of 150 images from [Flickr30k](https://www.kaggle.com/datasets/hsankesara/flickr-image-dataset)

https://github.com/user-attachments/assets/fe070d59-6a9b-47b2-8d31-b95382432fb1
<hr/>

## Architecture
The hybrid architecture can be divided into the write and read paths, which are event-driven and request-response based respectively.

![FYP System Design v2 (1)](https://github.com/user-attachments/assets/e07a9ed7-b197-4422-941d-64fc88ab9628)
![FYP System Design v2 (3)](https://github.com/user-attachments/assets/b6ebe350-7174-4351-b6d2-cd0c93dfb320)

The write path is designed to be event-driven because processing bottlenecks like chunking and embedding can be called asynchronously; all steps within the write path are idempotent; and eventual consistency is sufficient. The read path however, is required to respond back to the user ASAP, and hence uses a traditional synchronous request-response design.

To support retrieval of documents of various modalalities using text, the `Embedding Service` is designed with dual-modal `text-<MODAL>` embedder and reranker models.

![FYP System Design v2 (5)](https://github.com/user-attachments/assets/7e8f49ba-d170-407d-a2c5-60a03bcbc01e)

For the write path, when there is a request to index an object, the `Embedder Factory` creates the corresponding embedder to embed the object, then insert the embedding into the corresponding namespace in Pinecone.

![FYP System Design v2 (6)](https://github.com/user-attachments/assets/f5805b56-acf1-44b8-afff-d3b90ca67056)

For the read path, when there is a request to query using a text, the `Embedding Service` iterates through all supported modals, and for each modal, the `Embedder Factory` creates the corresponding embedder to embed the text, then fetch the `top_k` most relevant objects from the namespace associated with the user and modal. Next, the `Reranker factory` creates the reranker corresponding to the modal and reranks the candidates, yielding only the `top_n` ranked objects.

*Note: `top_k` = `top_n` * MULTIPLIER, where MULTIPLIER is an int > 1*
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
