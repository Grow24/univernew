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

FROM zeabur/caddy-static:latest

COPY Caddyfile.zeabur /etc/caddy/Caddyfile
RUN cat /etc/caddy/Caddyfile
COPY --from=builder /src/examples/local /usr/share/caddy

EXPOSE 80
EXPOSE 8080
