# Dockerfile
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# 使用构建参数，这些参数将从 docker-bake.hcl 传入
ARG BASE_IMAGE=base-notebook
ARG PYTHON_VERSION=3.10.12
ARG PYTHON_MAJOR=3
ARG PYTHON_MINOR=10
ARG PYTHON_PATCH=12
ARG PYTHON_MAJOR_MINOR=3.10
ARG BASE_PYTHON_MAJOR=3.10
ARG UBUNTU_VERSION=22.04
ARG NB_USER=jovyan
ARG NB_UID=1000
ARG CONDA_DIR=/opt/conda

# 使用之前构建的 base-notebook 作为基础镜像
FROM ${BASE_IMAGE}

# 设置环境变量
ENV PYTHON_VERSION=${PYTHON_VERSION:-3.10.12} \
    PYTHON_MAJOR=${PYTHON_MAJOR:-3} \
    PYTHON_MINOR=${PYTHON_MINOR:-10} \
    PYTHON_PATCH=${PYTHON_PATCH:-12} \
    PYTHON_MAJOR_MINOR=${PYTHON_MAJOR_MINOR:-3.10} \
    UBUNTU_VERSION=${UBUNTU_VERSION:-22.04} \
    DEBIAN_FRONTEND=noninteractive \
    NB_USER=${NB_USER:-jovyan} \
    NB_UID=${NB_UID:-1000} \
    CONDA_DIR=${CONDA_DIR:-/opt/conda}

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 切换到 root 用户
USER root

# 更新系统并安装必要的系统包
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends --fix-missing \
        # 构建工具
        build-essential \
        curl \
        git \
        vim \
        wget \
        ca-certificates \
        # Python 源码编译依赖
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libgdbm-dev \
        libdb5.3-dev \
        libbz2-dev \
        libexpat1-dev \
        liblzma-dev \
        tk-dev \
        libffi-dev \
        # 字体支持（用于 matplotlib/seaborn）
        fonts-liberation \
        # pandoc 用于转换 notebooks 到 html
        pandoc \
        # run-one - 用于支持 RESTARTABLE 选项
        run-one && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 重新声明 ARG 以便在 RUN 中使用
ARG PYTHON_VERSION
ARG PYTHON_MAJOR
ARG PYTHON_MINOR
ARG PYTHON_PATCH

