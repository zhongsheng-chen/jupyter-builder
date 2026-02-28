// =====================================================
// Variables
// =====================================================

variable "PYTHON_MAJOR_MINOR" {
  description = "Python major.minor version for foundation (e.g. 3.10)"
  default     = "3.10"
}

variable "PYTHON_VERSION" {
  description = "Exact Python version for final image (e.g. 3.10.12)"
  default     = "3.10.12"
}

variable "UBUNTU_VERSION" {
  default = "22.04"
}

variable "REGISTRY" {
  default = "docker.io"
}

variable "OWNER" {
  default = "zhongshengchen"
}

variable "TAG_SUFFIX" {
  default = ""
}

variable "PLATFORMS" {
  default = ""
}


variable "FOUNDATION_TAG" {
  default = "ubuntu${UBUNTU_VERSION}-py${PYTHON_MAJOR_MINOR}${TAG_SUFFIX != "" ? "-" + TAG_SUFFIX : ""}"
}

variable "BASE_NOTEBOOK_TAG" {
  default = "ubuntu${UBUNTU_VERSION}-py${PYTHON_MAJOR_MINOR}${TAG_SUFFIX != "" ? "-" + TAG_SUFFIX : ""}"
}

// =====================================================
// Group
// =====================================================

group "default" {
  targets = ["foundation", "base-notebook", "jupyter-custom-image"]
}

// =====================================================
// Foundation
// =====================================================

target "foundation" {
  context    = "./images/docker-stacks-foundation"
  dockerfile = "Dockerfile"

  args = {
    ROOT_IMAGE     = "ubuntu:${UBUNTU_VERSION}"
    PYTHON_VERSION = "${PYTHON_MAJOR_MINOR}"
    REGISTRY       = "${REGISTRY}"
    OWNER          = "${OWNER}"
  }

  tags = [
    "${REGISTRY}/${OWNER}/docker-stacks-foundation:${FOUNDATION_TAG}",
    "${REGISTRY}/${OWNER}/docker-stacks-foundation:latest"
  ]

  platforms = PLATFORMS != "" ? split(",", PLATFORMS) : null
}

// =====================================================
// Base Notebook
// =====================================================

target "base-notebook" {
  context    = "./images/base-notebook"
  dockerfile = "Dockerfile"
  
  args = {
    REGISTRY    = "${REGISTRY}"
    OWNER       = "${OWNER}"
    BASE_IMAGE  = "${REGISTRY}/${OWNER}/docker-stacks-foundation:${FOUNDATION_TAG}"
  }

  depends_on = ["foundation"]

  tags = [
    "${REGISTRY}/${OWNER}/base-notebook:${BASE_NOTEBOOK_TAG}",
    "${REGISTRY}/${OWNER}/base-notebook:latest"
  ]

  platforms = PLATFORMS != "" ? split(",", PLATFORMS) : null
}

// =====================================================
// Jupyter Custom Image
// =====================================================

target "jupyter-custom-image" {
  context    = "."
  dockerfile = "images/jupyter-custom-image/Dockerfile"

  args = {
    PYTHON_VERSION = "${PYTHON_VERSION}"
    UBUNTU_VERSION = "${UBUNTU_VERSION}"
    REGISTRY       = "${REGISTRY}"
    OWNER          = "${OWNER}"
    BASE_IMAGE     = "${REGISTRY}/${OWNER}/base-notebook:${BASE_NOTEBOOK_TAG}"
  }

  depends_on = ["base-notebook"]

  tags = [
    "${REGISTRY}/${OWNER}/jupyter-custom:python-${PYTHON_VERSION}-ubuntu${UBUNTU_VERSION}",
    "${REGISTRY}/${OWNER}/jupyter-custom:latest"
  ]

  platforms = PLATFORMS != "" ? split(",", PLATFORMS) : null
}