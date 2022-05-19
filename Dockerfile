FROM node:16

WORKDIR /app

COPY contracts /app/
COPY migrations /app/
COPY truffle-config.js /app/

RUN npm install -g truffle && truffle compile

ENTRYPOINT [ "truffle" ]
CMD [ "migrate" ]