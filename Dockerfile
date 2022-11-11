FROM node:16

WORKDIR /app

COPY . .

RUN npm install -g truffle@5.5.14 && npm i && truffle compile

ENTRYPOINT [ "truffle" ]
CMD [ "migrate" ]