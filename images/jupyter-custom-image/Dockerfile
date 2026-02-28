# =====================================================
# 构建参数
# =====================================================
ARG REGISTRY=docker.io
ARG OWNER=zhongsheng
ARG BASE_IMAGE=${REGISTRY}/${OWNER}/base-notebook

FROM ${BASE_IMAGE}

ARG PYTHON_VERSION

RUN echo "Using Python version: ${PYTHON_VERSION}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL maintainer="Zhongsheng Chen <zhongsheng.chen@outlook.com>"

ENV DEBIAN_FRONTEND=noninteractive

# 切换到 root 用户安装系统依赖
USER root

# =====================================================
# 安装系统依赖
# =====================================================
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
        curl \
        git \
        nano-tiny \
        tzdata \
        unzip \
        vim-tiny \
        openssh-client \
        less \
        texlive-xetex \
        texlive-fonts-recommended \
        texlive-plain-generic \
        xclip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 将 nano 命令指向 nano-tiny
RUN update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10

# 修复 macOS Rosetta 虚拟化可能导致的 root 权限缓存目录问题
RUN rm -rf "/home/${NB_USER}/.cache/"

# =====================================================
# 锁定 PYTHON_VERSION（以 root 执行）
# =====================================================
RUN mamba install --yes python=${PYTHON_VERSION} && \
    mamba clean -afy

# =====================================================
# 使用 mamba 安装科学计算核心库（以 root 用户执行）
# =====================================================
RUN mamba install --yes \
        numpy \
        pandas \
        scipy \
        scikit-learn \
        statsmodels \
        matplotlib \
        seaborn \
        xgboost \
        lightgbm \
        sqlalchemy \
    && mamba clean --all -f -y \
    && fix-permissions "${CONDA_DIR}" \
    && fix-permissions "/home/${NB_USER}"

# =====================================================
# 使用 pip 安装额外 Python 依赖（以 jovyan 用户执行）
# =====================================================
WORKDIR /tmp

# 复制 requirements.txt
COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp/requirements.txt

RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt \
    && fix-permissions "${CONDA_DIR}" \
    && fix-permissions "/home/${NB_USER}"

# =====================================================
# 修复启动脚本权限
# =====================================================
USER root
RUN chmod +x /usr/local/bin/start.sh \
    /usr/local/bin/start-notebook.sh \
    /usr/local/bin/start-singleuser.sh \
    /usr/local/bin/start-notebook.py \
    /usr/local/bin/start-singleuser.py \
    && fix-permissions /usr/local/bin/

# 确保 jovyan 用户可以执行这些脚本
RUN ls -la /usr/local/bin/start*.sh /usr/local/bin/start*.py

# 切回普通用户
USER ${NB_UID}

# 返回用户主目录
WORKDIR "${HOME}"