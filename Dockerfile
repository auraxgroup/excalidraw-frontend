FROM node:18 AS build

WORKDIR /opt/node_app

# Copy package files
COPY package.json yarn.lock ./

# Copy env files
COPY .env.production .env.production

# Copy source files
COPY . .

# Install dependencies with frozen lockfile
RUN yarn install --frozen-lockfile --network-timeout 600000

# Build for production
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

RUN yarn build:app:docker

# Production image
FROM nginx:1.25-alpine

# Copy custom nginx config if needed
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files
COPY --from=build /opt/node_app/excalidraw-app/build /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -q -O /dev/null http://localhost || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]