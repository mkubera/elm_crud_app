FROM node:12.0.0
WORKDIR /app
COPY . .
RUN npm install && npm run build
ENTRYPOINT npm start