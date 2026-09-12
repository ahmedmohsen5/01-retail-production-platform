# syntax=docker/dockerfile:1.7
FROM golang:1.25.14-bookworm AS build

WORKDIR /workspace/catalog

COPY catalog/go.mod catalog/go.sum ./

RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY catalog/. .

RUN --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=1 go build -o /out/catalog main.go

FROM debian:bookworm-slim AS runtime

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 10001 app \
    && useradd -u 10001 -g 10001 --no-create-home --shell /usr/sbin/nologin app 

COPY --from=build --chown=10001:10001 /out/catalog /app/catalog
COPY --chown=10001:10001 LICENSE /licenses/LICENSE  
COPY --chown=10001:10001 catalog/ATTRIBUTION.md /licenses/ATTRIBUTION.md

LABEL org.opencontainers.image.title="retail-catalog" \
      org.opencontainers.image.source="https://github.com/ahmedmohsen5/01-retail-production-platform"

USER 10001:10001

EXPOSE 8080

ENTRYPOINT [ "/app/catalog" ]