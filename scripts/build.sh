#!/bin/bash
# scripts/build.sh

set -e

# 颜色定义
RED='\033[0;31m'      # 红色
GREEN='\033[0;32m'    # 绿色
YELLOW='\033[1;33m'   # 黄色
BLUE='\033[0;34m'     # 蓝色
CYAN='\033[0;36m'     # 青色
NC='\033[0m'          # 无色

# 获取脚本所在目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 默认值配置
PYTHON_VERSION="3.10.12"     # Python 版本（支持完整版本号）
UBUNTU_VERSION="22.04"       # Ubuntu 版本
CLEAN_BUILD=false            # 是否清理构建
IMAGE_NAME="zhongsheng/base-notebook"  # 镜像名称
NO_CACHE=false               # 是否不使用缓存
PUSH_IMAGE=false             # 是否推送镜像
VERBOSE=false                # 是否显示详细输出
SKIP_TESTS=false             # 是否跳过测试
BUILD_PLATFORM="linux/amd64" # 构建平台
TAG_SUFFIX=""                # 标签后缀
FORCE_PYTHON_MAJOR=""        # 强制使用的主版本号（用于基础镜像选择）

# 显示帮助信息
show_help() {
    echo -e "${CYAN}Jupyter base-notebook Builder${NC}"
    echo
    echo "Usage: ./build.sh [OPTIONS]"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "  -p, --python VERSION    Python version with full version number (default: 3.10.12)"
    echo "                          Examples: 2.7.18, 3.6.15, 3.8.20, 3.9.21, 3.10.12, 3.11.9, 3.12.8"
    echo "  -u, --ubuntu VERSION    Ubuntu version (default: 22.04)"
    echo "  -i, --image NAME        Image name (default: zhongsheng/base-notebook)"
    echo "  -t, --tag SUFFIX        Additional tag suffix"
    echo "  -c, --clean             Clean build (remove old images)"
    echo "  -n, --no-cache          Build without cache"
    echo "      --push              Push image to registry"
    echo "      --platform PLATFORM Build platform (default: linux/amd64)"
    echo "      --skip-tests        Skip post-build tests"
    echo "      --force-major MAJOR Force base image to use specific major Python version"
    echo "                          (e.g., --force-major 3.10 uses ubuntu-22.04 base with Python 3.10)"
    echo "  -v, --verbose           Verbose output"
    echo "  -h, --help              Show this help message"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./build.sh                                         # Default build with Python 3.10.12"
    echo "  ./build.sh -p 3.11.9 -u 24.04                      # Python 3.11.9 + Ubuntu 24.04"
    echo "  ./build.sh --python 2.7.18 --ubuntu 18.04          # Python 2.7.18 + Ubuntu 18.04"
    echo "  ./build.sh -p 3.12.8 --clean --push                 # Clean build and push"
    echo "  ./build.sh -p 3.10.12 --platform linux/arm64       # Build for ARM64"
    echo "  ./build.sh -p 3.11.9 --force-major 3.11            # Force use Python 3.11 base"
    echo
    echo -e "${YELLOW}Supported Python versions:${NC}"
    echo "  Python 2.x: 2.7.18"
    echo "  Python 3.x: 3.6.15, 3.7.17, 3.8.20, 3.9.21, 3.10.12, 3.11.9, 3.12.8, 3.13.1"
    echo "  (More versions available upon request)"
    echo
    echo -e "${YELLOW}Supported Ubuntu versions:${NC}"
    echo "  18.04, 20.04, 22.04, 24.04"
}

