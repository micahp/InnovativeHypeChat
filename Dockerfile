# v0.7.8

# Base node image
FROM node:20-alpine AS deps
# Install jemalloc and build tools
RUN apk add --no-cache jemalloc python3 py3-pip uv
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
WORKDIR /app
# Copy package manifests only for better caching
COPY package*.json ./
COPY api/package*.json ./api/
COPY client/package*.json ./client/
COPY packages/data-provider/package*.json ./packages/data-provider/
COPY packages/data-schemas/package*.json ./packages/data-schemas/
COPY packages/mcp/package*.json ./packages/mcp/
# Install dependencies
RUN npm config set fetch-retry-maxtimeout 600000 && \
    npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 15000 && \
    npm ci --legacy-peer-deps

FROM node:20-alpine AS node
RUN apk add --no-cache jemalloc python3 py3-pip uv
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
WORKDIR /app
RUN mkdir -p /app && chown node:node /app
USER node
COPY --chown=node:node . .
COPY --chown=node:node --from=deps /app/node_modules ./node_modules
COPY --chown=node:node --from=deps /app/packages ./packages
COPY --chown=node:node --from=deps /app/api/node_modules ./api/node_modules
COPY --chown=node:node --from=deps /app/client/node_modules ./client/node_modules

RUN touch .env && \
    mkdir -p /app/client/public/images /app/api/logs && \
    NODE_OPTIONS="--max-old-space-size=2048" npm run frontend && \
    npm prune --production && npm cache clean --force

# Node API setup
EXPOSE 3080
ENV HOST=0.0.0.0
CMD ["npm", "run", "backend"]

# Optional: for client with nginx routing
# FROM nginx:stable-alpine AS nginx-client
# WORKDIR /usr/share/nginx/html
# COPY --from=node /app/client/dist /usr/share/nginx/html
# COPY client/nginx.conf /etc/nginx/conf.d/default.conf
# ENTRYPOINT ["nginx", "-g", "daemon off;"]