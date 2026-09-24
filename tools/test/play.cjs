// Runs Hollow House in Node with JSZM and prints a transcript.
// usage: node tools/test/play.cjs story.z3 commands.txt
// Each line of commands.txt is one command. Lines starting with # are skipped.
const fs = require('fs');
const JSZM = require('./jszm.js');
const [story, cmdFile] = process.argv.slice(2);
const cmds = fs.readFileSync(cmdFile, 'utf8').split(/\r?\n/).filter(l => l.trim() && !l.startsWith('#'));
const g = new JSZM(fs.readFileSync(story));
let out = '';
g.print = function* (t) { out += t; };
g.read = function* () {
  if (!cmds.length) { process.stdout.write(out + '\n[end of commands]\n'); process.exit(0); }
  const c = cmds.shift();
  out += c + '\n';
  return c;
};
g.updateStatusLine = function* (room, moves, loop) { out += `\n[${room} | night ${loop} | turn ${moves}]\n`; };
const it = g.run();
it.next();
process.stdout.write(out + '\n[game quit]\n');
