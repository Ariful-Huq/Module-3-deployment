name: Deploy to GCP Kubernetes

on:
  push:
    branches:
      - main   # or your deployment branch

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/express-app:latest

  deploy:
    runs-on: ubuntu-latest
    needs: build-and-push

    steps:
      - name: SSH into GCP VM and deploy to Kubernetes
        uses: appleboy/ssh-action@v0.1.10
        with:
          host: ${{ secrets.GCP_VM_HOST }}
          username: ${{ secrets.GCP_VM_USER }}
          key: ${{ secrets.GCP_VM_SSH_KEY }}
          port: 22
          script: |
            cd /home/${{ secrets.GCP_VM_USER }}/Module-3-deployment || exit 1
            git pull origin main

            # Export DockerHub username
            export DOCKERHUB_USERNAME=${{ secrets.DOCKERHUB_USERNAME }}

            # Ensure Kubernetes namespace exists
            kubectl get namespace production >/dev/null 2>&1 || kubectl create namespace production

            # Apply manifests
            kubectl apply -f nginx-config.yaml
            kubectl apply -f deployment.yaml
            kubectl apply -f service.yaml

            # Untaint control-plane node (for single-node clusters)
            kubectl taint nodes --all node-role.kubernetes.io/control-plane- >/dev/null 2>&1

            # Restart deployment to use latest Docker image
            kubectl rollout restart deployment express-nginx-deployment -n production

            # Wait until all pods are ready
            echo "Waiting for pods to be fully ready..."
            kubectl wait --namespace production \
              --for=condition=Ready pods \
              --selector=app=express-nginx \
              --timeout=180s

            # Show final status
            kubectl get pods -n production
            kubectl get svc -n production

            echo "✅ Deployment completed successfully!"