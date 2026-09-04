# syntax=docker/dockerfile:1.7

FROM maven:3.9.16-eclipse-temurin-21 AS build

WORKDIR /workspace

COPY ui/pom.xml ui/pom.xml
COPY orders/openapi.yml orders/openapi.yaml
COPY cart/openapi.yml cart/openapi.yaml
COPY catalog/openapi.yml catalog/openapi.yml
COPY checkout/openapi.yml checkout/openapi.yaml
COPY recommendations/openapi.yml recommendations/openapi.yaml


WORKDIR /workspace/ui
RUN --mount=type=cache,target=/root/.m2 mvn -B dependency:go-offline

WORKDIR /workspace/
COPY ui/src ui/src

WORKDIR /workspace/ui
RUN --mount=type=cache,target=/root/.m2 mvn -B verify

FROM eclipse-temurin:21.0.12_8-jre-noble AS runtime

WORKDIR /app

RUN groupadd -g 10001 app \
    && useradd -u 10001 -g 10001 --no-create-home --shell /usr/sbin/nologin app

COPY --from=build --chown=10001:10001 /workspace/ui/target/ui-0.0.1-SNAPSHOT.jar /app/app.jar
COPY --chown=10001:10001 LICENSE /licenses/LICENSE
COPY --chown=10001:10001 ui/ATTRIBUTION.md /licenses/ATTRIBUTION.md

LABEL org.opencontainers.image.title="retail-ui" \
      org.opencontainers.image.source="https://github.com/ahmedmohsen5/01-retail-production-platform"

USER 10001:10001
EXPOSE 8080

ENTRYPOINT [ "java", "-jar", "/app/app.jar" ]