/*
 * Hollow House: the web player.
 *
 * Runs hollow.z3 in JSZM (a public-domain Z-machine) and draws it as a
 * retro horror game. The story file prints small cues between {{ and }}:
 *   {{face mother}} ... {{/face}}   a line spoken in a portrait dialog box
 *   {{scare}}                       a flash of the grin
 *   {{reset}}                       the night starts over
 *   {{end dawn}} / {{end dinner}}   an ending
 * Everything else the story prints goes into the log as plain text.
 */
(function() {
	'use strict';

	var SAVE_KEY = 'hollowHouseSave';
	var TYPE_MS = 12;          // per two letters in the log
	var DIALOG_TYPE_MS = 24;   // per two letters in a dialog box
	var LOOP_LENGTH = 45;

	var $ = function(s) { return document.querySelector(s); };
	var logEl = $('#log');
	var form = $('#prompt');
	var input = $('#cmd');
	var sceneCanvas = $('#scene');
	var dialogEl = $('#dialog');
	var portraitCanvas = $('#portrait');
	var grinCanvas = $('#grin');

	var game, runner;
	var outBuf = '';
	var history = [], histPos = 0;
	var busy = false;
	var skipTyping = false;

	// what the pictures need to know, pieced together from the story's own text
	var FRESH = {
		room: 'West of House', moves: 0, night: 1, dark: false, darkLevel: 0, lamp: false,
		motherKitchen: true, motherRadio: false, radioOn: false, juneFollow: false,
		rope: false, windowOpen: false, pantryOpen: false, rugMoved: false, trapOpen: false,
		juneDoorOpen: false, tookBox: false, tookLocket: false, ended: null
	};
	var st = Object.assign({}, FRESH);

	/* ---------- running the story ---------- */

	function boot() {
		fetch('hollow.z3').then(function(r) {
			if(!r.ok) throw new Error('could not load hollow.z3 (' + r.status + ')');
			return r.arrayBuffer();
		}).then(function(buf) {
			start(new Uint8Array(buf));
		}).catch(function(err) {
			addLine('The story file would not load: ' + err.message, 'error');
		});
	}

	function start(bytes) {
		game = new JSZM(bytes);
		game.print = function*(text) { outBuf += text; };
		game.read = function*() { return yield 'read'; };
		game.updateStatusLine = function*(room, moves, night) {
			if(room !== st.room) {
				st.room = room;
				st.dark = false;
				st.darkLevel = 0;
			}
			st.moves = moves;
			st.night = night;
			updateHud();
		};
		game.save = function*(buf) {
			try {
				localStorage.setItem(SAVE_KEY, JSON.stringify({ z: toB64(buf), st: st }));
				return true;
			} catch(e) {
				return false;
			}
		};
		game.restore = function*() {
			try {
				var saved = JSON.parse(localStorage.getItem(SAVE_KEY));
				if(!saved) return null;
				st = Object.assign({}, FRESH, saved.st);
				return fromB64(saved.z);
			} catch(e) {
				return null;
			}
		};
		game.restarted = function*() {
			st = Object.assign({}, FRESH);
		};
		runner = game.run();
		advance(undefined);
	}

	// runs the story until it asks for input (or ends), then shows what it printed
	function advance(line) {
		var r;
		try {
			r = runner.next(line);
		} catch(e) {
			addLine('The story stopped: ' + e.message, 'error');
			return;
		}
		var text = outBuf;
		outBuf = '';
		busy = true;
		setPromptEnabled(false);
		present(text).then(function() {
			busy = false;
			if(r.done) {
				if(!st.ended) showEnding('quit');
				return;
			}
			setPromptEnabled(true);
		});
	}

	form.addEventListener('submit', function(e) {
		e.preventDefault();
		if(busy) { skipTyping = true; return; }
		var line = input.value.trim();
		input.value = '';
		if(!line) return;
		history.push(line);
		histPos = history.length;
		addLine('> ' + line, 'echo');
		advance(line);
	});

	input.addEventListener('keydown', function(e) {
		if(e.key === 'ArrowUp' && histPos > 0) {
			histPos--;
			input.value = history[histPos];
			e.preventDefault();
		} else if(e.key === 'ArrowDown') {
			histPos = Math.min(history.length, histPos + 1);
			input.value = history[histPos] || '';
			e.preventDefault();
		}
	});

	document.querySelectorAll('[data-cmd]').forEach(function(b) {
		b.addEventListener('click', function() {
			if(busy || input.disabled) return;
			input.value = b.getAttribute('data-cmd');
			form.requestSubmit();
		});
	});

	// Enter, space or a click while text is typing shows the rest at once
	document.addEventListener('keydown', function(e) {
		if(busy && (e.key === 'Enter' || e.key === ' ' || e.key === 'Escape')) skipTyping = true;
	});
	logEl.addEventListener('click', function() { if(busy) skipTyping = true; });

	/* ---------- turning printed text into the screen ---------- */

	function present(text) {
		readCues(text);
		var parts = text.split(/(\{\{[^}]*\}\})/);
		var chain = Promise.resolve();
		var speaker = null, speech = '';
		parts.forEach(function(part) {
			var cue = part.match(/^\{\{(\/?)(\w+)\s*(\w*)\}\}$/);
			if(!cue) {
				if(speaker) {
					speech += part;
				} else if(part.trim()) {
					chain = chain.then(function() { return typeText(part); });
				}
				return;
			}
			var closing = cue[1] === '/', name = cue[2], arg = cue[3];
			if(name === 'face' && !closing) {
				speaker = arg;
				speech = '';
			} else if(name === 'face' && closing) {
				var who = speaker, said = speech;
				speaker = null;
				chain = chain.then(function() { return speak(who, said); });
			} else if(name === 'scare') {
				chain = chain.then(scare);
			} else if(name === 'reset') {
				chain = chain.then(rewind);
			} else if(name === 'end') {
				st.ended = arg;
				st.endText = text.replace(/\{\{[^}]*\}\}/g, '').replace(/>\s*$/, '').trim();
			}
		});
		return chain.then(function() {
			if(st.ended) showEnding(st.ended);
		});
	}

	// the pictures follow the story's text, never the game's hidden state
	function readCues(text) {
		var has = function(re) { return re.test(text); };
		if(has(/\{\{reset\}\}/)) {
			st = Object.assign({}, FRESH, { night: st.night, room: 'West of House' });
		}
		if(has(/pitch black/)) { st.dark = true; st.darkLevel = 0.15; }
		if(has(/closer now/)) { st.dark = true; st.darkLevel = 0.7; }
		if(has(/lamp catches/)) { st.lamp = true; st.dark = false; }
		if(has(/shrinks to a blue bead|wick down until|puts it back/)) st.lamp = false;
		if(has(/Mother isn't here/)) st.motherKitchen = false;
		if(has(/stands in front of the radio/)) { st.motherRadio = true; st.motherKitchen = false; st.radioOn = true; }
		if(has(/walks back into the kitchen|radio go quiet/)) { st.motherRadio = false; st.motherKitchen = true; st.radioOn = false; }
		if(has(/radio warms up/)) st.radioOn = true;
		if(has(/switch the radio off/)) st.radioOn = false;
		if(has(/takes hold of your sleeve/)) st.juneFollow = true;
		if(has(/rope hangs taut|rope runs straight down/)) st.rope = true;
		if(has(/comes up empty/)) st.rope = false;
		if(has(/wide enough to climb/)) st.windowOpen = true;
		if(has(/ease the window down/)) st.windowOpen = false;
		if(has(/Opening the pantry/)) st.pantryOpen = true;
		if(has(/drag the rug/)) st.rugMoved = true;
		if(has(/trap door comes up/)) { st.rugMoved = true; st.trapOpen = true; }
		if(has(/let the trap door down/)) st.trapOpen = false;
		if(has(/door opens a crack/)) st.juneDoorOpen = true;
		if(has(/^Taken\./m) && st.room === 'Root Cellar') {
			// the transcript doesn't say which, so look at what was asked for
			var last = (history[history.length - 1] || '').toLowerCase();
			if(/box|all/.test(last)) st.tookBox = true;
			if(/locket|necklace|all/.test(last)) st.tookLocket = true;
		}
	}

	function typeText(text) {
		var clean = text.replace(/\n>\s*$/, '').replace(/^>\s*$/gm, '').replace(/^\n+|\n+$/g, '');
		if(!clean.trim()) return Promise.resolve();
		var p = document.createElement('p');
		logEl.appendChild(p);
		return typeInto(p, clean, TYPE_MS).then(scrollLog);
	}

	function typeInto(el, text, ms) {
		skipTyping = false;
		return new Promise(function(done) {
			var i = 0;
			(function tick() {
				if(skipTyping || ms === 0) {
					el.textContent = text;
					scrollLog();
					return done();
				}
				i = Math.min(text.length, i + 2);
				el.textContent = text.slice(0, i);
				if(i % 40 === 0) scrollLog();
				if(i >= text.length) return done();
				setTimeout(tick, ms);
			})();
		});
	}

	function addLine(text, cls) {
		var p = document.createElement('p');
		if(cls) p.className = cls;
		p.textContent = text;
		logEl.appendChild(p);
		scrollLog();
	}

	function scrollLog() {
		logEl.scrollTop = logEl.scrollHeight;
	}

	/* ---------- dialog boxes ---------- */

	var talking = null;

	function speak(who, text) {
		text = text.replace(/\s+/g, ' ').trim();
		var name = who === 'mother' ? 'MOTHER' : who === 'june' ? 'JUNE' : '';
		dialogEl.hidden = false;
		$('#dialog-idle').hidden = true;
		dialogEl.className = 'dialog ' + who;
		$('#dialog-name').textContent = name;
		var body = $('#dialog-text');
		body.textContent = '';
		$('#dialog-more').hidden = true;
		grinCanvas.hidden = !(who === 'mother' && st.night >= 3);
		talking = who;
		drawDialog(performance.now());
		return typeInto(body, text, DIALOG_TYPE_MS).then(function() {
			talking = null;
			$('#dialog-more').hidden = false;
			return waitForAdvance();
		}).then(function() {
			dialogEl.hidden = true;
			$('#dialog-idle').hidden = false;
			grinCanvas.hidden = true;
			// the line goes into the log once it has been read, so the history reads in order
			addLine((name ? name + ':  ' : '') + text, 'speech ' + who);
		});
	}

	function waitForAdvance() {
		return new Promise(function(done) {
			function go(e) {
				if(e.type === 'keydown' && !(e.key === 'Enter' || e.key === ' ' || e.key === 'Escape')) return;
				if(e.type === 'keydown') e.preventDefault();
				document.removeEventListener('keydown', go, true);
				dialogEl.removeEventListener('click', go);
				done();
			}
			setTimeout(function() {
				document.addEventListener('keydown', go, true);
				dialogEl.addEventListener('click', go);
			}, 150);
		});
	}

	function drawDialog(t) {
		if(dialogEl.hidden) return;
		var who = dialogEl.classList.contains('mother') ? 'mother' : 'june';
		Art.drawPortrait(portraitCanvas, who, st.night, talking === who, t);
		if(!grinCanvas.hidden) Art.drawGrin(grinCanvas, st.night, t);
	}

	/* ---------- effects ---------- */

	function scare() {
		var el = $('#scare');
		Art.drawGrin($('#scare-grin'), Math.max(3, st.night + 1), Date.now());
		el.hidden = false;
		document.body.classList.add('shake');
		return wait(420).then(function() {
			el.hidden = true;
			document.body.classList.remove('shake');
		});
	}

	function rewind() {
		var el = $('#rewind');
		el.hidden = false;
		// the status line has already moved on to the new night by the time this plays
		$('#rewind-night').textContent = 'NIGHT ' + st.night;
		return wait(1500).then(function() {
			el.hidden = true;
			var sep = document.createElement('div');
			sep.className = 'night-break';
			sep.textContent = '3:00 AM  /  night ' + st.night;
			logEl.appendChild(sep);
			scrollLog();
		});
	}

	function showEnding(kind) {
		setPromptEnabled(false);
		var el = $('#ending');
		el.className = 'overlay ending ' + kind;
		var title = $('#ending-title'), sub = $('#ending-sub');
		if(kind === 'dawn') {
			title.textContent = '3:35 AM';
			sub.textContent = st.endText || 'You got her out.';
		} else if(kind === 'dinner') {
			title.textContent = 'DINNER IS SERVED';
			sub.textContent = st.endText || 'You stayed.';
		} else {
			title.textContent = 'THE END';
			sub.textContent = '';
		}
		setTimeout(function() { el.hidden = false; }, 1400);
	}

	function wait(ms) {
		return new Promise(function(r) { setTimeout(r, ms); });
	}

	/* ---------- the clock and the scene ---------- */

	function updateHud() {
		var m = Math.min(33, Math.floor(st.moves * 33 / LOOP_LENGTH));
		var clock = $('#clock');
		clock.textContent = '3:' + (m < 10 ? '0' : '') + m + ' AM';
		clock.classList.toggle('late', m >= 28);
		$('#night').textContent = 'NIGHT ' + st.night;
		$('#room').textContent = st.room;
		sceneCanvas.setAttribute('aria-label', 'Picture of ' + st.room);
	}

	var lastFrame = 0;
	function frame(t) {
		if(t - lastFrame > 110) {
			lastFrame = t;
			Art.drawScene(sceneCanvas, st, t);
			drawDialog(t);
			grain();
		}
		requestAnimationFrame(frame);
	}

	var grainCanvas = $('#grain');
	var grainCtx = grainCanvas.getContext('2d');
	grainCanvas.width = 160;
	grainCanvas.height = 100;
	var grainImg = grainCtx.createImageData(160, 100);
	var grainData = new Uint32Array(grainImg.data.buffer);
	function grain() {
		for(var i = 0; i < grainData.length; i++) {
			var v = Math.random() * 255 | 0;
			grainData[i] = ((40 << 24) | (v << 16) | (v << 8) | v) >>> 0;
		}
		grainCtx.putImageData(grainImg, 0, 0);
	}

	/* ---------- small things ---------- */

	function setPromptEnabled(on) {
		input.disabled = !on;
		form.classList.toggle('waiting', !on);
		if(on) input.focus({ preventScroll: true });
	}

	function toB64(u8) {
		var s = '';
		for(var i = 0; i < u8.length; i++) s += String.fromCharCode(u8[i]);
		return btoa(s);
	}

	function fromB64(b) {
		var s = atob(b), u8 = new Uint8Array(s.length);
		for(var i = 0; i < s.length; i++) u8[i] = s.charCodeAt(i);
		return u8;
	}

	$('#start').addEventListener('click', function() {
		$('#title').hidden = true;
		boot();
	});
	$('#again').addEventListener('click', function() { location.reload(); });
	$('#help-open').addEventListener('click', function() { $('#help').hidden = false; });
	$('#help-close').addEventListener('click', function() { $('#help').hidden = true; });

	updateHud();
	requestAnimationFrame(frame);
})();
