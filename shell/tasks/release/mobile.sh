#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUMP_TYPE=""
PLATFORM=""
AUTO_APPROVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --patch)
      BUMP_TYPE="1"
      shift
      ;;
    --minor)
      BUMP_TYPE="2"
      shift
      ;;
    --major)
      BUMP_TYPE="3"
      shift
      ;;
    --ios)
      PLATFORM="ios"
      shift
      ;;
    --android)
      PLATFORM="android"
      shift
      ;;
    --auto-approve)
      AUTO_APPROVE=true
      shift
      ;;
    *)
      printf "${RED}❌ Unknown option: $1${NC}\n"
      printf "Usage: $0 [--patch|--minor|--major] [--ios|--android] [--auto-approve]\n"
      exit 1
      ;;
  esac
done

printf "${BLUE}🚀 Mobile Release${NC}\n\n"

# 1. Check jq
if ! command -v jq &> /dev/null; then
  printf "${RED}❌ jq is required but not installed.${NC}\n"
  printf "   Install: brew install jq\n"
  exit 1
fi

# 2. Check clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  printf "${RED}❌ Working tree has uncommitted changes. Commit or stash before releasing.${NC}\n"
  exit 1
fi
printf "${GREEN}✓${NC} Working tree is clean\n"


# 3. Check if run/bump exists
if [ ! -f "run/bump" ]; then
  printf "${RED}❌ run/bump not found in this project.${NC}\n"
  printf "   Create run/bump to define how versions are bumped.\n"
  exit 1
fi

# 4. Check main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  printf "${RED}❌ Error: You must be on 'main' branch${NC}\n"
  printf "   Current branch: ${YELLOW}%s${NC}\n" "$CURRENT_BRANCH"
  exit 1
fi
printf "${GREEN}✓${NC} On main branch\n"

# 5. Fetch and check up to date with origin
printf "\n${BLUE}Fetching latest from origin...${NC}\n"
git fetch origin main --tags --prune --prune-tags --force

LOCAL=$(git rev-parse main)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
  printf "${YELLOW}⚠ Local main is behind origin — pulling...${NC}\n"
  git pull --rebase origin main
fi
printf "${GREEN}✓${NC} Main is up to date\n"

# 6. Resolve current version — highest remote tag is source of truth
if [ ! -f "app.json" ]; then
  printf "${RED}❌ app.json not found${NC}\n"
  exit 1
fi

# strips platform suffixes, picks highest semver tag from remote
LATEST_TAG=$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' \
  | sed 's/-android$//;s/-ios$//' \
  | sort -V | tail -1)
LATEST_VERSION=${LATEST_TAG#v}

APP_VERSION=$(jq -r '.expo.version' app.json)

if [ -n "$LATEST_VERSION" ]; then
  CURRENT_VERSION="$LATEST_VERSION"
else
  CURRENT_VERSION="$APP_VERSION"
fi

if [ "$CURRENT_VERSION" != "$APP_VERSION" ]; then
  printf "\n${YELLOW}⚠ app.json is at %s but latest tag is v%s — using tag as base${NC}\n" "$APP_VERSION" "$CURRENT_VERSION"
fi

printf "\n${BLUE}Current version:${NC} ${YELLOW}%s${NC}\n" "$CURRENT_VERSION"

IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# 7. Ask for bump type
if [ -z "$BUMP_TYPE" ]; then
  printf "\n${BLUE}What type of release is this?${NC}\n"
  printf "  1) ${GREEN}patch${NC} - Bug fixes (e.g., 1.2.3 → 1.2.4)\n"
  printf "  2) ${YELLOW}minor${NC} - New features (e.g., 1.2.3 → 1.3.0)\n"
  printf "  3) ${RED}major${NC} - Breaking changes (e.g., 1.2.3 → 2.0.0)\n"
  printf "  q) quit\n\n"
  read -p "Enter choice [1-3/q]: " BUMP_TYPE
fi

case $BUMP_TYPE in
  1)
    PATCH=$((PATCH + 1))
    BUMP_NAME="patch"
    ;;
  2)
    MINOR=$((MINOR + 1))
    PATCH=0
    BUMP_NAME="minor"
    ;;
  3)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    BUMP_NAME="major"
    ;;
  q|Q)
    printf "${YELLOW}Bye!${NC}\n"
    exit 0
    ;;
  *)
    printf "${RED}❌ Invalid choice${NC}\n"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# 8. Ask for platform
if [ -z "$PLATFORM" ]; then
  printf "\n${BLUE}Target platform?${NC}\n"
  printf "  1) ${GREEN}both${NC} - iOS and Android (default)\n"
  printf "  2) ios\n"
  printf "  3) android\n\n"
  read -p "Enter choice [1-3, default=1]: " PLATFORM_CHOICE
  case $PLATFORM_CHOICE in
    2) PLATFORM="ios" ;;
    3) PLATFORM="android" ;;
    *) PLATFORM="both" ;;
  esac
fi

# 9. Build draft tag
TAG="v$NEW_VERSION-draft"
if [ "$PLATFORM" = "ios" ]; then
  TAG="v$NEW_VERSION-draft-ios"
elif [ "$PLATFORM" = "android" ]; then
  TAG="v$NEW_VERSION-draft-android"
fi

# 9. Advance patch until a free version is found (checks local and remote tags)
while git tag --list | grep -q "^v${NEW_VERSION}" || git ls-remote --tags origin | grep -q "refs/tags/v${NEW_VERSION}"; do
  EXISTING=$(git tag --list | grep "^v${NEW_VERSION}")
  printf "${YELLOW}⚠ Version %s already tagged (%s) — advancing patch${NC}\n" "$NEW_VERSION" "$EXISTING"
  PATCH=$((PATCH + 1))
  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
  TAG="v$NEW_VERSION-draft"
  if [ "$PLATFORM" = "ios" ]; then
    TAG="v$NEW_VERSION-draft-ios"
  elif [ "$PLATFORM" = "android" ]; then
    TAG="v$NEW_VERSION-draft-android"
  fi
done

# 10. Confirm
printf "\n${BLUE}Release summary:${NC}\n"
printf "  Version:   ${YELLOW}%s${NC} → ${GREEN}%s${NC} (%s)\n" "$CURRENT_VERSION" "$NEW_VERSION" "$BUMP_NAME"
printf "  Platform:  ${GREEN}%s${NC}\n" "$PLATFORM"
printf "  Tag:       ${GREEN}%s${NC} → v%s (after bump)\n" "$TAG" "$NEW_VERSION"
printf "\n"

if [ "$AUTO_APPROVE" = false ]; then
  read -p "Proceed? [y/N]: " CONFIRM
  if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    printf "${YELLOW}Aborted${NC}\n"
    exit 0
  fi
else
  printf "${GREEN}✓${NC} Auto-approved\n"
fi

# 11. Create and push tag
printf "\n${BLUE}Creating tag %s...${NC}\n" "$TAG"
git tag "$TAG"
git push origin "$TAG"
printf "${GREEN}✓${NC} Tag pushed\n"

GIT_URL=$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')

printf "\n${GREEN}🎉 Done!${NC}\n"
printf "Tag ${GREEN}%s${NC} created and pushed\n" "$TAG"
printf "\n${BLUE}Monitor CI:${NC} ${GIT_URL}/actions\n"
