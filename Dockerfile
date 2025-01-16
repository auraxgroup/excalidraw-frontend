# Build stage
FROM node:18 AS build

WORKDIR /opt/node_app

# Copy package files first for better caching
COPY package.json yarn.lock ./

# Install dependencies with frozen lockfile
RUN yarn install --frozen-lockfile --network-timeout 600000

# Copy source files
COPY . .

# Copy env file
COPY .env.production .env.production

# Set production environment
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Build the application
RUN yarn build:app

# Production stage
FROM nginx:1.25-alpine

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files from build stage
COPY --from=build /opt/node_app/build /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]