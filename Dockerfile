FROM node:14.15.4-alpine
WORKDIR /app
COPY . .
RUN yarn
ENTRYPOINT ["npm", "run"]
CMD ["server"]
