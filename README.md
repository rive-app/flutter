# Rive

Welcome to the Rive mono repo! More docs to follow on getting this set up and running on your local environment.

## Test Coop Server runs via docker compose

1. create a .env file, look at the .env.example for inspiration
    - make sure you point PRIVATE_API at something appropriate, probably a locally running 2d server
2. run `docker-compose up --build --force-recreate coop`
    - this starts it (up)
    - builds a new image (build)
    - forces a new container to be created

## Build and deploy coop server to ECR

```sh 
AWS_REGION=us-west-1
AWS_COOP_ECR=654831454668.dkr.ecr.us-west-1.amazonaws.com/coop
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_COOP_ECR
docker build -t coop .
docker tag coop:latest $AWS_COOP_ECR:latest
docker push $AWS_COOP_ECR:latest
```