# 解析 Python 版本号
parse_python_version() {
    local version="$1"
    
    # 使用正则表达式匹配 Python 版本号
    if [[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        PYTHON_MAJOR="${BASH_REMATCH[1]}"
        PYTHON_MINOR="${BASH_REMATCH[2]}"
        PYTHON_PATCH="${BASH_REMATCH[3]}"
        PYTHON_MAJOR_MINOR="${PYTHON_MAJOR}.${PYTHON_MINOR}"
        return 0
    elif [[ $version =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        # 如果没有 patch 版本，使用 .0 作为默认
        PYTHON_MAJOR="${BASH_REMATCH[1]}"
        PYTHON_MINOR="${BASH_REMATCH[2]}"
        PYTHON_PATCH="0"
        PYTHON_MAJOR_MINOR="${PYTHON_MAJOR}.${PYTHON_MINOR}"
        echo -e "${YELLOW}⚠️  No patch version specified, using ${PYTHON_MAJOR_MINOR}.${PYTHON_PATCH}${NC}"
        return 0
    else
        echo -e "${RED}❌ Invalid Python version format: ${version}${NC}"
        echo -e "${YELLOW}Expected format: X.Y.Z (e.g., 3.10.12)${NC}"
        return 1
    fi
}

# 验证版本支持
validate_versions() {
    local valid_python=false
    local valid_ubuntu=false
    
    # 解析 Python 版本
    if ! parse_python_version "$PYTHON_VERSION"; then
        exit 1
    fi
    
    # 支持的 Python 版本列表（完整版本号）
    local supported_python_versions=(
        "2.7.18"
        "3.6.15" "3.7.17" "3.8.20" "3.9.21"
        "3.10.0" "3.10.1" "3.10.2" "3.10.3" "3.10.4" "3.10.5" "3.10.6" "3.10.7" "3.10.8" "3.10.9" "3.10.10" "3.10.11" "3.10.12" "3.10.13" "3.10.14" "3.10.15" "3.10.16"
        "3.11.0" "3.11.1" "3.11.2" "3.11.3" "3.11.4" "3.11.5" "3.11.6" "3.11.7" "3.11.8" "3.11.9" "3.11.10" "3.11.11"
        "3.12.0" "3.12.1" "3.12.2" "3.12.3" "3.12.4" "3.12.5" "3.12.6" "3.12.7" "3.12.8"
        "3.13.0" "3.13.1"
    )
    
    # 检查 Python 版本是否支持
    for v in "${supported_python_versions[@]}"; do
        if [[ "$PYTHON_VERSION" == "$v" ]]; then
            valid_python=true
            break
        fi
    done
    
    # 支持的 Ubuntu 版本
    local supported_ubuntu_versions=("18.04" "20.04" "22.04" "24.04")
    for v in "${supported_ubuntu_versions[@]}"; do
        if [[ "$UBUNTU_VERSION" == "$v" ]]; then
            valid_ubuntu=true
            break
        fi
    done
    
    if [[ "$valid_python" == false ]]; then
        echo -e "${RED}❌ Unsupported Python version: ${PYTHON_VERSION}${NC}"
        echo -e "${YELLOW}Common supported versions: 2.7.18, 3.6.15, 3.7.17, 3.8.20, 3.9.21, 3.10.12, 3.11.9, 3.12.8, 3.13.1${NC}"
        echo -e "${YELLOW}For other versions, please check official Python support${NC}"
        exit 1
    fi
    
    if [[ "$valid_ubuntu" == false ]]; then
        echo -e "${RED}❌ Unsupported Ubuntu version: ${UBUNTU_VERSION}${NC}"
        echo -e "${YELLOW}Supported versions: 18.04, 20.04, 22.04, 24.04${NC}"
        exit 1
    fi
    
    # 版本兼容性检查
    if [[ "$PYTHON_MAJOR" == "2" ]] && [[ "$UBUNTU_VERSION" > "20.04" ]]; then
        echo -e "${YELLOW}⚠️  Warning: Python 2.7 is not officially supported on Ubuntu ${UBUNTU_VERSION}${NC}"
        echo -e "${YELLOW}   You may encounter compatibility issues${NC}"
    fi
    
    if [[ "$PYTHON_MAJOR_MINOR" == "3.13" ]] && [[ "$UBUNTU_VERSION" < "22.04" ]]; then
        echo -e "${YELLOW}⚠️  Warning: Python 3.13 requires newer system libraries${NC}"
        echo -e "${YELLOW}   Ubuntu ${UBUNTU_VERSION} may not be fully compatible${NC}"
    fi
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--python)
                PYTHON_VERSION="$2"
                shift 2
                ;;
            -u|--ubuntu)
                UBUNTU_VERSION="$2"
                shift 2
                ;;
            -i|--image)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -t|--tag)
                TAG_SUFFIX="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -n|--no-cache)
                NO_CACHE=true
                shift
                ;;
            --push)
                PUSH_IMAGE=true
                shift
                ;;
            --platform)
                BUILD_PLATFORM="$2"
                shift 2
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --force-major)
                FORCE_PYTHON_MAJOR="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查必要文件
