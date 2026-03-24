# Standalone hoppers-server: single container, no external dependencies
# Uses PGlite (embedded Postgres), local filesystem storage, no Redis

# Stage 1: install dependencies
FROM node:20 AS deps

RUN apt-get update && apt-get install -y python3 make g++ build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /repo

COPY package.json yarn.lock ./
COPY scripts ./scripts
COPY patches ./patches

RUN mkdir -p packages/hoppers-app packages/hoppers-server packages/hoppers-cli packages/hoppers-agent packages/hoppers-wire

COPY packages/hoppers-app/package.json packages/hoppers-app/
COPY packages/hoppers-server/package.json packages/hoppers-server/
COPY packages/hoppers-cli/package.json packages/hoppers-cli/
COPY packages/hoppers-agent/package.json packages/hoppers-agent/
COPY packages/hoppers-wire/package.json packages/hoppers-wire/

# Workspace postinstall requirements
COPY packages/hoppers-app/patches packages/hoppers-app/patches
COPY packages/hoppers-server/prisma packages/hoppers-server/prisma
COPY packages/hoppers-cli/scripts packages/hoppers-cli/scripts
COPY packages/hoppers-cli/tools packages/hoppers-cli/tools

RUN SKIP_HOPPERS_WIRE_BUILD=1 yarn install --frozen-lockfile --ignore-engines

# Stage 2: copy source and type-check
FROM deps AS builder

COPY packages/hoppers-wire ./packages/hoppers-wire
COPY packages/hoppers-server ./packages/hoppers-server

RUN yarn workspace @hoppers-app/hoppers-wire build
RUN yarn workspace hoppers-server build

# Stage 3: runtime
FROM node:20-slim AS runner

WORKDIR /repo

RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production
ENV DATA_DIR=/data
ENV PGLITE_DIR=/data/pglite

COPY --from=builder /repo/node_modules /repo/node_modules
COPY --from=builder /repo/packages/hoppers-wire /repo/packages/hoppers-wire
COPY --from=builder /repo/packages/hoppers-server /repo/packages/hoppers-server

VOLUME /data
EXPOSE 3005

CMD ["sh", "-c", "node_modules/.bin/tsx packages/hoppers-server/sources/standalone.ts migrate && exec node_modules/.bin/tsx packages/hoppers-server/sources/standalone.ts serve"]
