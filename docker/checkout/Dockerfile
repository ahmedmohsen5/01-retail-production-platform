# syntax=docker/dockerfile:1.7

FROM node:22-bookworm AS build

WORKDIR /workspace/checkout

COPY checkout/package.json ./
COPY checkout/yarn.lock ./
COPY checkout/.yarnrc.yml ./
COPY checkout/.yarn ./.yarn

RUN corepack enable

RUN --mount=type=cache,target=/root/.yarn/berry/cache yarn install --immutable

COPY checkout/ ./

RUN yarn build

FROM node:22-bookworm-slim AS runtime

WORKDIR /app

RUN groupadd -g 10001 app && useradd -u 10001 -g 10001 --no-create-home --shell /usr/sbin/nologin app

COPY --from=build --chown=10001:10001 \
    /workspace/checkout/dist \
    /app/dist

COPY --from=build --chown=10001:10001 \
    /workspace/checkout/node_modules \
    /app/node_modules

COPY --from=build --chown=10001:10001 \
    /workspace/checkout/package.json \
    /app/package.json

COPY --chown=10001:10001 LICENSE /licenses/LICENSE
COPY --chown=10001:10001 checkout/ATTRIBUTION.md /licenses/ATTRIBUTION.md

LABEL org.opencontainers.image.title="retail-checkout" \
      org.opencontainers.image.source="https://github.com/ahmedmohsen5/01-retail-production-platform"

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["node", "dist/main"]