# 检查当前 Python 版本，如果需要则从源码安装指定版本
RUN set -ex; \
    current_version=$(python --version 2>&1 | cut -d' ' -f2); \
    echo "Current Python version in base image: $current_version"; \
    echo "Requested Python version: ${PYTHON_VERSION}"; \
    \
    # 将版本号拆分为主要、次要、修订号
    current_major=$(echo $current_version | cut -d. -f1); \
    current_minor=$(echo $current_version | cut -d. -f2); \
    current_patch=$(echo $current_version | cut -d. -f3); \
    \
    requested_major=${PYTHON_MAJOR}; \
    requested_minor=${PYTHON_MINOR}; \
    requested_patch=${PYTHON_PATCH}; \
    \
    # 版本比较函数：如果当前版本 >= 请求版本，返回0（true）
    version_ge() { \
        if [ "$1" -gt "$4" ]; then \
            return 0; \
        elif [ "$1" -eq "$4" ] && [ "$2" -gt "$5" ]; then \
            return 0; \
        elif [ "$1" -eq "$4" ] && [ "$2" -eq "$5" ] && [ "$3" -ge "$6" ]; then \
            return 0; \
        else \
            return 1; \
        fi \
    }; \
    \
    # 确保变量不为空
    if [ -z "$requested_major" ] || [ -z "$requested_minor" ] || [ -z "$requested_patch" ]; then \
        echo "ERROR: Python version variables are empty!"; \
        echo "PYTHON_MAJOR=${PYTHON_MAJOR}"; \
        echo "PYTHON_MINOR=${PYTHON_MINOR}"; \
        echo "PYTHON_PATCH=${PYTHON_PATCH}"; \
        exit 1; \
    fi; \
    \
    # 如果当前版本 >= 请求版本，则不需要重新安装
    if version_ge "$current_major" "$current_minor" "$current_patch" "$requested_major" "$requested_minor" "$requested_patch"; then \
        echo "Current Python version ($current_version) is >= requested version (${PYTHON_VERSION}), no need to reinstall"; \
        \
        # 确保 pip 是最新的
        pip install --upgrade pip setuptools wheel; \
    else \
        echo "Current Python version ($current_version) is < requested version (${PYTHON_VERSION}), installing from source..."; \
        \
        # 下载 Python 源码
        cd /tmp; \
        wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz; \
        tar xzf Python-${PYTHON_VERSION}.tgz; \
        cd Python-${PYTHON_VERSION}; \
        \
        # 配置、编译、安装
        ./configure --enable-optimizations \
                    --prefix=/usr/local \
                    --with-ensurepip=install \
                    --enable-shared \
                    LDFLAGS="-Wl,-rpath /usr/local/lib"; \
        make -j$(nproc); \
        make altinstall; \
        \
        # 创建符号链接
        ln -sf /usr/local/bin/python${PYTHON_MAJOR}.${PYTHON_MINOR} /usr/local/bin/python3; \
        ln -sf /usr/local/bin/python${PYTHON_MAJOR}.${PYTHON_MINOR} /usr/local/bin/python; \
        ln -sf /usr/local/bin/pip${PYTHON_MAJOR}.${PYTHON_MINOR} /usr/local/bin/pip3; \
        ln -sf /usr/local/bin/pip${PYTHON_MAJOR}.${PYTHON_MINOR} /usr/local/bin/pip; \
        \
        # 更新 pip
        /usr/local/bin/pip${PYTHON_MAJOR}.${PYTHON_MINOR} install --upgrade pip setuptools wheel; \
        \
        # 清理
        cd /; \
        rm -rf /tmp/Python-${PYTHON_VERSION}*; \
        \
        echo "Python ${PYTHON_VERSION} installed successfully"; \
    fi

# 验证 Python 版本
RUN python --version && pip --version

# 复制本地文件（尽量晚放以避免缓存破坏）
COPY start-notebook.py start-notebook.sh start-singleuser.py start-singleuser.sh /usr/local/bin/
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

# 修复 /etc/jupyter 目录的权限（作为 root）
USER root
RUN fix-permissions /etc/jupyter/

# 复制 requirements.txt
COPY requirements.txt /tmp/requirements.txt

# 安装 Python 依赖（使用 jovyan 用户）
USER ${NB_UID}
WORKDIR /tmp

RUN if [ -s /tmp/requirements.txt ]; then \
        echo "Installing packages from requirements.txt..."; \
        pip install --no-cache-dir -r /tmp/requirements.txt; \
        echo "Requirements installed successfully"; \
    else \
        echo "requirements.txt is empty, skipping package installation"; \
    fi

# 清理临时文件（切换回 root）
USER root
RUN rm -f /tmp/requirements.txt

# 创建测试脚本并设置权限
RUN echo 'import sys; print(f"Python {sys.version}")' > /home/${NB_USER}/check_python.py && \
    chown ${NB_UID}:${NB_UID} /home/${NB_USER}/check_python.py

# macOS Rosetta 虚拟化会在上层创建由 root 拥有的垃圾目录
# 它会被重新创建，但在下一个指令后作为 NB_USER 运行，希望不会引起权限问题
# 更多信息：https://github.com/jupyter/docker-stacks/issues/2296
RUN rm -rf "/home/${NB_USER}/.cache/"

# 修复 Conda 目录和用户主目录的权限
RUN fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# 设置 Jupyter 端口
ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

# 健康检查
# 这个健康检查适用于 lab、notebook、nbclassic、server 和 retro jupyter 命令
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK --interval=3s --timeout=1s --start-period=3s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1

# 切换回 jovyan 用户以避免意外以 root 运行容器
USER ${NB_UID}

# 设置工作目录
WORKDIR "/home/${NB_USER}"

# 配置容器启动命令
CMD ["start-notebook.py"]