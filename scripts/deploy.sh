#!/bin/bash
# scripts/deploy.sh

# 启动JupyterHub
echo "Starting JupyterHub..."
docker-compose up -d

echo "JupyterHub is running at http://localhost:8000"
echo "Admin user: admin"
echo "Check logs with: docker-compose logs -f"