#!/bin/bash
set -euo pipefail

# =====================================================
# 颜色定义
# =====================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =====================================================
# 默认参数
# =====================================================
PYTHON_MAJOR_MINOR="3.10"
PYTHON_VERSION="3.10.20"
UBUNTU_VERSION="24.04"
TAG_SUFFIX=""
PUSH=false
PLATFORMS="linux/amd64,linux/arm64"
REGISTRY="docker.io"    # 镜像仓库
OWNER="zhongshengchen"  # 仓库所有者
TARGET=""               # 指定构建目标

# =====================================================
# 显示帮助
# =====================================================
show_help() {
    echo -e "${CYAN}Jupyter Build Script (bake-based)${NC}"
    echo
    echo "Usage:"
    echo "  ./build.sh [options] [target]"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "  -m, --major VERSION     Python major.minor (default: 3.10)"
    echo "  -p, --python VERSION    Python full version (default: 3.10.12)"
    echo "  -u, --ubuntu VERSION    Ubuntu version (default: 22.04)"
    echo "  -t, --tag SUFFIX        Tag suffix"
    echo "      --push              Push image to registry"
    echo "      --platforms LIST    Platforms (default: linux/amd64,linux/arm64)"
    echo "  -h, --help              Show this help message"
    echo
    echo -e "${YELLOW}Targets:${NC}"
    echo "  foundation              Build only foundation image"
    echo "  base-notebook           Build only base-notebook image"
    echo "  jupyter-custom-image    Build only custom image"
    echo "  (empty)                 Build all targets"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./build.sh"
    echo "  ./build.sh --push"
    echo "  ./build.sh --platforms linux/amd64"
    echo "  ./build.sh foundation"
    echo "  ./build.sh base-notebook --push"
    echo "  ./build.sh -m 3.9 -u 20.04 jupyter-custom-image"
    echo
}

# =====================================================
# 参数解析
# =====================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--major) PYTHON_MAJOR_MINOR="$2"; shift 2 ;;
            -p|--python) PYTHON_VERSION="$2"; shift 2 ;;
            -u|--ubuntu) UBUNTU_VERSION="$2"; shift 2 ;;
            -t|--tag) TAG_SUFFIX="$2"; shift 2 ;;
            --push) PUSH=true; shift ;;
            --platforms) PLATFORMS="$2"; shift 2 ;;
            -h|--help) show_help; exit 0 ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                # 第一个非选项参数作为 target
                if [[ -z "$TARGET" ]]; then
                    TARGET="$1"
                    shift
                else
                    echo -e "${RED}Unexpected argument: $1${NC}"
                    show_help
                    exit 1
                fi
                ;;
        esac
    done
}

