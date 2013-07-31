var winston = require('winston');

var logger = new (winston.Logger)({
	transports:[
		new (winston.transports.Console)({
			level: 'info'
		}),
		new (winston.transports.File)({
			name: 'file#all',
			filename: "out.log",
			level:'info',
			json: false
		}),
		new (winston.transports.File)({
			name: 'file#error',
			filename: "err.log",
			level: 'debug',
			json: false
		})
	]
});

module.exports = logger;
