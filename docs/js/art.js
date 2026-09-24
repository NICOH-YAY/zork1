/*
 * Hollow House: the pictures.
 *
 * Every scene and portrait is drawn in code into a small framebuffer and
 * scaled up with hard pixel edges. Nothing here is an image file. The palette
 * is a handful of greens with bone, one yellow (June) and one red.
 */
var Art = (function() {
	var P = {
		void: '#040605', deep: '#08130d', dark: '#0f2518', mid: '#1f4430',
		moss: '#3d6a45', sick: '#6f9460', pale: '#a8c398', bone: '#ddd5b0',
		yellow: '#ecc94b', amber: '#9c7426', red: '#8a1c1c', gum: '#4a1216',
		skin: '#b7c79c', skinShade: '#7d9170', dress: '#2f6b3b', dressDark: '#1b4226'
	};
	var BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]];

	// colors as little-endian ABGR ints for the framebuffer
	var INT = {};
	Object.keys(P).forEach(function(k) {
		var h = P[k];
		var r = parseInt(h.substr(1, 2), 16), g = parseInt(h.substr(3, 2), 16), b = parseInt(h.substr(5, 2), 16);
		INT[k] = ((255 << 24) | (b << 16) | (g << 8) | r) >>> 0;
	});

	function Surface(w, h) {
		this.w = w;
		this.h = h;
		this.buf = new Uint32Array(w * h);
	}

	Surface.prototype = {
		px: function(c, x, y) {
			x = x | 0; y = y | 0;
			if(x < 0 || y < 0 || x >= this.w || y >= this.h) return;
			this.buf[y * this.w + x] = INT[c];
		},
		rect: function(c, x, y, w, h) {
			for(var yy = Math.max(0, y | 0); yy < Math.min(this.h, (y + h) | 0); yy++) {
				for(var xx = Math.max(0, x | 0); xx < Math.min(this.w, (x + w) | 0); xx++) {
					this.buf[yy * this.w + xx] = INT[c];
				}
			}
		},
		// fills with c1, and c2 where the ordered-dither threshold is under t(x, y)
		dither: function(c1, c2, x, y, w, h, t) {
			for(var yy = y; yy < y + h; yy++) {
				for(var xx = x; xx < x + w; xx++) {
					var v = typeof t === 'function' ? t(xx, yy) : t;
					this.px(BAYER[yy & 3][xx & 3] / 16 < v ? c2 : c1, xx, yy);
				}
			}
		},
		vgrad: function(c1, c2, x, y, w, h) {
			this.dither(c1, c2, x, y, w, h, function(xx, yy) { return (yy - y) / h; });
		},
		line: function(c, x0, y0, x1, y1) {
			x0 = x0 | 0; y0 = y0 | 0; x1 = x1 | 0; y1 = y1 | 0;
			var dx = Math.abs(x1 - x0), dy = -Math.abs(y1 - y0);
			var sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, err = dx + dy;
			for(var guard = 0; guard < 1000; guard++) {
				this.px(c, x0, y0);
				if(x0 === x1 && y0 === y1) break;
				var e2 = 2 * err;
				if(e2 >= dy) { err += dy; x0 += sx; }
				if(e2 <= dx) { err += dx; y0 += sy; }
			}
		},
		disc: function(c, cx, cy, r) {
			for(var y = -r; y <= r; y++) {
				for(var x = -r; x <= r; x++) {
					if(x * x + y * y <= r * r + r * 0.6) this.px(c, cx + x, cy + y);
				}
			}
		},
		ring: function(c, cx, cy, r) {
			for(var a = 0; a < Math.PI * 2; a += 0.5 / r) {
				this.px(c, cx + Math.round(Math.cos(a) * r), cy + Math.round(Math.sin(a) * r));
			}
		},
		// darkens everything outside a circle of light (the lamp)
		lightRadius: function(cx, cy, r, flicker) {
			var rr = r + flicker;
			for(var y = 0; y < this.h; y++) {
				for(var x = 0; x < this.w; x++) {
					var d = Math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
					if(d > rr) {
						var t = Math.min(1, (d - rr) / 10);
						if(BAYER[y & 3][x & 3] / 16 < t) this.buf[y * this.w + x] = INT.void;
					}
				}
			}
		},
		blit: function(canvas) {
			if(canvas.width !== this.w) { canvas.width = this.w; canvas.height = this.h; }
			var g = canvas.getContext('2d');
			var img = g.createImageData(this.w, this.h);
			new Uint32Array(img.data.buffer).set(this.buf);
			g.putImageData(img, 0, 0);
		}
	};

	/* ---------- pieces used by more than one scene ---------- */

	function nightSky(s, t, h) {
		s.vgrad('void', 'deep', 0, 0, s.w, h);
		// a thin moon
		s.disc('pale', 132, 14, 6);
		s.disc('void', 135, 12, 6);
		// a few stars that do not move
		var seed = 7;
		for(var i = 0; i < 26; i++) {
			seed = (seed * 9301 + 49297) % 233280;
			var x = seed % s.w;
			seed = (seed * 9301 + 49297) % 233280;
			var y = seed % Math.max(1, h - 20);
			if((i + Math.floor(t / 900)) % 7 !== 0) s.px(i % 5 ? 'mid' : 'pale', x, y);
		}
	}

	function treeline(s, y, c) {
		for(var x = 0; x < s.w; x++) {
			var top = y - 4 - Math.round(Math.abs(Math.sin(x * 0.37) * 6 + Math.sin(x * 0.11) * 5));
			s.rect(c, x, top, 1, s.h - top);
			// a lighter edge along the tops so the trees read against the sky
			if(x % 2 === 0) s.px('mid', x, top);
		}
		// low fog along the tree line
		s.dither('dark', 'mid', 0, y - 2, s.w, 4, 0.18);
	}

	function grass(s, y, t) {
		s.dither('dark', 'mid', 0, y, s.w, s.h - y, function(xx, yy) { return 0.15 + (yy - y) / (s.h - y) * 0.4; });
		for(var x = 1; x < s.w; x += 3) {
			var sway = Math.round(Math.sin(t / 700 + x) * 0.6);
			s.px('moss', x + sway, y + ((x * 7) % 5));
		}
	}

	function house(s, x, y, w, h, opts) {
		s.rect('pale', x, y, w, h);
		s.dither('pale', 'sick', x, y, w, h, 0.18);
		// roof
		for(var i = 0; i <= h * 0.6; i++) {
			s.rect('dark', x - 3 + i, y - i, w + 6 - i * 2, 1);
		}
		s.rect('mid', x, y, w, 1);
		if(opts.door) {
			var dx = x + (w >> 1) - 4;
			s.rect('dark', dx, y + h - 14, 8, 14);
			for(var b = 0; b < 3; b++) s.line('amber', dx - 1, y + h - 12 + b * 4, dx + 8, y + h - 10 + b * 4);
		}
		(opts.windows || []).forEach(function(wd) {
			if(wd.lit) {
				var f = wd.flicker || 0;
				s.rect(f > 0.93 ? 'amber' : 'yellow', wd.x, wd.y, 6, 7);
				if(wd.shadow) s.rect('amber', wd.x + 2, wd.y + 2, 2, 5);
				s.line('amber', wd.x + 3, wd.y, wd.x + 3, wd.y + 6);
			} else {
				s.rect('dark', wd.x, wd.y, 6, 7);
				s.line('amber', wd.x - 1, wd.y + 2, wd.x + 6, wd.y + 4);
				s.line('amber', wd.x - 1, wd.y + 5, wd.x + 6, wd.y + 3);
			}
		});
	}

	// Mother seen from behind: green dress, dark hair in a bun
	function motherBack(s, x, y, sway) {
		x += Math.round(sway || 0);
		s.rect('dressDark', x - 5, y + 10, 11, 20);
		s.rect('dress', x - 4, y + 10, 9, 19);
		s.rect('dressDark', x - 6, y + 12, 2, 10);
		s.rect('dressDark', x + 5, y + 12, 2, 10);
		s.rect('skinShade', x - 1, y + 7, 3, 3);
		s.disc('void', x, y + 3, 4);
		s.disc('deep', x, y - 1, 2);
	}

	function juneSmall(s, x, y) {
		s.rect('yellow', x - 3, y + 7, 7, 9);
		s.rect('amber', x - 3, y + 15, 7, 1);
		s.rect('skin', x - 2, y + 16, 1, 4);
		s.rect('skin', x + 2, y + 16, 1, 4);
		s.disc('skin', x, y + 3, 3);
		s.rect('void', x - 3, y - 1, 7, 3);
		s.px('void', x - 1, y + 3);
		s.px('void', x + 1, y + 3);
	}

	// packed earth walls and floor, for the rooms under the house
	function earth(s) {
		s.dither('deep', 'dark', 0, 0, s.w, 64, function(x, y) { return 0.35 + Math.sin(x * 0.7 + y * 1.3) * 0.15; });
		s.dither('dark', 'amber', 0, 64, s.w, 36, function(x, y) { return 0.08 + (y - 64) / 36 * 0.14; });
		for(var i = 0; i < 40; i++) s.px('mid', (i * 37) % s.w, (i * 23) % 60);
	}

	// the grin that lives in the dark. size grows from 0 to 1
	function darkGrin(s, cx, cy, size, t) {
		if(size <= 0) return;
		var w = Math.round(10 + size * 40), h = Math.round(2 + size * 5);
		var jitter = Math.round(Math.sin(t / 90) * size);
		for(var x = -w; x <= w; x++) {
			var curve = Math.round((x * x) / (w * w) * -h);
			var yy = cy + curve + jitter;
			s.px('gum', cx + x, yy - 1);
			if(Math.abs(x) % 3 !== 0) {
				s.px('bone', cx + x, yy);
				if(size > 0.4) s.px('bone', cx + x, yy + 1);
			}
			s.px('gum', cx + x, yy + 2);
		}
	}

	/* ---------- the rooms ---------- */

	var SCENES = {
		'West of House': function(s, st, t) {
			nightSky(s, t, 60);
			treeline(s, 62, 'deep');
			house(s, 52, 34, 56, 34, {
				door: true,
				windows: [
					{ x: 60, y: 40 },
					{ x: 95, y: 40, lit: true, flicker: Math.random(), shadow: Math.sin(t / 1300) > 0.85 },
					{ x: 60, y: 54 },
					{ x: 95, y: 54 }
				]
			});
			grass(s, 68, t);
			// mailbox
			s.rect('amber', 30, 74, 1, 10);
			s.rect('mid', 26, 70, 9, 5);
			s.rect('red', 34, 67, 1, 4);
			// the track west
			s.dither('dark', 'moss', 0, 84, 30, 16, 0.3);
		},
		'North of House': function(s, st, t) {
			nightSky(s, t, 58);
			treeline(s, 60, 'deep');
			house(s, 28, 30, 104, 40, { windows: [{ x: 44, y: 38 }, { x: 80, y: 38 }, { x: 110, y: 38 }, { x: 60, y: 54 }] });
			grass(s, 70, t);
			// swing set, the left swing moves from the second night on
			s.line('amber', 118, 64, 124, 90);
			s.line('amber', 150, 64, 144, 90);
			s.line('amber', 118, 64, 150, 64);
			var swing = st.night > 1 ? Math.round(Math.sin(t / 520) * 5) : 0;
			s.line('mid', 126, 64, 126 + swing, 84);
			s.line('mid', 131, 64, 131 + swing, 84);
			s.rect('amber', 125 + swing, 84, 7, 1);
			s.line('mid', 137, 64, 137, 84);
			s.line('mid', 142, 64, 142, 84);
			s.rect('amber', 136, 84, 7, 1);
		},
		'Behind House': function(s, st, t) {
			nightSky(s, t, 50);
			house(s, 20, 26, 120, 50, { windows: [{ x: 40, y: 34 }, { x: 112, y: 34 }] });
			// the kitchen window, warm and lit
			var open = st.windowOpen;
			s.rect('yellow', 72, 46, 18, 14);
			s.dither('yellow', 'amber', 72, 46, 18, 14, 0.25 + Math.random() * 0.08);
			if(st.motherKitchen) motherBack(s, 81, 47, Math.sin(t / 600));
			s.rect('mid', 71, open ? 42 : 45, 20, 2);
			s.rect('mid', 71, 60, 20, 2);
			grass(s, 76, t);
			treeline(s, 100, 'deep');
		},
		'The Well': function(s, st, t) {
			nightSky(s, t, 56);
			treeline(s, 58, 'deep');
			grass(s, 62, t);
			// stones
			s.rect('mid', 56, 66, 48, 20);
			s.dither('mid', 'sick', 56, 66, 48, 20, 0.35);
			for(var i = 0; i < 6; i++) s.line('dark', 56 + i * 8, 66, 56 + i * 8, 86);
			s.rect('void', 60, 64, 40, 4);
			// winch posts
			s.rect('amber', 58, 36, 2, 30);
			s.rect('amber', 100, 36, 2, 30);
			s.rect('amber', 58, 36, 44, 2);
			s.rect('amber', 76, 38, 8, 3);
			if(st.rope) {
				s.line('bone', 80, 41, 80, 66);
			} else {
				s.line('bone', 80, 41, 80, 48);
				s.rect('amber', 76, 48, 8, 7);
				s.rect('mid', 76, 50, 8, 1);
			}
		},
		'Kitchen': function(s, st, t) {
			s.rect('deep', 0, 0, s.w, s.h);
			s.dither('dark', 'mid', 0, 0, s.w, 70, 0.2);
			// floor
			s.dither('dark', 'deep', 0, 70, s.w, 30, 0.5);
			// stove and pot, with steam
			s.rect('void', 96, 50, 36, 22);
			s.rect('red', 102, 48, 6, 2);
			s.rect('mid', 104, 38, 22, 11);
			s.rect('sick', 104, 38, 22, 2);
			for(var i = 0; i < 5; i++) {
				var sy = 36 - ((t / 60 + i * 7) % 26);
				s.px('pale', 110 + i * 3 + Math.round(Math.sin(t / 300 + i) * 2), sy);
			}
			// table set for four
			s.rect('amber', 14, 62, 50, 3);
			s.rect('amber', 18, 65, 2, 14);
			s.rect('amber', 58, 65, 2, 14);
			for(var b = 0; b < 4; b++) s.rect('bone', 18 + b * 11, 60, 7, 2);
			// pantry door
			s.rect('amber', 70, 22, 14, 48);
			s.rect(st.pantryOpen ? 'void' : 'dark', 71, 23, 12, 46);
			// the window over the sink
			s.rect('void', 30, 18, 20, 16);
			s.rect('mid', 30, st.windowOpen ? 14 : 17, 20, 2);
			if(st.motherKitchen) motherBack(s, 114, 38, Math.sin(t / 500) * 0.8);
		},
		'Living Room': function(s, st, t) {
			s.rect('deep', 0, 0, s.w, s.h);
			s.dither('deep', 'dark', 0, 0, s.w, 72, 0.35);
			s.dither('dark', 'void', 0, 72, s.w, 28, 0.4);
			// grandfather clock
			s.rect('amber', 16, 20, 14, 54);
			s.rect('void', 18, 22, 10, 10);
			s.ring('bone', 23, 27, 4);
			var a = (st.moves / 45) * Math.PI * 2 - Math.PI / 2;
			s.line('bone', 23, 27, 23 + Math.round(Math.cos(a) * 3), 27 + Math.round(Math.sin(a) * 3));
			s.rect('void', 20, 38, 6, 30);
			s.px('amber', 23, 60);
			// radio
			s.rect('amber', 120, 50, 26, 22);
			s.rect('dark', 123, 53, 20, 10);
			s.ring(st.radioOn ? 'yellow' : 'mid', 133, 66, 3);
			if(st.radioOn) {
				for(var n = 0; n < 3; n++) {
					var ny = 44 - ((t / 90 + n * 9) % 22);
					s.px('yellow', 128 + n * 6 + Math.round(Math.sin(t / 200 + n) * 2), ny);
				}
			}
			// mantel with the photograph
			s.rect('amber', 56, 40, 40, 3);
			s.rect('bone', 70, 30, 12, 10);
			s.rect('mid', 71, 31, 10, 8);
			for(var f = 0; f < 4; f++) s.px(f === 2 && st.night > 1 ? 'void' : 'skin', 72 + f * 2, 34);
			// rug and trap door
			if(st.trapOpen) {
				s.rect('void', 64, 80, 26, 12);
				s.line('amber', 64, 80, 70, 70);
				s.rect('amber', 68, 68, 26, 2);
			} else if(st.rugMoved) {
				s.rect('amber', 66, 80, 22, 10);
				s.ring('bone', 77, 85, 2);
				s.dither('red', 'amber', 96, 82, 30, 10, 0.5);
			} else {
				s.dither('red', 'amber', 58, 80, 44, 12, 0.5);
			}
			// stairs going up on the right
			for(var k = 0; k < 6; k++) s.rect('amber', 144 + k * 2, 70 - k * 8, 16, 2);
			if(st.motherRadio) motherBack(s, 108, 42, Math.sin(t / 450) * 2);
		},
		'Upstairs Hall': function(s, st, t) {
			s.rect('void', 0, 0, s.w, s.h);
			// corridor in perspective
			for(var i = 0; i < 40; i++) {
				var c = i < 14 ? 'deep' : 'dark';
				s.rect(c, 40 + i, 10 + i / 2, s.w - 80 - i * 2, 1);
			}
			s.dither('dark', 'mid', 40, 30, 80, 60, 0.15);
			s.line('mid', 0, 0, 40, 30);
			s.line('mid', s.w, 0, 120, 30);
			s.line('mid', 0, s.h, 40, 90);
			s.line('mid', s.w, s.h, 120, 90);
			// June's yellow door, north
			if(!st.juneDoorOpen) {
				s.rect('amber', 68, 38, 24, 52);
				s.rect('yellow', 70, 40, 20, 48);
				// the paper star
				s.px('bone', 80, 48); s.line('bone', 77, 50, 83, 50); s.px('bone', 78, 52); s.px('bone', 82, 52); s.px('bone', 80, 51);
				s.px('void', 88, 64);
			} else {
				s.rect('void', 68, 38, 24, 52);
				s.rect('yellow', 70, 40, 3, 50);
			}
			// light under the door
			s.rect('yellow', 68, 90, 24, 1);
		},
		"June's Room": function(s, st, t) {
			s.rect('deep', 0, 0, s.w, s.h);
			// slanted ceiling
			for(var i = 0; i < 30; i++) s.rect('void', 0, i, 60 - i * 2, 1);
			s.dither('dark', 'deep', 0, 70, s.w, 30, 0.4);
			// drawings, many, crooked
			for(var d = 0; d < 9; d++) {
				var dx = 64 + (d % 5) * 18, dy = 14 + Math.floor(d / 5) * 20;
				s.rect('bone', dx, dy, 12, 14);
				s.line(d % 3 ? 'dress' : 'red', dx + 2, dy + 10, dx + 9, dy + 9);
				s.px('yellow', dx + 5, dy + 4);
			}
			// the bed and the moon night light
			s.rect('amber', 14, 64, 44, 4);
			s.rect('bone', 16, 58, 40, 6);
			s.disc('yellow', 70, 70, 3);
			s.disc('deep', 72, 69, 2);
			if(!st.juneFollow) juneSmall(s, 36, 42);
		},
		"Parents' Room": function(s, st, t) {
			s.rect('deep', 0, 0, s.w, s.h);
			s.dither('deep', 'dark', 0, 0, s.w, 70, 0.3);
			s.dither('dark', 'void', 0, 70, s.w, 30, 0.35);
			// the bed, made tight
			s.rect('bone', 20, 58, 70, 14);
			s.rect('pale', 20, 58, 70, 2);
			s.rect('amber', 18, 50, 4, 26);
			// nightstand
			s.rect('amber', 96, 58, 16, 16);
			s.rect('dark', 98, 62, 12, 4);
			// mirror
			s.rect('amber', 124, 18, 24, 58);
			s.vgrad('mid', 'dark', 126, 20, 20, 54);
			if(st.night > 1 && (t % 5000) < 500) {
				s.rect('dress', 132, 42, 8, 20);
				s.disc('void', 136, 38, 3);
			}
		},
		'Cellar': function(s, st, t) {
			earth(s);
			for(var r = 0; r < 3; r++) {
				s.rect('amber', 14, 28 + r * 18, 60, 2);
				for(var j = 0; j < 7; j++) {
					s.rect('sick', 17 + j * 8, 21 + r * 18, 5, 7);
					s.px('bone', 18 + j * 8, 23 + r * 18);
				}
			}
			for(var k = 0; k < 7; k++) s.rect('amber', 110 + k * 3, 10 + k * 10, 20, 2);
			s.rect('void', 136, 50, 20, 30);
		},
		'Root Cellar': function(s, st, t) {
			earth(s);
			// the dress, laid out
			s.rect('dress', 54, 64, 50, 12);
			s.rect('dressDark', 60, 76, 38, 8);
			s.rect('dress', 46, 66, 8, 4);
			s.rect('dress', 104, 66, 8, 4);
			s.disc('bone', 40, 68, 5);
			s.px('void', 38, 67); s.px('void', 41, 67);
			for(var b = 0; b < 5; b++) s.px('bone', 58 + b * 8, 70);
			if(!st.tookBox) { s.rect('pale', 72, 58, 10, 6); s.rect('bone', 72, 58, 10, 1); }
			if(!st.tookLocket) s.px('pale', 112, 67);
			s.rect('void', 146, 40, 14, 40);
		},
		'Tunnel': function(s, st, t) {
			earth(s);
			for(var i = 0; i < 5; i++) {
				var inset = i * 12;
				s.rect('amber', 20 + inset, 10 + inset / 2, 4, 90 - inset);
				s.rect('amber', s.w - 24 - inset, 10 + inset / 2, 4, 90 - inset);
				s.rect('amber', 20 + inset, 10 + inset / 2, s.w - 40 - inset * 2, 3);
			}
			var drip = (t / 12) % 70;
			s.px('pale', 80, 20 + drip);
		},
		'Bottom of the Well': function(s, st, t) {
			s.rect('void', 0, 0, s.w, s.h);
			// the circle of sky, far above
			s.disc('deep', 80, 14, 9);
			s.px('pale', 77, 12); s.px('mid', 83, 16);
			for(var y = 20; y < 86; y++) {
				var w = 20 + (y - 20) * 0.9;
				s.dither('void', 'dark', Math.round(80 - w), y, 2, 1, 0.5);
				s.dither('void', 'dark', Math.round(80 + w), y, 2, 1, 0.5);
			}
			// water
			for(var x = 10; x < 150; x++) {
				s.px((x + Math.floor(t / 150)) % 6 ? 'deep' : 'mid', x, 86 + Math.round(Math.sin(x / 5 + t / 400)));
			}
			if(st.rope) {
				s.line('bone', 80, 22, 80, 84);
				s.rect('amber', 76, 83, 8, 5);
			}
		}
	};

	function drawScene(canvas, st, t) {
		var s = new Surface(160, 100);
		var fn = SCENES[st.room];
		if(fn) {
			fn(s, st, t);
		} else {
			s.rect('void', 0, 0, s.w, s.h);
		}
		var under = st.room === 'Cellar' || st.room === 'Root Cellar' || st.room === 'Tunnel';
		if(st.juneFollow && !under) juneSmall(s, 146, 74);
		if(st.dark) {
			s.rect('void', 0, 0, s.w, s.h);
			darkGrin(s, 80, 50, st.darkLevel, t);
		} else if(under && st.lamp) {
			s.lightRadius(80, 60, 46, Math.round(Math.sin(t / 110) * 2 + Math.random()));
			if(st.juneFollow) juneSmall(s, 104, 60);
		}
		s.blit(canvas);
	}

	/* ---------- portraits (40 x 40) ---------- */

	function mother(s, night, talking, t) {
		s.vgrad('void', 'deep', 0, 0, 40, 40);
		// hair
		s.disc('void', 20, 14, 12);
		s.disc('deep', 20, 5, 5);
		// face
		for(var y = 7; y < 29; y++) {
			var hw = Math.round(9 - Math.max(0, (y - 20)) * 0.6 - Math.max(0, 10 - y) * 0.7);
			s.rect('skin', 20 - hw, y, hw * 2, 1);
		}
		s.dither('skin', 'skinShade', 11, 7, 18, 22, function(x) { return x > 23 ? 0.5 : 0.08; });
		// eyes: from the third night they stop blinking
		var blink = night < 3 && (t % 3600) < 140;
		if(blink) {
			s.rect('skinShade', 14, 15, 4, 1);
			s.rect('skinShade', 22, 15, 4, 1);
		} else {
			s.rect('void', 15, 14, 3, 3);
			s.rect('void', 23, 14, 3, 3);
			s.px('pale', 16, 14);
			s.px('pale', 24, 14);
		}
		// the smile, wider every night
		var w = Math.min(4 + night * 3, 17);
		if(night === 1) {
			s.line('gum', 20 - w, 23, 20 + w, 23);
			s.px('gum', 20 - w - 1, 22);
			s.px('gum', 20 + w + 1, 22);
		} else {
			for(var x = -w; x <= w; x++) {
				var yy = 23 - Math.round((x * x) / (w * w) * 2);
				s.px('gum', 20 + x, yy - 1);
				if(night > 2 || talking) s.px(Math.abs(x) % 2 ? 'bone' : 'gum', 20 + x, yy);
				if(night > 3) s.px('bone', 20 + x, yy + 1);
				s.px('gum', 20 + x, yy + 1 + (night > 3 ? 1 : 0));
			}
		}
		// dress collar
		s.rect('dress', 6, 32, 28, 8);
		s.rect('dressDark', 16, 32, 8, 3);
		s.rect('skin', 17, 29, 6, 3);
	}

	function june(s, talking, t) {
		s.vgrad('void', 'deep', 0, 0, 40, 40);
		// hair with bangs
		s.disc('void', 20, 16, 12);
		for(var y = 9; y < 30; y++) {
			var hw = Math.round(8 - Math.max(0, y - 22) * 0.8 - Math.max(0, 12 - y) * 0.9);
			s.rect('skin', 20 - hw, y, hw * 2, 1);
		}
		s.rect('void', 11, 9, 18, 5);
		s.dither('skin', 'skinShade', 12, 10, 16, 20, function(x) { return x > 22 ? 0.4 : 0.05; });
		// big eyes, older than eight
		s.rect('void', 14, 17, 4, 4);
		s.rect('void', 22, 17, 4, 4);
		s.px('pale', 15, 17);
		s.px('pale', 23, 17);
		s.line('skinShade', 14, 22, 17, 22);
		s.line('skinShade', 22, 22, 25, 22);
		// small mouth
		if(talking && Math.floor(t / 120) % 2) {
			s.rect('gum', 19, 25, 3, 2);
		} else {
			s.line('gum', 19, 25, 21, 25);
		}
		// yellow dress
		s.rect('yellow', 8, 32, 24, 8);
		s.rect('amber', 17, 32, 6, 2);
		s.rect('skin', 18, 30, 4, 2);
	}

	function drawPortrait(canvas, who, night, talking, t) {
		var s = new Surface(40, 40);
		if(who === 'mother') {
			mother(s, night, talking, t);
		} else {
			june(s, talking, t);
		}
		s.blit(canvas);
	}

	// the close-up grin inset, 64 x 28
	function drawGrin(canvas, night, t) {
		var s = new Surface(64, 28);
		s.rect('void', 0, 0, 64, 28);
		s.dither('void', 'skinShade', 0, 0, 64, 28, function(x, y) { return 0.25 - Math.abs(y - 14) / 60; });
		var w = 26, open = 3 + Math.min(night, 5);
		for(var x = -w; x <= w; x++) {
			var curve = Math.round((x * x) / (w * w) * -6);
			var top = 12 + curve, bottom = top + open;
			s.px('gum', 32 + x, top - 1);
			for(var y = top; y < bottom; y++) {
				var tooth = (x + 40) % 4 !== 0 && y !== top + (open >> 1);
				s.px(tooth ? 'bone' : 'gum', 32 + x, y);
			}
			s.px('gum', 32 + x, bottom);
		}
		s.blit(canvas);
	}

	return { drawScene: drawScene, drawPortrait: drawPortrait, drawGrin: drawGrin, palette: P };
})();
