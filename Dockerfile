FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --only=production

COPY . .

USER node

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "server.js"]