FROM node:16

WORKDIR /app

COPY contracts/ /app/contracts
COPY migrations/ /app/migrations
COPY truffle-config.js /app/truffle-config.js

RUN npm install -g truffle && truffle compile

ENTRYPOINT [ "truffle" ]
CMD [ "migrate" ]