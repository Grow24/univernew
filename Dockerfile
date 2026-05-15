FROM node:22-alpine
LABEL "language"="nodejs"
LABEL "framework"="univer"

WORKDIR /src

RUN npm install -g pnpm@10.24.0

COPY . .

RUN pnpm run install:ci

RUN pnpm run build:static

FROM zeabur/caddy-static:latest

COPY Caddyfile.zeabur /etc/caddy/Caddyfile
# Echo in build logs so Zeabur confirms the shipped Caddyfile (debug port mismatch).
RUN cat /etc/caddy/Caddyfile
COPY --from=0 /src/examples/local /usr/share/caddy

EXPOSE 80
EXPOSE 8080