// config/defaults.js

module.exports = {
	serverPort: 8280,
	serverHost: "0.0.0.0",
	lndProto: __dirname + "/rpc.proto",
	lndHost: "lnd:10009",
	lndCertPath: "/config/tls.cert",
	macaroonPath: "/macaroons/admin.macaroon",
	dataPath: __dirname + "/../data",
	loglevel: "info",
	logfile: "lncliweb.log",
	lndLogFile: "/logs/lnd/lnd.log"
};