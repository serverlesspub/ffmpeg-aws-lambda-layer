/*global module, require, console, Promise */
'use strict';
const childProcess = require('child_process'),
	spawnPromise = function (command, argsarray, envOptions) {
		return new Promise((resolve, reject) => {
			console.log('executing', command, argsarray.join(' '));
			const childProc = childProcess.spawn(command, argsarray, envOptions || {env: process.env, cwd: process.cwd()}),
				resultBuffers = [];
			childProc.stdout.on('data', buffer => {
				console.log(buffer.toString());
				resultBuffers.push(buffer);
			});
			childProc.stderr.on('data', buffer => console.error(buffer.toString()));
			childProc.on('exit', (code, signal) => {
				console.log(`${command} completed with ${code}:${signal}`);
				if (code || signal) {
					reject(`${command} failed with ${code || signal}`);
				} else {
					resolve(Buffer.concat(resultBuffers).toString().trim());
				}
			});
		});
	};
module.exports = {
	spawn: spawnPromise
};