check_files() {
    cd "${PROJECT_ROOT}"
    
    if [ ! -f "docker-bake.hcl" ]; then
        echo -e "${RED}❌ Error: docker-bake.hcl not found in $(pwd)${NC}"
        exit 1
    fi
    
    if [ ! -f "Dockerfile" ]; then
        echo -e "${RED}❌ Error: Dockerfile not found in $(pwd)${NC}"
        exit 1
    fi
    
    if [ ! -f "requirements.txt" ]; then
        echo -e "${YELLOW}⚠️  Warning: requirements.txt not found, creating empty file${NC}"
        touch requirements.txt
    fi
    
    # 检查官方脚本文件是否存在
    local missing_files=0
    for file in start-notebook.py start-notebook.sh start-singleuser.py start-singleuser.sh jupyter_server_config.py docker_healthcheck.py; do
        if [ ! -f "${PROJECT_ROOT}/${file}" ]; then
            echo -e "${YELLOW}⚠️  Missing ${file}${NC}"
            missing_files=1
        fi
    done
    
    if [[ ${missing_files} -eq 1 ]]; then
        echo -e "${YELLOW}📥 Running fetch-base-notebook-assets.sh...${NC}"
        "${SCRIPT_DIR}/fetch-base-notebook-assets.sh"
    fi
}

# 清理旧的镜像
clean_old_images() {
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        echo -e "${YELLOW}🧹 Cleaning up old images...${NC}"
        
        # 构建镜像标签模式（使用完整 Python 版本）
        local python_tag_part="python-${PYTHON_VERSION}"
        local tag_pattern="${IMAGE_NAME}:${python_tag_part}-ubuntu${UBUNTU_VERSION}"
        if [[ -n "$TAG_SUFFIX" ]]; then
            tag_pattern="${tag_pattern}-${TAG_SUFFIX}"
        fi
        
        # 查找并删除相关镜像
        local old_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${IMAGE_NAME}:" | grep "python-${PYTHON_VERSION}-ubuntu${UBUNTU_VERSION}" || true)
        
        if [[ ! -z "$old_images" ]]; then
            echo "Removing old images:"
            echo "$old_images"
            docker rmi $old_images 2>/dev/null || true
        fi
        
        # 清理构建缓存
        docker builder prune -f --filter "until=24h" 2>/dev/null || true
        
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    fi
}

# 构建镜像标签（使用完整 Python 版本）
build_tags() {
    local tags=()
    local python_tag_part="python-${PYTHON_VERSION}"
    local base_tag="${python_tag_part}-ubuntu${UBUNTU_VERSION}"
    
    # 添加基础标签
    if [[ -n "$TAG_SUFFIX" ]]; then
        tags+=("${IMAGE_NAME}:${base_tag}-${TAG_SUFFIX}")
    else
        tags+=("${IMAGE_NAME}:${base_tag}")
    fi
    
    # 添加主版本标签（如 python-3.10-ubuntu22.04）
    local major_tag="python-${PYTHON_MAJOR_MINOR}-ubuntu${UBUNTU_VERSION}"
    if [[ -n "$TAG_SUFFIX" ]]; then
        tags+=("${IMAGE_NAME}:${major_tag}-${TAG_SUFFIX}")
    else
        tags+=("${IMAGE_NAME}:${major_tag}")
    fi
    
    # 如果是最新稳定版本，添加 latest 标签
    if [[ "$PYTHON_VERSION" == "3.10.12" && "$UBUNTU_VERSION" == "22.04" && -z "$TAG_SUFFIX" ]]; then
        tags+=("${IMAGE_NAME}:latest")
    fi
    
    printf '%s\n' "${tags[@]}"
}

