"""Builds hollow/engine/ from the original Zork I engine files at the repo root.

The Zork I files at the root are left exactly as Infocom wrote them. This
script copies the generic engine files (parser, verbs, clock, globals) into
hollow/engine/ and applies a short, fixed list of text replacements so the
engine prints Hollow House text instead of Zork text. Every change is listed
below, so the difference from the original can be read in one place.

Run from the repo root:  python tools/make_engine.py
"""
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'hollow', 'engine')
FILES = ['gmacros.zil', 'gsyntax.zil', 'gglobals.zil', 'gclock.zil',
         'gmain.zil', 'gparser.zil', 'gverbs.zil']

HEADER = (';"Hollow House: copied from the Zork I source at the repo root by\n'
          '  tools/make_engine.py. Original (c) Infocom, MIT license (Microsoft, 2025).\n'
          '  Changes from the original are listed in make_engine.py."\n\n')

# (file, old text, new text). Each old text must appear exactly once.
PATCHES = [
    # the version banner. the original routine is kept, renamed and unused.
    ('gverbs.zil',
     '<ROUTINE V-VERSION ("AUX" (CNT 17))\n',
     '<ROUTINE V-VERSION ("AUX" (CNT 17))\n'
     '\t<TELL "HOLLOW HOUSE|An interactive horror, built from the Zork I source|'
     'Zork I (c) Infocom; source released under the MIT license by Microsoft, 2025|'
     'Release ">\n'
     '\t<PRINTN <BAND <GET 0 1> *3777*>>\n'
     '\t<TELL " / Serial number ">\n'
     '\t<REPEAT ()\n'
     '\t\t<COND (<G? <SET CNT <+ .CNT 1>> 23> <RETURN>)\n'
     '\t\t      (T <PRINTC <GETB 0 .CNT>>)>>\n'
     '\t<CRLF>>\n\n'
     '<ROUTINE ORIGINAL-VERSION ("AUX" (CNT 17))\n'),
    # darkness: the grue becomes the thing that smiles
    ('gverbs.zil',
     '<TELL " You are likely to be eaten by a grue.">',
     '<TELL " Something down here is smiling. You can hear its teeth.">'),
    ('gverbs.zil',
     '"Oh, no! You have walked into the slavering fangs of a lurking grue!"',
     '"You walk into it in the dark. It is warm, and it was waiting, and it is all teeth."'),
    ('gverbs.zil',
     '"Oh, no! A lurking grue slithered into the ">',
     '"Something that smiles was waiting for you in the ">'),
    ('gverbs.zil',
     '<JIGS-UP " and devoured you!">',
     '<JIGS-UP ". You never see it.">'),
    ('gverbs.zil',
     '"You can\'t swim in the dungeon."',
     '"The water is too cold, and much too still."'),
    ('gverbs.zil',
     '"Well, for one, you are playing Zork..."',
     '"Well, for one, June is still up there. You can count on her."'),
    # turning things off shouldn't try to pick them up first (the radio is furniture)
    ('gsyntax.zil',
     '<SYNTAX TURN OFF OBJECT (FIND ONBIT)\n\t(HELD CARRIED ON-GROUND IN-ROOM TAKE HAVE) = V-LAMP-OFF>',
     '<SYNTAX TURN OFF OBJECT (FIND ONBIT)\n\t(HELD CARRIED ON-GROUND IN-ROOM) = V-LAMP-OFF>'),
    # the lines for jumping somewhere you shouldn't
    ('gverbs.zil',
     '"You should have looked before you leaped."\n\t       "In the movies, your life would be passing before your eyes."\n\t       "Geronimo..."',
     '"The dark takes a long time to reach the bottom."\n\t       "On the way down you hear humming, and then you don\'t."\n\t       "You fall, and something below you is already smiling."'),
    # Zork II/III lake rooms that the fallback branches name
    ('gverbs.zil',
     "'<COND (<EQUAL? ,HERE ,ON-LAKE>\n\t\t\t\t\t      ,IN-LAKE)\n\t\t\t\t\t     (T\n\t\t\t\t\t      ,HERE)>",
     "',HERE"),
    ('gverbs.zil',
     "'(<EQUAL? ,HERE ,ON-LAKE ,IN-LAKE>\n\t\t         <TELL \"What do you think you're doing?\" CR>)",
     "'(<NULL-F> <RFALSE>)"),
    # the grue object
    ('gglobals.zil',
     '(SYNONYM GRUE)\n\t(ADJECTIVE LURKING SINISTER HUNGRY SILENT)\n\t(DESC "lurking grue")',
     '(SYNONYM GRUE THING SMILE TEETH)\n\t(ADJECTIVE SMILING GRINNING HUNGRY SILENT)\n\t(DESC "smiling thing")'),
    ('gglobals.zil',
     '"The grue is a sinister, lurking presence in the dark places of the\n'
     'earth. Its favorite diet is adventurers, but its insatiable\n'
     'appetite is tempered by its fear of light. No grue has ever been\n'
     'seen by the light of day, and few have survived its fearsome jaws\n'
     'to tell the tale."',
     '"You have never seen it. You have only heard it, in the dark under the\n'
     'house, and the sound it makes is the sound of a mouth stretching."'),
    ('gglobals.zil',
     '"There is no grue here, but I\'m sure there is at least one lurking\n'
     'in the darkness nearby. I wouldn\'t let my light go out if I were\n'
     'you!"',
     '"It is somewhere under the house. Keep a light burning and it keeps\n'
     'its distance."'),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    texts = {}
    for name in FILES:
        with io.open(os.path.join(ROOT, name), encoding='latin-1', newline='') as f:
            texts[name] = f.read().replace('\r\n', '\n')
    for name, old, new in PATCHES:
        count = texts[name].count(old)
        if count != 1:
            sys.exit('patch not applied, %s: expected 1 match, found %d:\n%s' % (name, count, old[:80]))
        texts[name] = texts[name].replace(old, new)
    for name in FILES:
        with io.open(os.path.join(OUT, name), 'w', encoding='latin-1', newline='\n') as f:
            f.write(HEADER + texts[name])
    print('wrote %d engine files to hollow/engine with %d patches' % (len(FILES), len(PATCHES)))


if __name__ == '__main__':
    main()
