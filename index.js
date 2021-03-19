const express = require("express");
const app = express();
const bodyParser = require("body-parser");
const configLoader = require("./config.js");

configLoader.load();
const config = configLoader.data;

// APP USE BODYPARSER JSON
app.use(bodyParser.json())

// ROUTES FILE
require("./routes")(app);

// APP LISTENER
app.listen(config.api.port, "localhost", (req, res) => {
  setImmediate(() => {
    emit('ExternalSQL:APIReady');
  })
  console.log(`API Server Listening On Port: ${config.api.port}`)
})

console.log("[ExternalSQL Message] : Loaded 'index.js'");