# 显示构建信息
show_build_info() {
    echo -e "${GREEN}🔨 Build configuration:${NC}"
    echo -e "   ${BLUE}Python version:${NC} ${YELLOW}${PYTHON_VERSION} (${PYTHON_MAJOR}.${PYTHON_MINOR}.${PYTHON_PATCH})${NC}"
    echo -e "   ${BLUE}Ubuntu version:${NC} ${YELLOW}${UBUNTU_VERSION}${NC}"
    echo -e "   ${BLUE}Image name:${NC} ${YELLOW}${IMAGE_NAME}${NC}"
    echo -e "   ${BLUE}Platform:${NC} ${YELLOW}${BUILD_PLATFORM}${NC}"
    
    if [[ -n "$FORCE_PYTHON_MAJOR" ]]; then
        echo -e "   ${BLUE}Forced base major:${NC} ${YELLOW}${FORCE_PYTHON_MAJOR}${NC}"
    fi
    
    local tags=($(build_tags))
    echo -e "   ${BLUE}Tags:${NC}"
    for tag in "${tags[@]}"; do
        echo -e "     ${YELLOW}${tag}${NC}"
    done
    
    if [[ "$NO_CACHE" == "true" ]]; then
        echo -e "   ${BLUE}Cache:${NC} ${YELLOW}Disabled${NC}"
    fi
    
    if [[ "$PUSH_IMAGE" == "true" ]]; then
        echo -e "   ${BLUE}Push:${NC} ${YELLOW}Enabled${NC}"
    fi
    
    echo ""
}

# 执行构建
run_build() {
    echo -e "${GREEN}🚀 Starting build...${NC}"
    
    # 准备构建参数
    local bake_args=""
    if [[ "$NO_CACHE" == "true" ]]; then
        bake_args="${bake_args} --no-cache"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        bake_args="${bake_args} --progress plain"
    else
        bake_args="${bake_args} --progress auto"
    fi

    # 确定基础镜像的 Python 主版本
    local base_python_major="${PYTHON_MAJOR_MINOR}"
    if [[ -n "$FORCE_PYTHON_MAJOR" ]]; then
        base_python_major="$FORCE_PYTHON_MAJOR"
    fi
    
    # 对于 Ubuntu 18.04 或 Python 2.7，需要特殊处理
    if [[ "$UBUNTU_VERSION" == "18.04" ]] || [[ "$PYTHON_MAJOR_MINOR" == "2.7" ]]; then
        echo -e "${YELLOW}⚠️  Python ${PYTHON_MAJOR_MINOR} on Ubuntu ${UBUNTU_VERSION} detected, using compatibility mode${NC}"
        
        # 步骤1: 构建 foundation 镜像（使用修改过的 Dockerfile）
        echo -e "${BLUE}Building foundation image for Python ${PYTHON_MAJOR_MINOR} on Ubuntu ${UBUNTU_VERSION}...${NC}"
        
        # 创建一个临时目录
        local tmp_build_dir="/tmp/jupyter-builder-$$"
        mkdir -p "${tmp_build_dir}"
        
        # 克隆 foundation 的 Dockerfile 并修改
        cd "${tmp_build_dir}"
        
        # 下载 foundation 的所有文件
        git clone --depth 1 https://github.com/jupyter/docker-stacks.git
        cd docker-stacks/images/docker-stacks-foundation
        
        # 修改 Dockerfile 以支持不同 Ubuntu 版本和 Python 2.7
        cp Dockerfile Dockerfile.original
        
        # 创建修改后的 Dockerfile
        cat > Dockerfile.modified << 'EOF'
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

ARG ROOT_IMAGE=ubuntu:24.04
FROM $ROOT_IMAGE

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    bzip2 \
    ca-certificates \
    locales \
    netbase \
    sudo \
    wget && \
    # 对于 Ubuntu 18.04，手动安装 tini；其他版本直接安装
    if grep -q "18.04" /etc/os-release; then \
        wget -q https://github.com/krallin/tini/releases/download/v0.19.0/tini -O /usr/local/bin/tini && \
        chmod +x /usr/local/bin/tini; \
    else \
        apt-get install --yes --no-install-recommends tini; \
    fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "C.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    echo 'eval "$(conda shell.bash hook)"' >> /etc/skel/.bashrc

RUN if grep -q "${NB_UID}" /etc/passwd; then \
        userdel --remove $(id -un "${NB_UID}"); \
    fi

RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --no-user-group "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

RUN rm -rf "/home/${NB_USER}/.cache/"

USER ${NB_UID}

ARG PYTHON_VERSION=3.13

RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}"

COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp
RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="64"; \
    fi && \
    wget --progress=dot:giga -O - \
        "https://micro.mamba.pm/api/micromamba/linux-${arch}/latest" | tar -xvj bin/micromamba && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    ./bin/micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        'jupyter_core' \
        'conda' \
        'mamba' \
        "${PYTHON_SPECIFIER}" && \
    rm -rf /tmp/bin/ && \
    # 对于 Python 2.7，完全跳过所有 mamba 命令
    if [[ "${PYTHON_VERSION}" == "2.7" ]]; then \
        echo "python ${PYTHON_VERSION}.*" >> "${CONDA_DIR}/conda-meta/pinned"; \
        echo "Skipping mamba commands for Python 2.7 due to compatibility issues"; \
        # 手动清理 pkgs 目录
        rm -rf "${CONDA_DIR}/pkgs/*" 2>/dev/null || true; \
    else \
        mamba list --full-name 'python' | awk 'END{sub("[^.]*$", "*", $2); print $1 " " $2}' >> "${CONDA_DIR}/conda-meta/pinned" && \
        mamba clean --all -f -y; \
    fi && \
    # 确保权限正确
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}" && \
    # 验证安装
    echo "Installation completed for Python ${PYTHON_VERSION}"

COPY run-hooks.sh start.sh /usr/local/bin/

ENTRYPOINT ["tini", "-g", "--", "start.sh"]

USER root

RUN mkdir /usr/local/bin/start-notebook.d && \
    mkdir /usr/local/bin/before-notebook.d

COPY 10activate-conda-env.sh /usr/local/bin/before-notebook.d/

RUN rm -rf "/home/${NB_USER}/.cache/"

USER ${NB_UID}

WORKDIR "${HOME}"
EOF
        
        # 构建 foundation 镜像
        echo -e "${BLUE}Building foundation image with: custom-foundation:ubuntu${UBUNTU_VERSION}-py${base_python_major}${NC}"
        docker build \
            -f Dockerfile.modified \
            -t "custom-foundation:ubuntu${UBUNTU_VERSION}-py${base_python_major}" \
            --build-arg ROOT_IMAGE="ubuntu:${UBUNTU_VERSION}" \
            --build-arg PYTHON_VERSION="${base_python_major}" \
            .
        
        # 检查 foundation 构建是否成功
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Foundation build failed!${NC}"
            return 1
        fi
        
        # 步骤2: 构建 base-notebook 镜像
        echo -e "${BLUE}Building base-notebook image for Python ${PYTHON_MAJOR_MINOR} on Ubuntu ${UBUNTU_VERSION}...${NC}"
        cd "${tmp_build_dir}/docker-stacks/images/base-notebook"
        
        # 检查是否为 Python 2.7
        if [[ "${base_python_major}" == "2.7" ]]; then
            echo -e "${YELLOW}⚠️  Python 2.7 detected, using modified base-notebook Dockerfile with pip instead of mamba${NC}"
            
            # 创建修改后的 base-notebook Dockerfile，使用动态的 Ubuntu 版本
            cp Dockerfile Dockerfile.original
            
            # 使用 'EOF' 防止变量展开，创建模板文件
            cat > Dockerfile.template << 'EOF'
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_IMAGE=custom-foundation:TEMPLATE_UBUNTU_VERSION-pyTEMPLATE_PYTHON_VERSION
FROM ${BASE_IMAGE}

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for the Server that starts
# but lacks all features (e.g., download as all possible file formats)
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-liberation \
    pandoc \
    run-one && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# macOS Rosetta virtualization creates junk directory which gets owned by root further up.
RUN rm -rf "/home/${NB_USER}/.cache/"

USER ${NB_UID}

# 对于 Python 2.7，使用 pip 而不是 mamba 安装 Jupyter 组件
# 使用兼容 Python 2.7 的 Jupyter 版本
WORKDIR /tmp
RUN pip install --no-cache-dir \
    'jupyterhub-singleuser==1.5.0' \
    'jupyterlab==2.2.10' \
    'nbclassic==0.3.5' \
    'notebook==5.7.10' && \
    jupyter server --generate-config && \
    pip cache purge || true && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

ENV JUPYTER_PORT=8888
EXPOSE ${JUPYTER_PORT}

# Configure container startup
CMD ["start-notebook.py"]

# Copy local files as late as possible to avoid cache busting
COPY start-notebook.py start-notebook.sh start-singleuser.py start-singleuser.sh /usr/local/bin/
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root
RUN fix-permissions /etc/jupyter/

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
HEALTHCHECK --interval=3s --timeout=1s --start-period=3s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1