# =====================================================
# 版本校验
# =====================================================
validate_versions() {
    if [[ ! "$PYTHON_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Invalid Python version: $PYTHON_VERSION${NC}"
        exit 1
    fi
    
    # 提取 Python 主次版本号，确保与 PYTHON_MAJOR_MINOR 一致
    local extracted_major_minor=$(echo "$PYTHON_VERSION" | cut -d. -f1-2)
    if [[ "$extracted_major_minor" != "$PYTHON_MAJOR_MINOR" ]]; then
        echo -e "${YELLOW}⚠️  Warning: Python major.minor ($PYTHON_MAJOR_MINOR) does not match Python version ($PYTHON_VERSION)${NC}"
        echo -e "${YELLOW}   Using major.minor from version: $extracted_major_minor${NC}"
        PYTHON_MAJOR_MINOR="$extracted_major_minor"
    fi
}

# =====================================================
# 检查文件
# =====================================================
check_files() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root
    project_root="$(cd "$script_dir/.." && pwd)"

    if [[ ! -f "$project_root/docker-bake.hcl" ]]; then
        echo "docker-bake.hcl not found in project root: $project_root"
        exit 1
    fi
}

# =====================================================
# 打印构建配置信息
# =====================================================
print_build_runtime() {
    echo "======================================"
    echo "Python Version : $PYTHON_VERSION"
    echo "Major.Minor    : $PYTHON_MAJOR_MINOR"
    echo "Ubuntu         : $UBUNTU_VERSION"
    echo "Platforms      : $PLATFORMS"
    echo "Push           : $PUSH"
    if [[ -n "$TARGET" ]]; then
        echo "Target         : $TARGET"
    else
        echo "Target         : all (foundation, base-notebook, jupyter-custom-image)"
    fi
    echo "======================================"
}

# =====================================================
# 清理旧镜像（可选）
# =====================================================
clean_old_images() {
    echo "Skipping old image cleanup (bake handles caching)."
}

# =====================================================
# 检查远程镜像是否存在
# =====================================================
check_remote_image() {
    local image="$1"
    local tag="$2"
    
    if docker buildx imagetools inspect "${REGISTRY}/${OWNER}/${image}:${tag}" &>/dev/null; then
        return 0  # 存在
    else
        return 1  # 不存在
    fi
}

# =====================================================
# 分步构建
# =====================================================
build_step() {
    local step_target="$1"
    local step_platforms="$2"
    local step_push="$3"
    
    local step_cmd="docker buildx bake $step_target"
    
    if [[ "$step_platforms" == *","* ]]; then
        step_cmd="$step_cmd --push"
    else
        if [[ "$step_push" == "true" ]]; then
            step_cmd="$step_cmd --push"
        else
            step_cmd="$step_cmd --load"
        fi
    fi
    
    echo -e "${CYAN}▶ Building $step_target...${NC}"
    
    REGISTRY="$REGISTRY" \
    OWNER="$OWNER" \
    PYTHON_MAJOR_MINOR="$PYTHON_MAJOR_MINOR" \
    PYTHON_VERSION="$PYTHON_VERSION" \
    UBUNTU_VERSION="$UBUNTU_VERSION" \
    TAG_SUFFIX="$TAG_SUFFIX" \
    PLATFORMS="$step_platforms" \
    $step_cmd
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Failed to build $step_target${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ $step_target built successfully${NC}"
}

# =====================================================
# 执行构建
# =====================================================
run_build() {
    # 获取脚本所在目录和项目根目录
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root
    project_root="$(cd "$script_dir/.." && pwd)"
    
    echo -e "${BLUE}📂 Project root: $project_root${NC}"
    
    # 切换到项目根目录
    cd "$project_root"
    
    # 生成基础镜像的 tag
    local foundation_tag="ubuntu${UBUNTU_VERSION}-py${PYTHON_MAJOR_MINOR}"
    local base_notebook_tag="ubuntu${UBUNTU_VERSION}-py${PYTHON_MAJOR_MINOR}"

    if [[ -n "$TAG_SUFFIX" ]]; then
        foundation_tag="${foundation_tag}-${TAG_SUFFIX}"
        base_notebook_tag="${base_notebook_tag}-${TAG_SUFFIX}"
    fi

    # 检查 foundation 镜像
    if [[ -z "$TARGET" || "$TARGET" == "base-notebook" || "$TARGET" == "jupyter-custom-image" ]]; then
        if ! check_remote_image "docker-stacks-foundation" "$foundation_tag"; then
            echo -e "${YELLOW}⚠️  ${REGISTRY}/${OWNER}/docker-stacks-foundation:${foundation_tag} not found in remote repository${NC}"
            echo -e "${YELLOW}   Building and pushing foundation first...${NC}"
            
            # 强制推送 foundation 到远程
            REGISTRY="$REGISTRY" \
            OWNER="$OWNER" \
            PYTHON_MAJOR_MINOR="$PYTHON_MAJOR_MINOR" \
            PYTHON_VERSION="$PYTHON_VERSION" \
            UBUNTU_VERSION="$UBUNTU_VERSION" \
            TAG_SUFFIX="$TAG_SUFFIX" \
            PLATFORMS="$PLATFORMS" \
            docker buildx bake foundation --push
            
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}❌ Failed to build and push foundation${NC}"
                exit 1
            fi
            echo -e "${GREEN}✅ foundation built and pushed successfully${NC}"
        fi
    fi

    # 检查 base-notebook 镜像
    if [[ -z "$TARGET" || "$TARGET" == "jupyter-custom-image" ]]; then
        if ! check_remote_image "base-notebook" "$base_notebook_tag"; then
            echo -e "${YELLOW}⚠️  ${REGISTRY}/${OWNER}/base-notebook:${base_notebook_tag} not found in remote repository${NC}"
            echo -e "${YELLOW}   Building and pushing base-notebook first...${NC}"
            
            # 强制推送 base-notebook 到远程
            REGISTRY="$REGISTRY" \
            OWNER="$OWNER" \
            PYTHON_MAJOR_MINOR="$PYTHON_MAJOR_MINOR" \
            PYTHON_VERSION="$PYTHON_VERSION" \
            UBUNTU_VERSION="$UBUNTU_VERSION" \
            TAG_SUFFIX="$TAG_SUFFIX" \
            PLATFORMS="$PLATFORMS" \
            docker buildx bake base-notebook --push
            
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}❌ Failed to build and push base-notebook${NC}"
                exit 1
            fi
            echo -e "${GREEN}✅ base-notebook built and pushed successfully${NC}"
        fi
    fi
    
    # 执行构建
    if [[ -n "$TARGET" ]]; then
        # 构建指定目标
        build_step "$TARGET" "$PLATFORMS" "$PUSH"
    else
        # 构建所有目标
        echo -e "${BLUE}📦 Building all targets...${NC}"
        build_step "foundation" "$PLATFORMS" "$PUSH"
        build_step "base-notebook" "$PLATFORMS" "$PUSH"
        build_step "jupyter-custom-image" "$PLATFORMS" "$PUSH"
    fi
}

