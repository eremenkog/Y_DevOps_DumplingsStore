FROM node:16-alpine as build
ARG VERSION=${VERSION}
ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV
WORKDIR /usr/src/app
COPY package*.json ./
COPY . .
RUN npm install \
    && npm run build

FROM nginx:latest as server
ARG VERSION=${VERSION}
WORKDIR /app
COPY --from=build /usr/src/app/dist/ /usr/share/nginx/html/
EXPOSE 80