# macOS Rosetta virtualization creates junk directory which gets owned by root further up.
RUN rm -rf "/home/${NB_USER}/.cache/"

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

WORKDIR "${HOME}"
EOF

            # 替换模板中的变量
            sed -e "s/TEMPLATE_UBUNTU_VERSION/${UBUNTU_VERSION}/g" \
                -e "s/TEMPLATE_PYTHON_VERSION/${base_python_major}/g" \
                Dockerfile.template > Dockerfile.modified

            # 使用修改后的 Dockerfile 构建 base-notebook
            docker build \
                -f Dockerfile.modified \
                -t "custom-base-notebook:ubuntu${UBUNTU_VERSION}-py${base_python_major}" \
                --build-arg BASE_IMAGE="custom-foundation:ubuntu${UBUNTU_VERSION}-py${base_python_major}" \
                .
        else
            # 对于 Python 3.x，使用原始的 Dockerfile
            echo -e "${GREEN}Using standard mamba installation for Python ${base_python_major}${NC}"
            docker build \
                -t "custom-base-notebook:ubuntu${UBUNTU_VERSION}-py${base_python_major}" \
                --build-arg BASE_IMAGE="custom-foundation:ubuntu${UBUNTU_VERSION}-py${base_python_major}" \
                .
        fi
        
        # 检查 base-notebook 构建是否成功
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Base-notebook build failed!${NC}"
            return 1
        fi
        
        # 步骤3: 构建最终的自定义镜像
        echo -e "${BLUE}Building custom image...${NC}"
        cd "${PROJECT_ROOT}"
        
        local tags=($(build_tags))
        local tag_args=""
        for tag in "${tags[@]}"; do
            tag_args="${tag_args} -t ${tag}"
            echo -e "${BLUE}  Tag: ${tag}${NC}"
        done
        
        docker build \
            ${tag_args} \
            --build-arg BASE_IMAGE="custom-base-notebook:ubuntu${UBUNTU_VERSION}-py${base_python_major}" \
            --build-arg PYTHON_VERSION="${PYTHON_VERSION}" \
            --build-arg PYTHON_MAJOR="${PYTHON_MAJOR}" \
            --build-arg PYTHON_MINOR="${PYTHON_MINOR}" \
            --build-arg PYTHON_PATCH="${PYTHON_PATCH}" \
            --build-arg PYTHON_MAJOR_MINOR="${PYTHON_MAJOR_MINOR}" \
            --build-arg BASE_PYTHON_MAJOR="${base_python_major}" \
            --build-arg UBUNTU_VERSION="${UBUNTU_VERSION}" \
            -f Dockerfile \
            .
        
        local build_status=$?
        
        # 清理临时目录
        rm -rf "${tmp_build_dir}"
        
        if [ $build_status -eq 0 ]; then
            echo -e "${GREEN}✅ Custom image built successfully!${NC}"
            # 显示构建的镜像
            docker images | grep "${IMAGE_NAME}" | grep "${UBUNTU_VERSION}"
        else
            echo -e "${RED}❌ Custom image build failed!${NC}"
        fi
        
        return $build_status
    else
        # 对于 Ubuntu 20.04+ 且 Python 3.x，使用正常的 bake 流程
        echo -e "${GREEN}Using standard bake process for Python ${PYTHON_MAJOR_MINOR} on Ubuntu ${UBUNTU_VERSION}${NC}"
        PYTHON_VERSION="${PYTHON_VERSION}" \
        PYTHON_MAJOR="${PYTHON_MAJOR}" \
        PYTHON_MINOR="${PYTHON_MINOR}" \
        PYTHON_PATCH="${PYTHON_PATCH}" \
        PYTHON_MAJOR_MINOR="${PYTHON_MAJOR_MINOR}" \
        BASE_PYTHON_MAJOR="${base_python_major}" \
        UBUNTU_VERSION="${UBUNTU_VERSION}" \
        IMAGE_NAME="${IMAGE_NAME}" \
        BUILD_PLATFORM="${BUILD_PLATFORM}" \
        TAG_SUFFIX="${TAG_SUFFIX}" \
        docker buildx bake ${bake_args}
        
        return $?
    fi
}

