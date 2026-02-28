# Jupyter Base-Notebook 定制构建工具

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Jupyter](https://img.shields.io/badge/Jupyter-F37626.svg?style=for-the-badge&logo=Jupyter&logoColor=white)](https://jupyter.org/)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

## 📋 项目简介

本项目提供了一套完整的工具链，用于构建定制化的 Jupyter `base-notebook` Docker 镜像。您可以通过命令行参数灵活指定 **Ubuntu 版本**、**Python 完整版本号**（支持从 2.7 到 3.13 的各种小版本），并自动安装 `requirements.txt` 中定义的 Python 依赖包。

构建的镜像完全兼容 JupyterHub 的 DockerSpawner 和 Kubernetes 部署方案。

### ✨ 主要特性

- 🐍 **完整 Python 版本支持**：支持从 2.7.18 到 3.13.1 的完整版本号（如 `3.10.12`、`3.11.9`）
- 🐧 **多 Ubuntu 版本**：支持 18.04、20.04、22.04、24.04
- 🔧 **自动依赖管理**：自动安装 `requirements.txt` 中的所有 Python 包
- 🏗️ **多阶段构建**：使用 Docker Bake 进行高效的多阶段构建
- 🧪 **自动测试**：构建完成后自动测试 Python、Ubuntu 版本和包安装
- 📦 **多标签支持**：生成完整版本和主版本两个标签
- 🔄 **缓存优化**：支持构建缓存，加速重复构建
- 🚀 **JupyterHub 就绪**：生成的镜像可直接用于 JupyterHub

## 📁 项目结构
jupyter-builder/
├── scripts/
│ ├── build.sh # 主构建脚本
│ └── fetch-base-notebook-assets.sh # 下载官方文件
├── docker-bake.hcl # Docker Bake 配置文件
├── Dockerfile # 主 Dockerfile（遵循官方规范）
├── requirements.txt # Python 依赖包列表
├── README.md # 本文档
├── start-notebook.py # 官方启动脚本（自动下载）
├── start-notebook.sh # 官方启动脚本（自动下载）
├── start-singleuser.py # 官方单用户脚本（自动下载）
├── start-singleuser.sh # 官方单用户脚本（自动下载）
├── jupyter_server_config.py # Jupyter 服务器配置（自动下载）
└── docker_healthcheck.py # 健康检查脚本（自动下载）

text

## 🚀 快速开始

### 前提条件

- Docker 19.03+（支持 BuildKit）
- Docker Buildx（通常与 Docker 一起安装）
- Bash 4.0+

### 安装步骤

1. **创建项目目录**：
   ```bash
   mkdir -p ~/jupyter-builder
   cd ~/jupyter-builder
   mkdir -p scripts
创建脚本文件：
将以下文件内容复制到对应路径：

scripts/build.sh

scripts/fetch-base-notebook-assets.sh

docker-bake.hcl

Dockerfile

requirements.txt

赋予脚本执行权限：

bash
chmod +x scripts/*.sh
创建 requirements.txt（可选）：

bash
cat > requirements.txt << EOF
numpy==1.24.3
pandas==2.0.3
matplotlib==3.7.2
scikit-learn==1.3.0
jupyterlab==4.0.3
EOF
构建镜像：

bash
# 默认构建（Python 3.10.12, Ubuntu 22.04）
./scripts/build.sh
📖 使用指南
命令行选项
选项	描述	默认值
-p, --python VERSION	Python 完整版本号（如 3.10.12）	3.10.12
-u, --ubuntu VERSION	Ubuntu 版本	22.04
-i, --image NAME	镜像名称	zhongsheng/base-notebook
-t, --tag SUFFIX	额外的标签后缀	""
-c, --clean	清理构建（删除旧镜像）	false
-n, --no-cache	不使用构建缓存	false
--push	推送镜像到仓库	false
--platform PLATFORM	构建平台	linux/amd64
--skip-tests	跳过构建后的测试	false
`--force-major		
你写着写着就不是完整的markdown文本了，你给我了渲染后的文本
您说得对，我需要提供完整的、可以直接保存为 .md 文件的原始 Markdown 文本。以下是完整的 README.md 文件内容：

markdown
# Jupyter Base-Notebook 定制构建工具

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Jupyter](https://img.shields.io/badge/Jupyter-F37626.svg?style=for-the-badge&logo=Jupyter&logoColor=white)](https://jupyter.org/)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

## 📋 项目简介

本项目提供了一套完整的工具链，用于构建定制化的 Jupyter `base-notebook` Docker 镜像。您可以通过命令行参数灵活指定 **Ubuntu 版本**、**Python 完整版本号**（支持从 2.7 到 3.13 的各种小版本），并自动安装 `requirements.txt` 中定义的 Python 依赖包。

构建的镜像完全兼容 JupyterHub 的 DockerSpawner 和 Kubernetes 部署方案。

### ✨ 主要特性

- 🐍 **完整 Python 版本支持**：支持从 2.7.18 到 3.13.1 的完整版本号（如 `3.10.12`、`3.11.9`）
- 🐧 **多 Ubuntu 版本**：支持 18.04、20.04、22.04、24.04
- 🔧 **自动依赖管理**：自动安装 `requirements.txt` 中的所有 Python 包
- 🏗️ **多阶段构建**：使用 Docker Bake 进行高效的多阶段构建
- 🧪 **自动测试**：构建完成后自动测试 Python、Ubuntu 版本和包安装
- 📦 **多标签支持**：生成完整版本和主版本两个标签
- 🔄 **缓存优化**：支持构建缓存，加速重复构建
- 🚀 **JupyterHub 就绪**：生成的镜像可直接用于 JupyterHub

## 📁 项目结构
jupyter-builder/
├── scripts/
│ ├── build.sh # 主构建脚本
│ └── fetch-base-notebook-assets.sh # 下载官方文件
├── docker-bake.hcl # Docker Bake 配置文件
├── Dockerfile # 主 Dockerfile（遵循官方规范）
├── requirements.txt # Python 依赖包列表
├── README.md # 本文档
├── start-notebook.py # 官方启动脚本（自动下载）
├── start-notebook.sh # 官方启动脚本（自动下载）
├── start-singleuser.py # 官方单用户脚本（自动下载）
├── start-singleuser.sh # 官方单用户脚本（自动下载）
├── jupyter_server_config.py # Jupyter 服务器配置（自动下载）
└── docker_healthcheck.py # 健康检查脚本（自动下载）

text

## 🚀 快速开始

### 前提条件

- Docker 19.03+（支持 BuildKit）
- Docker Buildx（通常与 Docker 一起安装）
- Bash 4.0+

### 安装步骤

1. **创建项目目录**：
   ```bash
   mkdir -p ~/jupyter-builder
   cd ~/jupyter-builder
   mkdir -p scripts
创建脚本文件：
将以下文件内容复制到对应路径：

scripts/build.sh

scripts/fetch-base-notebook-assets.sh

docker-bake.hcl

Dockerfile

requirements.txt

赋予脚本执行权限：

bash
chmod +x scripts/*.sh
创建 requirements.txt（可选）：

bash
cat > requirements.txt << EOF
numpy==1.24.3
pandas==2.0.3
matplotlib==3.7.2
scikit-learn==1.3.0
jupyterlab==4.0.3
EOF
构建镜像：

bash
# 默认构建（Python 3.10.12, Ubuntu 22.04）
./scripts/build.sh
📖 使用指南
命令行选项
选项	描述	默认值
-p, --python VERSION	Python 完整版本号（如 3.10.12）	3.10.12
-u, --ubuntu VERSION	Ubuntu 版本	22.04
-i, --image NAME	镜像名称	zhongsheng/base-notebook
-t, --tag SUFFIX	额外的标签后缀	""
-c, --clean	清理构建（删除旧镜像）	false
-n, --no-cache	不使用构建缓存	false
--push	推送镜像到仓库	false
--platform PLATFORM	构建平台	linux/amd64
--skip-tests	跳过构建后的测试	false
--force-major MAJOR	强制基础镜像使用指定的 Python 主版本	""
-v, --verbose	显示详细输出	false
-h, --help	显示帮助信息	
使用示例
基本用法
bash
# 默认构建（Python 3.10.12, Ubuntu 22.04）
./scripts/build.sh

# 指定 Python 3.11.9 和 Ubuntu 24.04
./scripts/build.sh -p 3.11.9 -u 24.04

# 使用长选项
./scripts/build.sh --python 3.12.8 --ubuntu 22.04
高级用法
bash
# 清理构建并推送
./scripts/build.sh -p 3.11.9 -u 24.04 --clean --push

# 自定义镜像名称和标签后缀
./scripts/build.sh -p 3.10.16 -i myregistry/my-image -t dev

# 强制使用 Python 3.10 基础镜像但安装 3.10.16
./scripts/build.sh -p 3.10.16 --force-major 3.10

# 跨平台构建（ARM64）
./scripts/build.sh -p 3.11.9 --platform linux/arm64

# 跳过测试，详细输出
./scripts/build.sh -p 3.12.8 --skip-tests -v
Python 2.7 支持
bash
# 构建 Python 2.7.18 在 Ubuntu 18.04 上
./scripts/build.sh -p 2.7.18 -u 18.04
支持的版本组合
Python 版本	支持的 Ubuntu 版本	说明
2.7.18	18.04	Python 2 仅在 Ubuntu 18.04 上官方支持
3.6.15 - 3.9.21	18.04, 20.04	较旧的 Python 3 版本
3.10.0 - 3.10.16	20.04, 22.04, 24.04	Python 3.10 系列
3.11.0 - 3.11.11	20.04, 22.04, 24.04	Python 3.11 系列
3.12.0 - 3.12.8	22.04, 24.04	Python 3.12 系列
3.13.0 - 3.13.1	22.04, 24.04	Python 3.13 系列（需要较新系统）
🐳 在 JupyterHub 中使用
DockerSpawner 配置
在 jupyterhub_config.py 中：

python
c.DockerSpawner.image = 'zhongsheng/base-notebook:python-3.10.12-ubuntu22.04'
# 或使用主版本标签
# c.DockerSpawner.image = 'zhongsheng/base-notebook:python-3.10-ubuntu22.04'
Kubernetes (Zero to JupyterHub) 配置
在 config.yaml 中：

yaml
singleuser:
  image:
    name: zhongsheng/base-notebook
    tag: python-3.10.12-ubuntu22.04
  # 或者使用主版本标签
  # tag: python-3.10-ubuntu22.04
🔧 工作原理
构建流程
参数解析：build.sh 解析命令行参数，验证版本支持

文件检查：确保必要文件存在，必要时下载官方脚本

版本解析：将完整 Python 版本号（如 3.10.12）解析为组件

多阶段构建：

Stage 1: docker-stacks-foundation - 基础层，指定 Ubuntu 和 Python 主版本

Stage 2: base-notebook - Jupyter 基础层

Stage 3: 自定义层 - 安装 requirements.txt 和特定 Python 小版本

自动测试：验证 Python、Ubuntu 版本和包安装

标签生成：创建完整版本和主版本两个标签

推送（可选）：推送到镜像仓库

版本处理逻辑
如果指定的完整 Python 版本与基础镜像版本一致，直接使用

如果不一致，自动从源码编译安装指定的完整版本

--force-major 参数允许基础镜像使用较新的主版本，但最终安装较旧的完整版本

📊 输出示例
bash
$ ./scripts/build.sh -p 3.11.9 -u 24.04

🔨 Build configuration:
   Python version: 3.11.9 (3.11.9)
   Ubuntu version: 24.04
   Image name: zhongsheng/base-notebook
   Tags:
     zhongsheng/base-notebook:python-3.11.9-ubuntu24.04
     zhongsheng/base-notebook:python-3.11-ubuntu24.04

🚀 Starting build...
[+] Building 15.7s (24/24) FINISHED

🔍 Testing image...
   Python: Python 3.11.9
   ✓ Python version matches expected 3.11.9
   Ubuntu: Ubuntu 24.04 LTS
   Jupyter: 4.0.11
   Requirements: numpy installed (Version: 1.24.3)

✨ Build Summary
════════════════════════════════════════
📸 Image: zhongsheng/base-notebook:python-3.11.9-ubuntu24.04
   Size: 1.23GB | Created: 2024-01-15 10:30:45
📸 Image: zhongsheng/base-notebook:python-3.11-ubuntu24.04
   Size: 1.23GB | Created: 2024-01-15 10:30:45

To use this image in JupyterHub:
   c.DockerSpawner.image = 'zhongsheng/base-notebook:python-3.11.9-ubuntu24.04'

✅ Build completed successfully!
🐛 故障排除
常见问题
构建失败：无法下载官方文件

bash
# 手动下载或检查网络连接
./scripts/fetch-base-notebook-assets.sh
Python 版本编译错误

确保 Ubuntu 版本足够新以支持目标 Python 版本

检查系统依赖是否完整

权限问题

确保 fix-permissions 命令可用（在 Jupyter 基础镜像中提供）

检查目录所有权

Docker Buildx 未启用

bash
docker buildx install
# 或使用传统构建
export DOCKER_BUILDKIT=1
调试模式
bash
# 启用详细输出
./scripts/build.sh -v

# 跳过测试快速构建
./scripts/build.sh --skip-tests

# 不使用缓存进行干净构建
./scripts/build.sh -n
🤝 贡献指南
欢迎贡献！请遵循以下步骤：

Fork 本项目

创建特性分支 (git checkout -b feature/AmazingFeature)

提交更改 (git commit -m 'Add some AmazingFeature')

推送到分支 (git push origin feature/AmazingFeature)

打开 Pull Request

开发规范
脚本注释使用中文（帮助信息除外）

遵循 ShellCheck 规范

保持与官方 Jupyter Docker Stacks 兼容

📄 许可证
本项目基于 MIT License 开源。

🙏 致谢
Jupyter Docker Stacks - 官方 Jupyter Docker 镜像

Docker Buildx - 多平台构建工具

📞 联系方式
如有问题或建议，请提交 Issue 或 Pull Request。