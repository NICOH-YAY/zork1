# Hollow House

**Play:** https://nicoh-yay.github.io/zork1/

Game: *Hollow House*, release 1, a new game built from the Zork I source. Evidence: source code, this repository. Reuse terms: Zork I source under the MIT license (Microsoft, 2025), kept at the repo root unchanged. Hollow House's new files are MIT as well.

AI-use disclosure: the ZIL game code, the story text, the web player and the pixel art were drafted with Claude (Anthropic) in Claude Code from my design direction. I chose the premise, reviewed the story, playtested it, and I answer for what's here.

## What it is

It is 3:00 in the morning and you are standing in the field outside the house you grew up in. Your sister June went missing from this house twenty years ago at 3:33. Every night the clock strikes 3:33, the house resets, and you are back in the field at 3:00. You keep what you learned. The house keeps nothing, except the notes someone keeps leaving in the mailbox in your own handwriting.

Something is wearing your mother's green dress in the kitchen. It is stirring a pot of soup, and its smile gets a little wider every time you come back.

## How the game uses the Zork I source

The Infocom files at the repo root are untouched. `tools/make_engine.py` copies the generic engine (parser, verbs, clock and globals) into `hollow/engine/` and applies a short list of text replacements, so the grue becomes the thing that smiles and the banner names this game. Every change from the original is listed in that one script. Zork's own map (`1dungeon.zil`) and puzzles (`1actions.zil`) are not used. The new game lives in:

- `hollow/hollow.zil`: the build file, plus five verbs the Zork parser didn't have (show, sing/hum, knock, sleep, lie)
- `hollow/hdungeon.zil`: 13 rooms and their objects
- `hollow/hactions.zil`: the loop, Mother, June, the endings and every object's behavior
- `docs/`: the web player (a JSZM Z-machine, the pixel art, the dialog boxes)

Some Zork pieces were reused in spirit: the kitchen window you climb through, the rug hiding a trap door, and the lamp you need in the dark. Their code is new.

## MDA reading

**Mechanic.** The night is 45 turns long, from 3:00 to 3:33. At 3:33, or if you die, every object and person goes back where it was, and the night counter goes up by one. Your knowledge is the only thing that carries over, along with the notes in the mailbox, which gain a new line every few nights.

**Dynamics.** One night is enough to win only if you already know the order: lower the bucket, get the lamp while Mother is distracted, find what is under the house, open June's door, and leave by the well so you never walk June past the kitchen. So the first few nights go to scouting, and after that play turns into planning a route inside a fixed clock. Death costs you a night and nothing else, so taking risks to learn things is the right move.

**Aesthetic.** Dread that builds across loops, from details that change while the rules stay put. The photo on the mantel gets scratched, the left swing moves with no wind, the note grows, and Mother's smile widens in her portrait each night until a close-up of the grin shows up in her dialog box. The goal is mastery (the route) with fear pushing on it.

A playing agent could perceive the mechanic and most of the dynamic from the transcript. It can't tell whether a person feels the dread or just treats the house as a puzzle to optimize, and that has to be tested with people.

## Rules and evidence

Evidence labels follow the course: `code`, `manual`, `observed`, `assumed`.

| Rule | Evidence |
|---|---|
| A night lasts 45 turns; the clock shows 3:00 to 3:33 | `code`, hollow/hactions.zil `LOOP-LENGTH`, `PRINT-TIME` |
| At 3:33, on death, or on sleeping, the house resets and the night count goes up | `code`, hactions.zil `TIME-UP`, `JIGS-UP`, `LOOP-RESET`, `RESET-HOUSE` |
| The mailbox note gains lines on nights 2, 3, 4 and 6 | `code`, hactions.zil `NOTE-F` |
| Mother blocks the pantry and the lamp while she is in the kitchen | `code`, hactions.zil `PANTRY-F`, `LAMP-F` |
| The radio draws Mother to the living room for 6 turns; if she comes back while you hold the lamp in the kitchen, she takes it | `code`, hactions.zil `RADIO-F`, `MOTHER-RETURNS` |
| Three turns in the dark under the house is death | `code`, hactions.zil `I-NIGHT` (`DARK-TURNS`) |
| June only opens her door to the music box, and only follows you after seeing the locket | `code`, hactions.zil `MUSIC-BOX-F`, `JUNE-F` |
| If June is with you in a room Mother is in, the night ends | `code`, hactions.zil `I-NIGHT`, `CAUGHT` |
| Leaving west with June wins; eating the soup is the other ending | `code`, hactions.zil `FOREST-EXIT`, `ENDING-DAWN`, `SOUP-F`, `ENDING-DINNER` |
| The game can be won in one night by a player who knows the route | `observed`, tools/test/win-one-night.txt finishes in 33 turns |
| A new player needs 3 to 5 nights | `assumed`, needs playtesting |
| The widening smile makes the loop feel worse over time | `assumed`, needs playtesting with people |

## Acceptance trace

`tools/test/win-one-night.txt` is the full route. Run it with `node tools/test/play.cjs docs/hollow.z3 tools/test/win-one-night.txt`. The expected state changes are:

1. `s`, `lower bucket`: the rope hangs into the well (`BUCKET-DOWN` true).
2. `n`, `open window`, `w`: you enter the kitchen and Mother greets you. `w` takes you to the living room.
3. `move rug`, `open trap door`, `turn on radio`: Mother moves to the living room for 6 turns.
4. `e`, `open pantry`, `take lamp`, `take matches`, `w`, `light lamp`: the song ends while you are in the living room, so she walks back to the kitchen without taking the lamp.
5. `d`, `e`, `take box`, `take locket`: this is in the root cellar, under the house.
6. `w`, `u`, `u`, `wind box`: June's door opens. `n`, `show locket to june`: June follows you.
7. `s`, `d`, `d`, `e`, `e`, `e`, `climb rope`: you go through the tunnel and up the well, never passing the kitchen.
8. `w`, `w`: dawn ending at turn 33, "It took you 1 night."

Other scripts in `tools/test/` cover the 3:33 reset, death in the dark, the note changing across nights, getting the lamp taken back, getting caught, and the dinner ending.

## Building

You need [ZILF](https://zilf.io) 1.9. Then run `sh tools/build.sh` (set `ZILF_BIN` to ZILF's `bin` folder and `PYTHON` to your Python). It rebuilds the engine copy, compiles `hollow/hollow.zil` and copies `hollow.z3` into `docs/`. To play locally, serve `docs/` with any static server, for example `python -m http.server --directory docs`.

## Open questions

- 45 turns might be too tight for the first night or too loose once you know the route.
- The hints in the note arrive on fixed nights. A player who reads the diary on night 1 still gets told to read it on night 3.
- Typing commands is a barrier for people who have never played a parser game. The chips under the input help a little.

## Credits

Zork I by Tim Anderson, Marc Blank, Bruce Daniels and Dave Lebling (Infocom, 1980), source released under the MIT license by Microsoft in 2025 through historicalsource. Compiled with ZILF by Tara McGrew. The web player runs on JSZM, a public-domain Z-machine by zzo38. Font: VT323.