# 测试镜像
test_image() {
    if [[ "$SKIP_TESTS" == "true" ]]; then
        echo -e "${YELLOW}⚠️  Tests skipped${NC}"
        return 0
    fi
    
    echo -e "${GREEN}🔍 Testing image...${NC}"
    
    local tags=($(build_tags))
    local test_image="${tags[0]}"
    
    # 测试 Python 版本
    local python_check=$(docker run --rm "${test_image}" python --version 2>&1)
    echo -e "   ${BLUE}Python:${NC} ${python_check}"
    
    # 验证完整版本号
    if [[ "$python_check" == *"$PYTHON_VERSION"* ]]; then
        echo -e "   ${GREEN}✓ Python version matches expected ${PYTHON_VERSION}${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Python version may differ: expected ${PYTHON_VERSION}${NC}"
    fi
    
    # 测试 Ubuntu 版本
    local ubuntu_check=$(docker run --rm "${test_image}" lsb_release -d 2>/dev/null | cut -f2)
    if [[ -z "$ubuntu_check" ]]; then
        ubuntu_check=$(docker run --rm "${test_image}" cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d'"' -f2)
    fi
    if [[ -z "$ubuntu_check" ]]; then
        ubuntu_check="Ubuntu ${UBUNTU_VERSION}"
    fi
    echo -e "   ${BLUE}Ubuntu:${NC} ${ubuntu_check}"
    
    # 测试 Jupyter
    local jupyter_check=$(docker run --rm "${test_image}" jupyter --version 2>/dev/null | head -n1)
    echo -e "   ${BLUE}Jupyter:${NC} ${jupyter_check:-Available}"
    
    # 测试 requirements 安装
    if [ -s requirements.txt ]; then
        # 随机选择一个包来测试是否安装成功
        local test_pkg=$(head -n1 requirements.txt | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | xargs)
        if [[ -n "$test_pkg" ]]; then
            local pkg_check=$(docker run --rm "${test_image}" pip show "$test_pkg" 2>/dev/null | grep "Version" || true)
            if [[ -n "$pkg_check" ]]; then
                echo -e "   ${BLUE}Requirements:${NC} ${test_pkg} installed (${pkg_check})"
            else
                echo -e "   ${YELLOW}⚠️  Requirements:${NC} Could not verify ${test_pkg}"
            fi
        fi
    fi
    
    echo -e "${GREEN}✅ Tests completed${NC}"
}

# 推送镜像
push_image() {
    if [[ "$PUSH_IMAGE" == "true" ]]; then
        echo -e "${GREEN}📤 Pushing images...${NC}"
        
        local tags=($(build_tags))
        for tag in "${tags[@]}"; do
            echo -e "   Pushing ${YELLOW}${tag}${NC}"
            docker push "${tag}"
        done
        
        echo -e "${GREEN}✅ Push completed${NC}"
    fi
}

# 显示结果摘要
show_summary() {
    echo ""
    echo -e "${GREEN}✨ Build Summary${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    
    local tags=($(build_tags))
    for tag in "${tags[@]}"; do
        echo -e "${GREEN}📸 Image:${NC} ${YELLOW}${tag}${NC}"
        docker images --filter "reference=${tag}" --format "   Size: {{.Size}} | Created: {{.CreatedAt}}"
    done
    
    echo ""
    echo -e "${BLUE}To use this image in JupyterHub:${NC}"
    echo "   c.DockerSpawner.image = '${tags[0]}'"
    
    if [[ ${#tags[@]} -gt 1 ]]; then
        echo "   # Alternative tags:"
        for tag in "${tags[@]:1}"; do
            echo "   # ${tag}"
        done
    fi
}

# 主函数
main() {
    # 解析命令行参数
    parse_args "$@"
    
    # 验证版本支持
    validate_versions
    
    # 检查必要文件
    check_files
    
    # 显示构建信息
    show_build_info
    
    # 如果需要，清理旧镜像
    clean_old_images
    
    # 执行构建
    if run_build; then
        # 测试镜像
        test_image
        
        # 如果需要，推送镜像
        push_image
        
        # 显示结果摘要
        show_summary
        
        echo -e "${GREEN}✅ Build completed successfully!${NC}"
    else
        echo -e "${RED}❌ Build failed!${NC}"
        exit 1
    fi
}

# 运行主函数
main "$@"