// docker-bake.hcl

// 定义变量，这些变量将从 build.sh 脚本中通过环境变量传入
variable "PYTHON_VERSION" {
  default = "3.10.12"  // 默认使用完整的 Python 版本号
}

variable "PYTHON_MAJOR" {
  default = "3"
}

variable "PYTHON_MINOR" {
  default = "10"
}

variable "PYTHON_PATCH" {
  default = "12"
}

variable "PYTHON_MAJOR_MINOR" {
  default = "3.10"
}

// 用于指定基础镜像应该使用的主版本（例如 "3.10"）
// 当需要基础镜像为 3.10，但最终安装 3.10.16 时非常有用
variable "BASE_PYTHON_MAJOR" {
  default = "3.10"
}

variable "UBUNTU_VERSION" {
  default = "22.04"
}

variable "IMAGE_NAME" {
  default = "zhongsheng/base-notebook"
}

variable "TAG_SUFFIX" {
  default = ""
}

// 新增：判断是否为 Ubuntu 18.04 的辅助变量
variable "IS_UBUNTU_18" {
  default = UBUNTU_VERSION == "18.04" ? "true" : "false"
}

// 定义构建组，默认构建最终的自定义镜像
group "default" {
  targets = ["jupyter-custom-image"]
}

// 目标 1: 构建 docker-stacks-foundation
// 这是最基础的层，负责操作系统和核心 Python 环境
target "foundation" {
    // 直接从 GitHub 官方仓库拉取 foundation 的构建上下文
    context = "https://github.com/jupyter/docker-stacks.git#main:images/docker-stacks-foundation"
    // 传递构建参数，这些将覆盖 Dockerfile 中的默认值
    args = {
        // 通过 ROOT_IMAGE 指定基础 Ubuntu 版本
        ROOT_IMAGE = "ubuntu:${UBUNTU_VERSION}"
        // 指定要安装的 Python 主次版本（如 3.10），这里使用基础版本
        PYTHON_VERSION = "${BASE_PYTHON_MAJOR}"
        // 传递 Ubuntu 版本信息，以便在 foundation 的 Dockerfile 中做条件判断
        UBUNTU_VERSION = "${UBUNTU_VERSION}"
        // 传递是否手动安装 tini 的标志
        MANUAL_TINI = "${IS_UBUNTU_18}"
    }
    // 为这个中间层镜像打标签，方便调试，非必须
    tags = ["custom-foundation:ubuntu${UBUNTU_VERSION}-py${BASE_PYTHON_MAJOR}"]
}

// 目标 2: 构建 base-notebook，它依赖于 foundation
target "base-notebook" {
    // 直接从 GitHub 官方仓库拉取 base-notebook 的构建上下文
    context = "https://github.com/jupyter/docker-stacks.git#main:images/base-notebook"
    // 声明构建上下文依赖：将上一步构建的 foundation 目标作为 base-notebook 的构建基础
    contexts = {
        docker-stacks-foundation = "target:foundation"
    }
    // 传递构建参数
    args = {
        // 告诉 base-notebook 的 Dockerfile，基础镜像是刚刚构建的 foundation
        BASE_IMAGE = "docker-stacks-foundation"
        // 传递 Ubuntu 版本信息，以便在 base-notebook 的 Dockerfile 中做条件判断（如果需要）
        UBUNTU_VERSION = "${UBUNTU_VERSION}"
    }
    // 为这个中间层镜像打标签，方便调试，非必须
    tags = ["custom-base-notebook:ubuntu${UBUNTU_VERSION}-py${BASE_PYTHON_MAJOR}"]
}

// 目标 3: 最终的个性化镜像，它依赖于 base-notebook
target "jupyter-custom-image" {
    // 使用本地目录作为构建上下文，这样 Dockerfile 可以 COPY 本地的 requirements.txt 等文件
    context = "."
    // 明确指定使用当前目录下的 Dockerfile
    dockerfile = "Dockerfile"
    // 声明依赖：将上一步构建的 base-notebook 目标作为本步骤的基础
    contexts = {
        // 在本地 Dockerfile 中，可以通过 --from=base-notebook 引用此镜像
        base-notebook = "target:base-notebook"
    }
    // 向本地 Dockerfile 传递构建参数
    args = {
        // 告诉本地 Dockerfile，基础镜像是 base-notebook
        BASE_IMAGE = "base-notebook"
        // 传递完整的 Python 版本信息，以便在最终镜像中安装或验证
        PYTHON_VERSION = "${PYTHON_VERSION}"
        PYTHON_MAJOR = "${PYTHON_MAJOR}"
        PYTHON_MINOR = "${PYTHON_MINOR}"
        PYTHON_PATCH = "${PYTHON_PATCH}"
        PYTHON_MAJOR_MINOR = "${PYTHON_MAJOR_MINOR}"
        BASE_PYTHON_MAJOR = "${BASE_PYTHON_MAJOR}"
        UBUNTU_VERSION = "${UBUNTU_VERSION}"
    }
    // 生成最终镜像的标签
    tags = [
        // 主标签：包含完整 Python 版本
        TAG_SUFFIX != "" ? "${IMAGE_NAME}:python-${PYTHON_VERSION}-ubuntu${UBUNTU_VERSION}-${TAG_SUFFIX}" : "${IMAGE_NAME}:python-${PYTHON_VERSION}-ubuntu${UBUNTU_VERSION}",
        // 便捷标签：仅包含主次 Python 版本
        TAG_SUFFIX != "" ? "${IMAGE_NAME}:python-${PYTHON_MAJOR_MINOR}-ubuntu${UBUNTU_VERSION}-${TAG_SUFFIX}" : "${IMAGE_NAME}:python-${PYTHON_MAJOR_MINOR}-ubuntu${UBUNTU_VERSION}"
    ]
    
    // 添加镜像标签 (Labels) 用于元数据
    labels = {
        "org.opencontainers.image.source" = "https://github.com/jupyter/docker-stacks"
        "org.opencontainers.image.version" = "${PYTHON_VERSION}"
        "org.opencontainers.image.description" = "Custom Jupyter base-notebook with Python ${PYTHON_VERSION} on Ubuntu ${UBUNTU_VERSION}"
        "org.opencontainers.image.created" = "${timestamp()}"
        "python.full.version" = "${PYTHON_VERSION}"
        "python.major.minor" = "${PYTHON_MAJOR_MINOR}"
        "ubuntu.version" = "${UBUNTU_VERSION}"
    }
}