const express = require("express");
const app = express();
const bodyParser = require("body-parser");
const config = require("./config.json");

// APP USE BODYPARSER JSON
app.use(bodyParser.json())

// ROUTES FILE
require("./routes")(app);

// APP LISTENER
app.listen(config.api.port, (req, res) => {
  console.log(`API Server Listening On Port: ${config.api.port}`)
})

console.log("[ExternalSQL Message] : Loaded 'index.js'");