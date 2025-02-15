# Build stage
FROM node:18 AS build

WORKDIR /opt/node_app

# Copy root workspace files
COPY package.json yarn.lock ./

# Create necessary directories
RUN mkdir -p excalidraw-app/scripts/woff2 \
    packages/excalidraw \
    packages/utils \
    packages/math

# Copy package.json files for all workspaces
COPY excalidraw-app/package.json ./excalidraw-app/
COPY packages/excalidraw/package.json ./packages/excalidraw/
COPY packages/utils/package.json ./packages/utils/
COPY packages/math/package.json ./packages/math/

# Copy scripts directory first (contains required build scripts)
COPY scripts ./scripts/
COPY excalidraw-app/scripts ./excalidraw-app/scripts/

# Install dependencies with frozen lockfile
RUN yarn install --frozen-lockfile --network-timeout 600000

# Copy remaining source files
COPY . .

# Copy env file to correct location
COPY .env.production ./excalidraw-app/.env.production

# Set production environment
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Disable husky during build
ENV HUSKY=0

# Build the application
RUN yarn build:app:docker

# Production stage
FROM nginx:1.25-alpine

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files from build stage
COPY --from=build /opt/node_app/excalidraw-app/build /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]