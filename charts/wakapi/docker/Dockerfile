# Wakapi — patched image for zoneinfo directory permissions
#
# Upstream v2.17.2 ships /usr/share/zoneinfo with 0444 permissions,
# which prevents Go's time.LoadLocation() from traversing directories.
# This causes timezone validation to fail on the settings page.
#
# Fix: muety/wakapi#923 (merged to main, not yet released)
# We rebuild from source at the fixed commit to include the fix.

FROM --platform=$BUILDPLATFORM golang:alpine AS build-env
WORKDIR /src

RUN apk add --no-cache ca-certificates tzdata git && update-ca-certificates

# Clone at the fix commit (includes #923 zoneinfo chmod fix)
ARG WAKAPI_REF=f5cb4696
RUN git clone --depth 50 https://github.com/muety/wakapi.git . \
 && git checkout ${WAKAPI_REF}

RUN go mod download

ARG TARGETOS
ARG TARGETARCH
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0 GOEXPERIMENT=jsonv2 go build -ldflags "-s -w" -v -o wakapi main.go
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0 go build -ldflags "-s -w" -v -o healthcheck scripts/healthcheck.go

WORKDIR /staging
RUN mkdir ./data ./app && \
    cp /src/wakapi app/ && \
    cp /src/healthcheck app/ && \
    cp /src/config.default.yml app/config.yml && \
    sed -i 's/listen_ipv6: ::1/listen_ipv6: "-"/g' app/config.yml

# Run Stage
FROM gcr.io/distroless/static:nonroot
WORKDIR /app

ENV ENVIRONMENT=prod \
    WAKAPI_DB_TYPE=sqlite3 \
    WAKAPI_DB_USER='' \
    WAKAPI_DB_PASSWORD='' \
    WAKAPI_DB_HOST='' \
    WAKAPI_DB_NAME=/data/wakapi.db \
    WAKAPI_PASSWORD_SALT='' \
    WAKAPI_LISTEN_IPV4='0.0.0.0' \
    WAKAPI_INSECURE_COOKIES='true' \
    WAKAPI_ALLOW_SIGNUP='true'

COPY --from=build-env --chown=nonroot:nonroot --chmod=0444 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build-env --chown=nonroot:nonroot --chmod=0555 /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=build-env --chown=nonroot:nonroot /staging/app /app
COPY --from=build-env --chown=nonroot:nonroot /staging/data /data

LABEL org.opencontainers.image.url="https://github.com/muety/wakapi" \
    org.opencontainers.image.documentation="https://github.com/muety/wakapi" \
    org.opencontainers.image.source="https://github.com/sm-moshi/helm-charts" \
    org.opencontainers.image.title="Wakapi (patched)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.description="Wakapi with zoneinfo fix (muety/wakapi#923)"

USER nonroot

EXPOSE 3000

HEALTHCHECK --interval=60s --timeout=3s --start-period=120s --retries=3 CMD ["/app/healthcheck"]

ENTRYPOINT ["/app/wakapi"]