# =====================================================
# 测试镜像
# =====================================================
test_image() {
    # 如果推送到仓库或构建多平台，跳过测试
    if [[ "$PUSH" == "true" ]] || [[ "$PLATFORMS" == *","* ]]; then
        echo -e "${YELLOW}⚠️  Skipping test for pushed/multi-platform builds${NC}"
        return 0
    fi
    
    # 只测试最终的自定义镜像
    if [[ -n "$TARGET" && "$TARGET" != "jupyter-custom-image" ]]; then
        return 0
    fi
    
    echo "Testing image..."
    
    local image_tag="${REGISTRY}/${OWNER}/jupyter-custom:python-${PYTHON_VERSION}-ubuntu${UBUNTU_VERSION}"
    
    if [[ -n "$TAG_SUFFIX" ]]; then
        image_tag="${image_tag}-${TAG_SUFFIX}"
    fi
    
    echo "Testing: $image_tag"
    
    # 检查镜像是否存在
    if docker image inspect "$image_tag" &>/dev/null; then
        docker run --rm "$image_tag" python --version
    else
        echo -e "${YELLOW}⚠️  Image $image_tag not found locally, skipping test${NC}"
    fi
}

# =====================================================
# 推送镜像
# =====================================================
push_image() {
    if [[ "$PUSH" == "true" ]]; then
        echo "Push handled by buildx bake."
    fi
}

# =====================================================
# 打印构建结果摘要
# =====================================================
print_build_summary() {
    echo "======================================"
    echo -e "${GREEN}✅ Build completed successfully${NC}"
    echo "======================================"
    echo "Python Version : $PYTHON_VERSION"
    echo "Ubuntu         : $UBUNTU_VERSION"
    echo "Platforms      : $PLATFORMS"
    
    if [[ -n "$TARGET" ]]; then
        echo "Target         : $TARGET"
    fi
    
    if [[ "$PUSH" == "true" ]]; then
        echo "Push Status    : ${GREEN}Pushed to registry${NC}"
    elif [[ "$PLATFORMS" == *","* ]]; then
        echo "Push Status    : ${GREEN}Pushed to registry (multi-platform)${NC}"
    else
        echo "Push Status    : ${YELLOW}Local only${NC}"
    fi
    
    if [[ -n "$TAG_SUFFIX" ]]; then
        echo "Tag Suffix     : $TAG_SUFFIX"
    fi
    echo "======================================"
}

# =====================================================
# 主函数
# =====================================================
main() {
    parse_args "$@"
    validate_versions
    check_files
    print_build_runtime
    clean_old_images
    run_build
    test_image
    push_image
    print_build_summary
}

main "$@"