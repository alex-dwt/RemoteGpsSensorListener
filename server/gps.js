/*
 * This file is part of the RemoteGpsSensorListener package.
 * (c) Alexander Lukashevich <aleksandr.dwt@gmail.com>
 * For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
 */

import {spawn} from 'child_process';

const PORT = 6100;
const DEVICE = '/dev/ttyACM0';
const IDLE_TIMEOUT = 90;
const PROPERTIES = ['lat', 'lon', 'speed', 'time'];

let idleTimeout;

export default class {
	constructor() {
		let daemon = spawn(
			'gpsd',
			['-S', PORT, DEVICE],
			{detached: true, stdio: ['ignore', 'ignore', 'ignore']}
		);
		daemon.unref();

		let proc = spawn(
			'gpspipe',
			['-l', '-w', `localhost:${PORT}`]
		);
		proc.stdout.setEncoding('utf8');
		proc.stdout.on('data', (data) => updateInfo.call(this, data));
		proc.on('close', () => updateInfo.call(this));

		updateInfo.call(this);
	}
}

function updateInfo(data) {
	clearTimeout(idleTimeout);
	idleTimeout = setTimeout(() => process.exit(1), IDLE_TIMEOUT * 1000);

	if (typeof data === 'undefined') {
		for (let prop of PROPERTIES) {
			this[prop] = null;
		}

		return;
	}

	try {
		let res = JSON.parse(data);
		if (typeof res['class'] !== 'undefined' &&
			res['class'].toLowerCase() === 'tpv'
		) {
			for (let prop of PROPERTIES) {
				this[prop] = (typeof res[prop] !== 'undefined' ? res[prop] : null);
			}
		}
	} catch (e) { }
}