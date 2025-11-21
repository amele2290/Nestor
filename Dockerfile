FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
# inside frontend/Dockerfile final stage
ENV NODE_ENV=production
CMD ["sh", "-c", "npx next start -p ${PORT:-3000}"]
