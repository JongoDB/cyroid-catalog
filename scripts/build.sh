#!/bin/bash
#
# Build CYROID catalog images locally
#
# Usage:
#   ./scripts/build.sh                    # Build all images
#   ./scripts/build.sh kali-attack        # Build specific image
#   ./scripts/build.sh --push             # Build and push all to GHCR
#   ./scripts/build.sh kali-attack --push # Build and push specific image
#
# Environment:
#   REGISTRY_PREFIX  Override registry (default: ghcr.io/jongodb)
#   NO_CACHE         Set to 1 to build without cache
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGES_DIR="$REPO_ROOT/images"

REGISTRY_PREFIX="${REGISTRY_PREFIX:-ghcr.io/jongodb}"
PUSH=false
TARGET_IMAGE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [image-name] [--push]"
            echo ""
            echo "Options:"
            echo "  image-name   Specific image to build (default: all)"
            echo "  --push       Push to registry after building"
            echo ""
            echo "Available images:"
            ls -1 "$IMAGES_DIR" | grep -v "^\\." | while read img; do
                if [ -f "$IMAGES_DIR/$img/Dockerfile" ]; then
                    echo "  - $img"
                fi
            done
            exit 0
            ;;
        *)
            TARGET_IMAGE="$1"
            shift
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get list of images to build
get_images() {
    if [ -n "$TARGET_IMAGE" ]; then
        if [ -d "$IMAGES_DIR/$TARGET_IMAGE" ] && [ -f "$IMAGES_DIR/$TARGET_IMAGE/Dockerfile" ]; then
            echo "$TARGET_IMAGE"
        else
            log_error "Image '$TARGET_IMAGE' not found or has no Dockerfile"
            exit 1
        fi
    else
        # Find all directories with Dockerfiles
        find "$IMAGES_DIR" -mindepth 1 -maxdepth 1 -type d -exec test -f {}/Dockerfile \; -print | xargs -I {} basename {} | sort
    fi
}

# Read image metadata from image.yaml
read_metadata() {
    local image_dir="$1"
    local yaml_file="$image_dir/image.yaml"

    if [ -f "$yaml_file" ]; then
        NAME=$(grep '^name:' "$yaml_file" | sed 's/name: *//')
        TAG=$(grep '^tag:' "$yaml_file" | sed 's/tag: *//' | tr -d '"')
        ARCH=$(grep '^arch:' "$yaml_file" | sed 's/arch: *//')
        CATEGORY=$(grep '^category:' "$yaml_file" | sed 's/category: *//')
    else
        NAME="$(basename "$image_dir")"
        TAG="cyroid/$(basename "$image_dir"):latest"
        ARCH="x86_64"
        CATEGORY="unknown"
    fi

    # Extract image name for registry
    IMAGE_NAME=$(echo "$TAG" | sed 's|cyroid/||' | sed 's|:.*||')
}

# Build a single image
build_image() {
    local image="$1"
    local image_dir="$IMAGES_DIR/$image"

    log_info "Building $image..."

    read_metadata "$image_dir"

    local full_tag="$REGISTRY_PREFIX/$IMAGE_NAME:latest"
    local build_args=""

    if [ "$NO_CACHE" = "1" ]; then
        build_args="--no-cache"
    fi

    # Determine platform
    local platform_args=""
    if [ "$ARCH" = "both" ]; then
        # Check if buildx is available for multi-arch
        if docker buildx version &>/dev/null; then
            log_info "  Multi-arch build (amd64 + arm64)"
            platform_args="--platform linux/amd64,linux/arm64"

            if [ "$PUSH" = true ]; then
                docker buildx build $build_args $platform_args \
                    -t "$full_tag" \
                    --push \
                    "$image_dir"
            else
                # For local multi-arch, just build for current platform
                log_warn "  Multi-arch without push - building for current platform only"
                docker build $build_args -t "$full_tag" "$image_dir"
            fi
        else
            log_warn "  buildx not available, building single arch"
            docker build $build_args -t "$full_tag" "$image_dir"
        fi
    else
        docker build $build_args -t "$full_tag" "$image_dir"
    fi

    log_success "Built $full_tag"

    # Push if requested (single arch)
    if [ "$PUSH" = true ] && [ "$ARCH" != "both" ]; then
        log_info "  Pushing to registry..."
        docker push "$full_tag"
        log_success "Pushed $full_tag"
    fi

    echo ""
}

# Main
main() {
    echo "================================"
    echo "CYROID Catalog Image Builder"
    echo "================================"
    echo ""
    echo "Registry: $REGISTRY_PREFIX"
    echo "Push: $PUSH"
    echo ""

    local images=$(get_images)
    local count=$(echo "$images" | wc -l | tr -d ' ')

    log_info "Found $count image(s) to build"
    echo ""

    local failed=0
    local succeeded=0

    for image in $images; do
        if build_image "$image"; then
            ((succeeded++))
        else
            ((failed++))
            log_error "Failed to build $image"
        fi
    done

    echo "================================"
    echo "Build Summary"
    echo "================================"
    log_success "Succeeded: $succeeded"
    if [ $failed -gt 0 ]; then
        log_error "Failed: $failed"
        exit 1
    fi
}

main
