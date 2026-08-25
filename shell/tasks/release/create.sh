#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
BUMP_TYPE=""
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
    --auto-approve)
      AUTO_APPROVE=true
      shift
      ;;
    *)
      printf "${RED}❌ Unknown option: $1${NC}\n"
      printf "Usage: $0 [--patch|--minor|--major] [--auto-approve]\n"
      exit 1
      ;;
  esac
done

printf "${BLUE}🚀 Release Tag Creator${NC}\n\n"

# 1. Check if on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  printf "${RED}❌ Error: You must be on 'main' branch${NC}\n"
  printf "   Current branch: ${YELLOW}%s${NC}\n" "$CURRENT_BRANCH"
  exit 1
fi
printf "${GREEN}✓${NC} On main branch\n"

# 2. Fetch latest from origin
printf "\n${BLUE}Fetching latest from origin...${NC}\n"
git fetch origin main --tags --prune

# 3. Check if main is up to date
LOCAL=$(git rev-parse main)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
  printf "${RED}❌ Error: Local main is not up to date with origin/main${NC}\n"
  printf "   Run: ${YELLOW}git pull origin main${NC}\n"
  exit 1
fi
printf "${GREEN}✓${NC} Main is up to date\n"

# 4. Get current version from latest tag
CURRENT_VERSION=$(git tag --sort=-version:refname | head -1)
if [ -z "$CURRENT_VERSION" ]; then
  CURRENT_VERSION="v0.0.0"
fi
printf "\n${BLUE}Current version:${NC} ${YELLOW}%s${NC}\n" "$CURRENT_VERSION"

# Remove 'v' prefix for processing
VERSION=${CURRENT_VERSION#v}

# Split version into components
IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# 5. Ask for bump type (if not provided via flag)
if [ -z "$BUMP_TYPE" ]; then
  printf "\n${BLUE}What type of release is this?${NC}\n"
  printf "  1) ${GREEN}patch${NC} - Bug fixes, small changes (e.g., v1.2.3 → v1.2.4)\n"
  printf "  2) ${YELLOW}minor${NC} - New features, backwards compatible (e.g., v1.2.3 → v1.3.0)\n"
  printf "  3) ${RED}major${NC} - Breaking changes (e.g., v1.2.3 → v2.0.0)\n"
  printf "  q) quit\n"
  printf "\n"
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

NEW_VERSION="v$MAJOR.$MINOR.$PATCH"

# 6. Confirm
printf "\n${BLUE}Version bump (%s):${NC}\n" "$BUMP_NAME"
printf "  ${YELLOW}%s${NC} → ${GREEN}%s${NC}\n" "$CURRENT_VERSION" "$NEW_VERSION"
printf "\n"

if [ "$AUTO_APPROVE" = false ]; then
  read -p "Create and push tag $NEW_VERSION? [y/N]: " CONFIRM

  if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    printf "${YELLOW}Aborted${NC}\n"
    exit 0
  fi
else
  printf "${GREEN}✓${NC} Auto-approved\n"
fi

# 7. Create tag
printf "\n${BLUE}Creating tag %s...${NC}\n" "$NEW_VERSION"
git tag "$NEW_VERSION"
printf "${GREEN}✓${NC} Tag created locally\n\n"

# 8. Push tag
printf "${BLUE}Pushing tag to origin...${NC}\n"
git push origin "$NEW_VERSION" --no-verify
printf "${GREEN}✓${NC} Tag pushed to origin\n"

# 9. Clean local staging branch if it exists
if git show-ref --verify --quiet refs/heads/staging; then
  printf "\n${BLUE}Cleaning local staging branch...${NC}\n"
  git branch -D staging
  printf "${GREEN}✓${NC} Local staging branch deleted (CI will recreate remote version)\n"
fi

printf "\n${GREEN}🎉 Success!${NC}\n"
printf "Tag ${GREEN}%s${NC} created and pushed\n" "$NEW_VERSION"

# Get GitHub URL from git remote
GIT_URL=$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')

# Extract repo name from URL
REPO_NAME=$(basename "$GIT_URL")

printf "\n${BLUE}Next steps:${NC}\n"
printf "  1. CI will run tests automatically\n"
printf "  2. If tests pass, CI will push to 'staging' branch\n"
printf "  3. Platform (Heroku/Railway/Netlify) will auto-deploy from 'staging' branch\n"
printf "  4. Monitor CI: ${GIT_URL}/actions\n"
printf "  5. Validate in your staging environment\n"
printf "\n${BLUE}To deploy to production:${NC}\n"
printf "  1. Go to: ${GIT_URL}/actions/workflows/deploy-production.yml\n"
printf "  2. Click 'Run workflow'\n"
printf "  3. Workflow will test and push to 'production' branch if tests pass\n"

