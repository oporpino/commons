# syntax=docker/dockerfile:1
# check=skip=InvalidDefaultArgInFrom

ARG DISTRO=alpine
ARG STACK
ARG STACK_VERSION
ARG CONTAINER_REGISTRY=
ARG _DEV_BASE=${CONTAINER_REGISTRY:+${CONTAINER_REGISTRY}/${STACK}:${STACK_VERSION}-${DISTRO}.dev}

# ── base ───────────────────────────────────────────────────────────────────────
# Shared foundation for runtime and dev. Only runtime deps.
# ──────────────────────────────────────────────────────────────────────────────
FROM ${STACK}:${STACK_VERSION}-${DISTRO} AS base

ARG DISTRO
ARG STACK

WORKDIR /source

COPY --from=commons-source shell/setup/environment/${DISTRO}/base.sh /tmp/setup/base.sh
RUN --mount=type=bind,target=/tmp/project-source \
  --mount=type=bind,from=commons-source,source=shell/setup/environment/${DISTRO},target=/tmp/commons/setup \
  --mount=type=bind,from=commons-source,target=/tmp/commons/root \
  export COMMONS_DIR=/tmp/commons/root && \
  mkdir -p /tmp/project/shell/setup && \
  if [ -d "/tmp/project-source/.module/shell/setup" ]; then \
    cp -r "/tmp/project-source/.module/shell/setup/." /tmp/project/shell/setup/; \
  elif [ -d "/tmp/project-source/.project/shell/setup" ]; then \
    cp -r "/tmp/project-source/.project/shell/setup/." /tmp/project/shell/setup/; \
  fi && \
  sh /tmp/setup/base.sh && \
  if [ -f /tmp/commons/setup/${STACK}.base.sh ]; then sh /tmp/commons/setup/${STACK}.base.sh; fi && \
  if [ -f /tmp/project/shell/setup/environment.base.sh ]; then sh /tmp/project/shell/setup/environment.base.sh; fi && \
  rm -rf /tmp/setup /tmp/project

# ── builder ────────────────────────────────────────────────────────────────────
# base + build tools + .commons/ + stack setup.
# Foundation for source, test, and dev.
# ──────────────────────────────────────────────────────────────────────────────
FROM base AS builder

ARG DISTRO
ARG STACK

COPY --from=commons-source shell/setup/environment/${DISTRO}/build.sh /tmp/setup/build.sh
RUN --mount=type=bind,from=commons-source,source=shell/setup/environment/${DISTRO},target=/tmp/commons/setup \
  sh /tmp/setup/build.sh && \
  if [ -f /tmp/commons/setup/${STACK}.build.sh ]; then sh /tmp/commons/setup/${STACK}.build.sh; fi && \
  rm -rf /tmp/setup

COPY --from=commons-source . .commons/
ENV COMMONS_DIR=/.commons
RUN ln -s /source/.commons /.commons

# ── dev ────────────────────────────────────────────────────────────────────────
# builder + dev comfort tools + oh-my-zsh.
# Pushed to registry via image.push. Code arrives via volume mount.
# ──────────────────────────────────────────────────────────────────────────────
FROM ${_DEV_BASE:-builder} AS dev

ARG DISTRO
ARG STACK

COPY --from=commons-source . /tmp/commons/
RUN rm -rf /.commons /source/.commons && \
  mv /tmp/commons /.commons && \
  ln -s /.commons /source/.commons
ENV COMMONS_DIR=/.commons

COPY --from=commons-source shell/setup/environment/${DISTRO}/dev.sh /tmp/setup/dev.sh
COPY --from=commons-source shell/setup/environment/shared/powertools.sh /tmp/setup/powertools.sh
RUN --mount=type=bind,from=commons-source,source=shell/setup/environment/${DISTRO},target=/tmp/commons/setup \
  sh /tmp/setup/dev.sh && \
  if [ -f /tmp/commons/setup/${STACK}.source.sh ]; then . /tmp/commons/setup/${STACK}.source.sh; fi && \
  bash /tmp/setup/powertools.sh && \
  rm -rf /tmp/setup

CMD ["run/runtime"]

# ── source ─────────────────────────────────────────────────────────────────────
# builder + installed dependencies + project code.
# ──────────────────────────────────────────────────────────────────────────────
FROM builder AS source

ARG DISTRO
ARG STACK
ARG DEPS_PATH=

COPY --from=lockfiles . .
COPY run/install run/install
COPY . .

RUN --mount=type=bind,from=commons-source,source=shell/setup/environment/${DISTRO},target=/tmp/commons/setup \
  --mount=type=secret,id=env,required=false,mode=0444 \
  if [ -f /tmp/commons/setup/${STACK}.source.sh ]; then . /tmp/commons/setup/${STACK}.source.sh; fi && \
  if [ -f .module/shell/setup/environment.base.sh ]; then . .module/shell/setup/environment.base.sh; \
  elif [ -f .project/shell/setup/environment.base.sh ]; then . .project/shell/setup/environment.base.sh; fi && \
  if [ -f .build-env ]; then set -a && . ./.build-env && set +a; fi && \
  if [ -f /run/secrets/env ]; then set -a && . /run/secrets/env && set +a; fi && \
  if [ -f run/install ]; then run/install; fi && \
  rm -rf /tmp/setup

# ── test ───────────────────────────────────────────────────────────────────────
FROM source AS test

RUN git init /source

CMD ["run/test"]

# ── runtime ────────────────────────────────────────────────────────────────────
# base (clean, no build tools) + code + deps from source.
# ──────────────────────────────────────────────────────────────────────────────
FROM base AS runtime

ARG DISTRO
ARG STACK
ARG DEPS_PATH=

COPY --from=source /source .
COPY --from=commons-source shell/tasks/docker/entrypoint.sh /usr/local/bin/entrypoint

RUN --mount=type=bind,from=source,source=/,target=/mnt/source \
  if [ -n "${DEPS_PATH}" ] && [ -d "/mnt/source${DEPS_PATH}" ]; then \
    mkdir -p "${DEPS_PATH}" && cp -r "/mnt/source${DEPS_PATH}/." "${DEPS_PATH}/"; \
  fi

RUN --mount=type=bind,from=commons-source,source=shell/setup/environment/${DISTRO},target=/tmp/commons/setup \
  if [ -f .build-env ]; then set -a && . ./.build-env && set +a; fi && \
  if [ -f /tmp/commons/setup/${STACK}.runtime.sh ]; then sh /tmp/commons/setup/${STACK}.runtime.sh; fi && \
  rm -rf /tmp/setup

ENTRYPOINT ["entrypoint"]
CMD ["run/runtime"]
