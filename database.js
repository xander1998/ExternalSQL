const mysql = require("mysql");
const config = require("./config.json");
const devmode = config.devmodeactive;

const pool = mysql.createPool(config.database);

function SendQuery(query, data) {
  return new Promise((resolve) => {
    pool.getConnection((error, connection) => {
      if (!error) {
        connection.query(query, data, (error, data, fields) => {
          if (!error) {
            let returned_data = {}
            let meta_data = {}

            if (query.includes("SELECT")) {
              meta_data = { affectedRows: null, insertId: null, changedRows: null }
              returned_data = { ok: true, results: data, meta: meta_data }
            } else if (query.includes("DELETE") || query.includes("UPDATE") || query.includes("INSERT")) {
              meta_data = { affectedRows: data.affectedRows, insertId: data.insertId, changedRows: data.changedRows }
              returned_data = { ok: true, results: [], meta: meta_data }
            } else {
              returned_data = { ok: true, results: [], meta: meta_data }
            }

            resolve(returned_data);
          } else {
            resolve({ ok: false, results: [], meta: {}, error });
          }
        })
      } else {
        resolve({ ok: false, results: [], meta: {}, error });
      }
      connection.release()
    })
  })
}

pool.on("connection", (connection) => {
	connection.config.queryFormat = function (query, values) {
      if (!values) return query;
      return query.replace(/\:(\w+)/g, function (txt, key) {
          if (values.hasOwnProperty(key)) {
              return this.escape(values[key]);
          }
          return txt;
      }.bind(this));
  };
  if (devmode) {
    console.log(`Connection: ${connection.threadId}`);
  }
});

pool.on("acquire", (connection) => {
	if (devmode) {
    console.log(`Connection Acquired: ${connection.threadId}`);
    DisplayConnections()
  }
});

pool.on("enqueue", () => {
  if (devmode) {
    console.log("Waiting for available connection slot");
  }
})

pool.on("release", (connection) => {
	if (devmode) {
    console.log(`Connection Released: ${connection.threadId}`);
    DisplayConnections()
  }
})

function DisplayConnections() {
	console.log(`Acquiring Connections: ${pool._acquiringConnections.length}`);
	console.log("------------------------------------------------")
	console.log(`All Connections: ${pool._allConnections.length}`);
	console.log("------------------------------------------------")
	console.log(`Free Connections: ${pool._freeConnections.length}`);
	console.log("------------------------------------------------")
	console.log(`Connections Queued: ${pool._connectionQueue.length}`);
	console.log("------------------------------------------------")
}

module.exports = SendQuery;

console.log("[ExternalSQL Message] : Loaded 'database.js'");