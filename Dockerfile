# Multi-stage: build static demo in Node, serve with Zeabur's Caddy image.
# Do not drop Caddyfile.zeabur or :80 — Zeabur's startup probe often hits container port 80.
# Do not drop UNIVER_ASSET_BASE=/ — root domains need chunks at / not /univer/ (see examples/esbuild.config.ts).
FROM node:22-alpine AS builder
LABEL "language"="nodejs"
LABEL "framework"="univer"

WORKDIR /src

RUN npm install -g pnpm@10.24.0

COPY . .

RUN pnpm run install:ci

ENV UNIVER_ASSET_BASE=/
ENV NODE_OPTIONS="--max-old-space-size=6144"
# Production bundling; set only after install so devDependencies remain available for the build.
ENV NODE_ENV=production

RUN pnpm run build:static:zeabur

# Fail the image build if chunks still reference /univer/ (blank page on Zeabur root domain).
RUN ! grep -q '"/univer/' /src/examples/local/sheets/main.js \
    || (echo 'ERROR: sheets/main.js still uses /univer/ — set UNIVER_ASSET_BASE=/' && exit 1)

FROM zeabur/caddy-static:latest

COPY Caddyfile.zeabur /etc/caddy/Caddyfile
RUN cat /etc/caddy/Caddyfile
COPY --from=builder /src/examples/local /usr/share/caddy
COPY examples/_redirects.zeabur /usr/share/caddy/_redirects

EXPOSE 80
EXPOSE 8080
