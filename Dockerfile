FROM node:24 AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build


FROM node:24-slim

WORKDIR /usr/app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=build /app/dist /usr/app/dist

EXPOSE 3000

CMD ["node", "dist/main"]