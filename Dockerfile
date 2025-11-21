FROM node:18-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --production=false
COPY . .
# If using Prisma ensure client generated during build
RUN if [ -f prisma/schema.prisma ]; then npx prisma generate; fi
RUN npm run build
RUN chmod +x ./entrypoint.sh
ENV NODE_ENV=production
# Expose optional
EXPOSE 10000
CMD ["./entrypoint.sh"]
