FROM --platform=$BUILDPLATFORM golang:alpine AS builder
WORKDIR /go/src/github.com/sagernet/sing-box
ARG TARGETOS TARGETARCH BRANCH
ENV CGO_ENABLED=0
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH

RUN set -ex \
  && apk add git build-base git \
  && git clone -b $BRANCH --single-branch https://github.com/sagernet/sing-box /go/src/github.com/sagernet/sing-box \
  && export VERSION=$(go run ./cmd/internal/read_tag) \
  && go build -v -trimpath -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_acme,with_clash_api,with_v2ray_api,with_gvisor \
    -o /go/bin/sing-box \
    -ldflags "-X \"github.com/sagernet/sing-box/constant.Version=$VERSION\" -s -w -buildid=" \
    ./cmd/sing-box

FROM --platform=$TARGETPLATFORM alpine AS dist
RUN set -ex \
  && apk upgrade \
  && apk add bash tzdata ca-certificates \
  && rm -rf /var/cache/apk/*

COPY --from=builder /go/bin/sing-box /usr/local/bin/sing-box
ENTRYPOINT [ "/usr/local/bin/sing-box" ]
