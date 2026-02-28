#!/bin/bash
# scripts/fetch-base-notebook-assets.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}📦 Fetching base-notebook official assets...${NC}"

OFFICIAL_REPO="https://raw.githubusercontent.com/jupyter/docker-stacks/main"
BASE_NOTEBOOK_PATH="images/base-notebook"

FILES=(
    "start-notebook.py"
    "start-notebook.sh"
    "start-singleuser.py"
    "start-singleuser.sh"
    "jupyter_server_config.py"
    "docker_healthcheck.py"
)

# 获取脚本所在目录的上一级（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

# 删除可能存在的空文件
rm -f start-notebook.py start-notebook.sh start-singleuser.py start-singleuser.sh jupyter_server_config.py docker_healthcheck.py

for file in "${FILES[@]}"; do
    echo -e "${YELLOW}Downloading ${file}...${NC}"
    
    # 使用 curl 下载，带重试和详细输出
    if curl -fL --retry 3 --progress-bar "${OFFICIAL_REPO}/${BASE_NOTEBOOK_PATH}/${file}" -o "${file}"; then
        # 检查文件大小
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            filesize=$(stat -f%z "${file}" 2>/dev/null || echo "0")
        else
            # Linux
            filesize=$(stat -c%s "${file}" 2>/dev/null || echo "0")
        fi
        
        if [ "$filesize" -lt 100 ]; then
            echo -e "${RED}  ❌ Downloaded file is too small (${filesize} bytes), may be incomplete${NC}"
            rm -f "${file}"
            exit 1
        fi
        
        # 为shell脚本添加执行权限
        if [[ "${file}" == *.sh ]]; then
            chmod +x "${file}"
        fi
        echo -e "${GREEN}  ✅ ${file} downloaded (${filesize} bytes)${NC}"
    else
        echo -e "${RED}  ❌ Failed to download ${file}${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ All files downloaded successfully to ${PROJECT_ROOT}${NC}"
ls -la *.py *.sh 2>/dev/null || echo -e "${YELLOW}No .py or .sh files found${NC}"