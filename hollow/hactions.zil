"HACTIONS for
		HOLLOW HOUSE
	The loop, the people in the house, and what the objects do.
	Built on the Zork I engine (Infocom), MIT license.

	Text between {{ and }} is a cue for the web player (portraits, the
	reset flash, the endings). Plain interpreters print it as-is."

"---------- the loop ----------"

<CONSTANT LOOP-LENGTH 45>	;"turns from 3:00 to 3:33"

<GLOBAL MOTHER-AWAY 0>		;"turns left before the song on the radio ends"
<GLOBAL MOTHER-GREETED <>>
<GLOBAL JUNE-FOLLOWING <>>
<GLOBAL JUNE-MET <>>
<GLOBAL LAMP-FUEL 20>
<GLOBAL MATCHES-LEFT 3>
<GLOBAL DARK-TURNS 0>
<GLOBAL RUG-MOVED <>>
<GLOBAL ENDED <>>
<GLOBAL DIARY-READ <>>		;"survives the loop, like the notes"

<GLOBAL JUNE-FOLLOWS
	<LTABLE 0
		"June comes after you, holding a fistful of your sleeve."
		"June follows, close enough that you can hear her breathe."
		"June is right behind you. She doesn't make a sound on the floor."
		"June keeps hold of your sleeve.">>

<ROUTINE GO ()
	<SETG VERBOSE T>
	<SETG SCORE 1>
	<SETG MOVES 0>
	<SETG HERE ,WEST-OF-HOUSE>
	<THIS-IS-IT ,MAILBOX>
	<V-VERSION>
	<CRLF>
	<TELL
"It is three in the morning. You drove all night to get here, and you don't
remember the drive. You don't remember deciding to come back at all." CR CR>
	<SETG LIT T>
	<SETG WINNER ,ADVENTURER>
	<SETG PLAYER ,WINNER>
	<MOVE ,WINNER ,HERE>
	<ENABLE <QUEUE I-NIGHT -1>>
	<V-LOOK>
	<MAIN-LOOP>
	<AGAIN>>

"prints the clock as 3:MM from the turn count"
<ROUTINE PRINT-TIME ("AUX" M)
	<SET M </ <* ,MOVES 33> ,LOOP-LENGTH>>
	<COND (<G? .M 33> <SET M 33>)>
	<TELL "3:">
	<COND (<L? .M 10> <TELL "0">)>
	<PRINTN .M>>

<ROUTINE V-SCORE ("OPTIONAL" (ASK? T))
	<TELL "It is ">
	<PRINT-TIME>
	<TELL " in the morning. ">
	<COND (<EQUAL? ,SCORE 1>
	       <TELL "As far as you know, this is the first time tonight." CR>)
	      (T
	       <TELL "This is the ">
	       <PRINT-ORDINAL ,SCORE>
	       <TELL " time tonight." CR>)>>

<ROUTINE PRINT-ORDINAL (N)
	<COND (<EQUAL? .N 2> <TELL "second">)
	      (<EQUAL? .N 3> <TELL "third">)
	      (<EQUAL? .N 4> <TELL "fourth">)
	      (<EQUAL? .N 5> <TELL "fifth">)
	      (<EQUAL? .N 6> <TELL "sixth">)
	      (<EQUAL? .N 7> <TELL "seventh">)
	      (T <PRINTN .N> <TELL "th">)>>

<ROUTINE V-DIAGNOSE ()
	<TELL "You are cold, and more tired than one night should make you." CR>>

"called every turn"
<ROUTINE I-NIGHT ()
	<COND (,ENDED <RFALSE>)>
	<COND (<AND ,JUNE-FOLLOWING <NOT <IN? ,JUNE ,HERE>>>
	       <MOVE ,JUNE ,HERE>
	       <TELL <PICK-ONE ,JUNE-FOLLOWS> CR>)>
	<COND (<G? ,MOTHER-AWAY 0>
	       <SETG MOTHER-AWAY <- ,MOTHER-AWAY 1>>
	       <COND (<0? ,MOTHER-AWAY> <MOTHER-RETURNS>)>)>
	<COND (<AND ,JUNE-FOLLOWING <IN? ,MOTHER ,HERE>>
	       <CAUGHT>
	       <RTRUE>)>
	<COND (<FSET? ,LAMP ,ONBIT>
	       <SETG LAMP-FUEL <- ,LAMP-FUEL 1>>
	       <COND (<0? ,LAMP-FUEL>
		      <FCLEAR ,LAMP ,ONBIT>
		      <SETG LIT <LIT? ,HERE>>
		      <COND (<OR <HELD? ,LAMP> <IN? ,LAMP ,HERE>>
			     <TELL "The flame in the lamp shrinks to a blue bead and goes out." CR>)>)
		     (<AND <EQUAL? ,LAMP-FUEL 4> <OR <HELD? ,LAMP> <IN? ,LAMP ,HERE>>>
		      <TELL "The lamp flame gutters. There isn't much oil left." CR>)>)>
	<COND (<NOT ,LIT>
	       <SETG DARK-TURNS <+ ,DARK-TURNS 1>>
	       <COND (<EQUAL? ,DARK-TURNS 2>
		      <TELL
"{{scare}}It is closer now. You can hear it breathing through its teeth." CR>)
		     (<G? ,DARK-TURNS 2>
		      <JIGS-UP
"Something warm touches your face in the dark. It is smiling. You can feel
it smiling.">
		      <RTRUE>)>)
	      (T
	       <SETG DARK-TURNS 0>)>
	<COND (<EQUAL? ,MOVES 30>
	       <TELL "Somewhere below you, the grandfather clock chimes the quarter hour." CR>)
	      (<EQUAL? ,MOVES 41>
	       <TELL "The grandfather clock whirs, getting ready to strike." CR>)>
	<COND (<NOT <L? ,MOVES ,LOOP-LENGTH>>
	       <TIME-UP>
	       <RTRUE>)>
	<RFALSE>>

<ROUTINE TIME-UP ()
	<TELL CR
"The grandfather clock begins to strike. It strikes three, and then it keeps
striking." CR>
	<COND (<IN? ,MOTHER ,HERE>
	       <TELL
"{{face mother}}Mother turns around, all the way around, and smiles at you with
more teeth than a mouth should hold. \"Dinner,\" she says.{{/face}}" CR>)
	      (T
	       <TELL
"{{face mother}}From every room at once, Mother calls up the stairs.
\"Dinner!\"{{/face}}" CR>)>
	<LOOP-RESET>>

<ROUTINE CAUGHT ()
	<TELL
"{{face mother}}Mother's hand is on June's shoulder. You didn't see her cross
the room. \"And where,\" she says, \"are you taking my girl?\"{{/face}}" CR>
	<TELL "The lights go out." CR>
	<LOOP-RESET>>

"the engine calls this when you die"
<ROUTINE JIGS-UP (DESC "OPTIONAL" (PLAYER? <>))
	<TELL .DESC CR>
	<LOOP-RESET>>

<ROUTINE LOOP-RESET ()
	<TELL CR "{{reset}}" CR>
	<SETG SCORE <+ ,SCORE 1>>
	<SETG MOVES 0>
	<RESET-HOUSE>
	<TELL
"...and you are standing in the field again. The grass is wet. It is 3:00." CR CR>
	<MOVE ,WINNER ,WEST-OF-HOUSE>
	<SETG HERE ,WEST-OF-HOUSE>
	<SETG LIT T>
	<SETG P-CONT <>>
	<V-LOOK>
	<RFATAL>>

"puts everything back where it was at 3:00"
<ROUTINE RESET-HOUSE ()
	<MOVE ,NOTE ,MAILBOX>
	<FCLEAR ,MAILBOX ,OPENBIT>
	<FCLEAR ,KITCHEN-WINDOW ,OPENBIT>
	<SETG BUCKET-DOWN <>>
	<MOVE ,MOTHER ,KITCHEN>
	<SETG MOTHER-AWAY 0>
	<SETG MOTHER-GREETED <>>
	<FCLEAR ,RADIO ,ONBIT>
	<FCLEAR ,PANTRY ,OPENBIT>
	<MOVE ,LAMP ,PANTRY>
	<FCLEAR ,LAMP ,ONBIT>
	<SETG LAMP-FUEL 20>
	<MOVE ,MATCHBOOK ,PANTRY>
	<SETG MATCHES-LEFT 3>
	<SETG RUG-MOVED <>>
	<FSET ,TRAP-DOOR ,INVISIBLE>
	<FCLEAR ,TRAP-DOOR ,OPENBIT>
	<FCLEAR ,JUNE-DOOR ,OPENBIT>
	<MOVE ,JUNE ,JUNE-ROOM>
	<SETG JUNE-FOLLOWING <>>
	<SETG JUNE-MET <>>
	<FCLEAR ,NIGHTSTAND ,OPENBIT>
	<MOVE ,DIARY ,NIGHTSTAND>
	<MOVE ,MUSIC-BOX ,ROOT-CELLAR>
	<FCLEAR ,MUSIC-BOX ,TOUCHBIT>
	<MOVE ,LOCKET ,ROOT-CELLAR>
	<FCLEAR ,LOCKET ,TOUCHBIT>
	<SETG DARK-TURNS 0>>

"---------- small helpers the Zork I actions file used to provide ----------"

<ROUTINE OPEN-CLOSE (OBJ STROPN STRCLS)
	 <COND (<VERB? OPEN>
		<COND (<FSET? .OBJ ,OPENBIT>
		       <TELL <PICK-ONE ,DUMMY>>)
		      (T
		       <TELL .STROPN>
		       <FSET .OBJ ,OPENBIT>)>
		<CRLF>)
	       (<VERB? CLOSE>
		<COND (<FSET? .OBJ ,OPENBIT>
		       <TELL .STRCLS>
		       <FCLEAR .OBJ ,OPENBIT>
		       T)
		      (T <TELL <PICK-ONE ,DUMMY>>)>
		<CRLF>)>>

"there are no weapons in the house"
<ROUTINE FIND-WEAPON (O) <RFALSE>>

"---------- endings ----------"

<ROUTINE ENDING-DAWN ()
	<SETG ENDED T>
	<TELL
"You walk west with June's hand in yours. The trees close in and the path
bends, the way it always bends, and you keep walking. June doesn't look back,
so you don't either." CR CR
"Behind you, the yellow light in the window goes out." CR CR
"After a long time the sky ahead goes grey, and then white. You check your
watch. It says 3:34. Then it says 3:35." CR CR>
	<TELL "{{end dawn}}It took you ">
	<PRINTN ,SCORE>
	<COND (<EQUAL? ,SCORE 1> <TELL " night">) (T <TELL " nights">)>
	<TELL ". June is eight years old. She has been eight for twenty years, and
tomorrow she won't be." CR>
	<QUIT>>

<ROUTINE ENDING-DINNER ()
	<SETG ENDED T>
	<TELL
"You sit down at your old place and pick up the spoon. The soup is warm, and
it tastes like being small. Mother sits across from you and watches you eat." CR CR
"{{face mother}}\"There,\" she says. \"Now everyone's home.\"{{/face}}" CR CR
"Upstairs, June stops humming." CR CR
"{{end dinner}}You stay for dinner. You stay for every dinner after that." CR>
	<QUIT>>

"---------- outside ----------"

<ROUTINE WEST-HOUSE-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"You are standing in a field west of a white house. The front door is boarded
over from the inside. One window upstairs is lit, a flat yellow light, the same
light that was on the night June went missing twenty years ago.">
	       <COND (<G? ,SCORE 1>
		      <TELL " It is always 3:00 when you get here.">)>
	       <TELL
" A dirt track runs west into the trees. The grass goes on north around the
house, and south toward an old well." CR>)>>

<ROUTINE FOREST-EXIT ()
	<COND (<AND ,JUNE-FOLLOWING <IN? ,JUNE ,HERE>>
	       <ENDING-DAWN>
	       <RFALSE>)
	      (T
	       <TELL
"You walk west into the trees. The track bends, and bends again, and after a
while you step out of the trees into the same field. The light in the window
is still on." CR CR>
	       ,WEST-OF-HOUSE)>>

<ROUTINE WHITE-HOUSE-F ()
	<COND (<VERB? EXAMINE>
	       <TELL
"The house you grew up in. White paint gone grey, every downstairs window
boarded except the little one over the kitchen sink, around back." CR>)
	      (<VERB? FIND>
	       <TELL "It's right there. It's always right there." CR>)>>

<ROUTINE BOARDS-F ()
	<COND (<VERB? EXAMINE>
	       <TELL
"The boards were nailed up from the inside. Whoever did it wanted to keep
something in more than they wanted to keep something out." CR>)
	      (<VERB? OPEN MOVE TAKE ATTACK MUNG>
	       <TELL "The nails are driven deep. They aren't coming out tonight." CR>)>>

<ROUTINE LIT-WINDOW-F ()
	<COND (<VERB? EXAMINE LOOK-INSIDE>
	       <TELL
"June's window. The light behind it is the color of old teeth. Now and then a
small shadow crosses it." CR>)>>

<ROUTINE MAILBOX-F ()
	<COND (<VERB? TAKE>
	       <TELL "The mailbox is set in concrete." CR>)
	      (<VERB? EXAMINE>
	       <TELL
"A rusted mailbox with the family name worn off. The flag is up." CR>)>>

<ROUTINE NOTE-F ()
	<COND (<VERB? READ EXAMINE>
	       <TELL
"The handwriting is yours. You don't remember writing it." CR CR
"\"It's 3:00 again. Get June out before 3:33. Don't eat the soup. Don't
let her see you take anything.\"" CR>
	       <COND (<G? ,SCORE 1>
		      <TELL CR "Under it, in the same hand, newer ink:" CR
"\"The radio. She can't help herself.\"" CR>)>
	       <COND (<G? ,SCORE 2>
		      <TELL
"\"Dad's diary, in the nightstand. Read it this time.\"" CR>)>
	       <COND (<G? ,SCORE 3>
		      <TELL
"\"LOWER THE BUCKET FIRST. Then everything else.\"" CR>)>
	       <COND (<G? ,SCORE 5>
		      <TELL
"\"I know you're tired. I'm tired too. Keep going.\"" CR>)>
	       <RTRUE>)>>

<ROUTINE NORTH-HOUSE-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"You are on the north side of the house. The windows here are boarded. An old
swing set stands in the grass">
	       <COND (<G? ,SCORE 1>
		      <TELL ", and the left swing is moving. There is no wind">)>
	       <TELL
". The grass continues east, around the back of the house, and west to the
front." CR>)>>

<ROUTINE SWING-F ()
	<COND (<VERB? EXAMINE>
	       <TELL
"Two swings on rusted chains. June always took the left one. You always
pushed." CR>)
	      (<VERB? PUSH MOVE CLIMB-ON CLIMB-FOO BOARD>
	       <TELL
"The chain is cold. When you let go, the swing keeps moving a little longer
than it should." CR>)>>

<ROUTINE BEHIND-HOUSE-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"You are behind the house. A small window over the kitchen sink is ">
	       <COND (<FSET? ,KITCHEN-WINDOW ,OPENBIT>
		      <TELL "open wide">)
		     (T
		      <TELL "open an inch">)>
	       <TELL ", and warm light and the smell of onions come out of it.">
	       <COND (<IN? ,MOTHER ,KITCHEN>
		      <TELL
" Through it you can see Mother at the stove with her back to you.">)
		     (T
		      <TELL " The kitchen is empty. The pot is still boiling.">)>
	       <TELL
" The grass runs north around the house and south to the well." CR>)>>

<ROUTINE KITCHEN-WINDOW-F ()
	<COND (<VERB? OPEN CLOSE>
	       <OPEN-CLOSE ,KITCHEN-WINDOW
"You push the window up. It sticks, then gives, and it's wide enough to climb
through."
"You ease the window down.">)
	      (<AND <VERB? EXAMINE> <NOT <FSET? ,KITCHEN-WINDOW ,OPENBIT>>>
	       <TELL
"The window is open an inch. You used to sneak in this way after curfew." CR>)
	      (<VERB? WALK BOARD THROUGH ENTER>
	       <COND (<EQUAL? ,HERE ,KITCHEN> <DO-WALK ,P?EAST>)
		     (T <DO-WALK ,P?WEST>)>
	       <RTRUE>)
	      (<VERB? LOOK-INSIDE>
	       <COND (<EQUAL? ,HERE ,KITCHEN>
		      <TELL "Grass, and the well, and the black line of the trees." CR>)
		     (T
		      <TELL "The kitchen, lit and warm and wrong." CR>)>)>>

<ROUTINE WELL-TOP-F (RARG)
	<COND (<AND <EQUAL? .RARG ,M-BEG> <VERB? LEAP>>
	       <TELL
"You climb up onto the lip of the well and look down into the black. It looks
back. You climb down again." CR>
	       <RTRUE>)
	      (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"An old stone well stands in the grass south of the house, with a wooden
bucket hung from a winch over the opening. ">
	       <COND (,BUCKET-DOWN
		      <TELL "The rope runs straight down into the dark. ">)>
	       <TELL
"The house is north. The front field is to the west." CR>)>>

<ROUTINE WELL-F ()
	<COND (<VERB? EXAMINE LOOK-INSIDE>
	       <TELL
"Black water, very far down. The stones are furred with moss.">
	       <COND (<G? ,SCORE 1>
		      <TELL
" If you hold your breath you can hear something down there, humming.">)>
	       <CRLF>)
	      (<VERB? CLIMB-DOWN ENTER BOARD CLIMB-FOO THROUGH>
	       <DO-WALK ,P?DOWN>
	       <RTRUE>)>>

<ROUTINE BUCKET-F ()
	<COND (<VERB? LOWER TURN PUSH MOVE DROP>
	       <COND (,BUCKET-DOWN
		      <TELL "The rope is already all the way down." CR>)
		     (T
		      <SETG BUCKET-DOWN T>
		      <TELL
"You let the winch go. It spins and spins, and the rope pays out a long way
before the bucket slaps water, far below. The rope hangs taut into the
dark." CR>)>)
	      (<VERB? RAISE>
	       <COND (,BUCKET-DOWN
		      <SETG BUCKET-DOWN <>>
		      <TELL "You crank the bucket back up. It comes up empty." CR>)
		     (T
		      <TELL "The bucket is already up." CR>)>)
	      (<VERB? TAKE>
	       <TELL "The bucket is tied fast to the winch rope." CR>)
	      (<VERB? EXAMINE>
	       <TELL "A wooden bucket on a frayed rope, on a winch. ">
	       <COND (,BUCKET-DOWN <TELL "It's down in the well." CR>)
		     (T <TELL "It hangs over the opening." CR>)>)>>

<ROUTINE ROPE-F ()
	<COND (<VERB? CLIMB-UP CLIMB-FOO CLIMB-ON>
	       <COND (<EQUAL? ,HERE ,WELL-BOTTOM> <DO-WALK ,P?UP>)
		     (T <DO-WALK ,P?DOWN>)>
	       <RTRUE>)
	      (<VERB? CLIMB-DOWN>
	       <DO-WALK ,P?DOWN>
	       <RTRUE>)
	      (<VERB? TAKE>
	       <TELL "It's tied to the winch." CR>)
	      (<VERB? EXAMINE>
	       <COND (,BUCKET-DOWN
		      <TELL "The rope hangs down the middle of the well, wet and taut." CR>)
		     (T
		      <TELL "The rope is wound up on the winch." CR>)>)>>

<ROUTINE WATER-F ()
	<COND (<VERB? DRINK>
	       <TELL "It tastes like pennies and old leaves." CR>)
	      (<VERB? EXAMINE>
	       <TELL "Black, and so still it looks solid." CR>)>>

"---------- the kitchen ----------"

<ROUTINE KITCHEN-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"The kitchen smells of onions and of something under the onions. A pot of
grey soup boils on the stove. The table is set for four. A narrow pantry door
is ">
	       <COND (<FSET? ,PANTRY ,OPENBIT> <TELL "open">)
		     (T <TELL "shut">)>
	       <TELL
" beside the stove, the window over the sink leads out, and a doorway leads
west into the living room." CR>
	       <COND (<IN? ,MOTHER ,KITCHEN>
		      <CRLF>
		      <MOTHER-GREETING>)
		     (T
		      <TELL CR "Mother isn't here. Her spoon is still turning in the pot." CR>)>)>>

<ROUTINE MOTHER-GREETING ()
	<COND (,MOTHER-GREETED
	       <TELL "Mother stands at the stove, stirring, with her back to you." CR>
	       <RTRUE>)>
	<SETG MOTHER-GREETED T>
	<COND (<EQUAL? ,SCORE 1>
	       <TELL
"{{face mother}}Mother stands at the stove in her green dress, stirring, with
her back to you. \"You're late,\" she says, without turning around. \"Dinner is
at 3:33. Go and get your sister.\"{{/face}}" CR>)
	      (<EQUAL? ,SCORE 2>
	       <TELL
"{{face mother}}Mother stands at the stove in her green dress. \"You're late
again,\" she says. You didn't know she knew about the first time.
\"Go and get your sister.\"{{/face}}" CR>)
	      (T
	       <TELL
"{{face mother}}Mother turns her head to look at you over her shoulder. It
keeps turning a little after it should stop. \"Go and get June,\" she says.
\"I'll wait. I'm very good at waiting.\"{{/face}}" CR>)>>

<ROUTINE MOTHER-F ()
	<COND (<EQUAL? ,WINNER ,MOTHER>
	       <TELL
"{{face mother}}\"Dinner is at 3:33,\" she says. \"Everything else can
wait.\"{{/face}}" CR>
	       <SETG P-CONT <>>
	       <SETG WINNER ,PLAYER>
	       <RFATAL>)
	      (<VERB? TELL HELLO>
	       <MOTHER-TALK>
	       <SETG P-CONT <>>
	       <SETG QUOTE-FLAG <>>
	       <RTRUE>)
	      (<VERB? EXAMINE>
	       <TELL
"She has Mother's green dress and Mother's hair and Mother's way of holding a
spoon.">
	       <COND (<G? ,SCORE 2>
		      <TELL
" Her smile is too wide for her face. It is wider every time you come
back.">)
		     (T
		      <TELL " You haven't seen her face yet.">)>
	       <CRLF>)
	      (<AND <VERB? SHOW GIVE> <EQUAL? ,PRSO ,LOCKET>>
	       <TELL
"{{face mother}}She looks at the locket for a long time. \"Where did you get
that,\" she says. It isn't a question.{{/face}}" CR>
	       <JIGS-UP "The lights go out, and she is very close in the dark.">
	       <RTRUE>)
	      (<AND <VERB? SHOW GIVE> <EQUAL? ,PRSO ,MUSIC-BOX>>
	       <TELL
"Mother won't look at it. Her shoulders go stiff and she stirs faster." CR>)
	      (<VERB? ATTACK MUNG KICK>
	       <TELL
"{{scare}}You grab her shoulder and pull her around, and she comes around
easily, like a door, and her smile opens all the way down." CR>
	       <JIGS-UP "You don't remember anything after that.">
	       <RTRUE>)
	      (<VERB? KISS>
	       <TELL
"You kiss her cheek. It's cold, and it moves under your mouth, as if she's
smiling wider." CR>)
	      (<VERB? LISTEN>
	       <TELL
"She's humming. It's almost the song she used to hum. The notes are in the
wrong places." CR>)
	      (<VERB? FOLLOW>
	       <TELL "She's right here." CR>)
	      (<VERB? TAKE>
	       <TELL "You don't want to touch her." CR>)>>

<ROUTINE MOTHER-TALK ()
	<COND (<G? ,MOTHER-AWAY 0>
	       <TELL
"{{face mother}}\"Shh,\" says Mother, swaying. \"This is our song.\"{{/face}}" CR>)
	      (<EQUAL? ,SCORE 1>
	       <TELL
"{{face mother}}\"You're letting the soup get cold,\" she says, and the pot
boils harder. \"Go and get your sister. She won't come down for me.\"{{/face}}" CR>)
	      (<EQUAL? ,SCORE 2>
	       <TELL
"{{face mother}}\"June's hiding again,\" she says. \"She hides from me. She
never used to hide from me.\"{{/face}}" CR>)
	      (T
	       <TELL
"{{face mother}}\"How many times is this,\" she says, pleasantly. \"I lose
count. I don't mind. We have all the time in the world, until 3:33.\"{{/face}}" CR>)>>

<ROUTINE STOVE-F ()
	<COND (<VERB? EXAMINE>
	       <TELL "An old iron stove. The burner under the pot glows. The knobs are all off." CR>)
	      (<VERB? LAMP-OFF TURN>
	       <TELL "The knobs are already off. The burner glows anyway." CR>)>>

<ROUTINE SOUP-F ()
	<COND (<VERB? EAT DRINK>
	       <ENDING-DINNER>
	       <RTRUE>)
	      (<VERB? EXAMINE LOOK-INSIDE>
	       <TELL
"Grey soup. Things turn over in it. You decide not to look for what they
are." CR>)
	      (<VERB? SMELL>
	       <TELL "Onions. Under the onions, a sweet smell like a closed room." CR>)
	      (<VERB? TAKE>
	       <TELL "The pot is too hot to touch, and you don't want it." CR>)>>

<ROUTINE KITCHEN-TABLE-F ()
	<COND (<VERB? EXAMINE>
	       <TELL
"Four places. Mother's, Dad's, June's, yours. Your bowl is already full. Dad's
place has dust on it." CR>)
	      (<VERB? CLIMB-ON BOARD>
	       <TELL "If you sit down, you'll eat. You know that much." CR>)>>

<ROUTINE PANTRY-F ()
	<COND (<AND <VERB? OPEN> <IN? ,MOTHER ,KITCHEN>>
	       <TELL
"{{face mother}}Before your hand touches the door, Mother says, \"Not before
dinner.\" She hasn't turned around. The door stays shut.{{/face}}" CR>)
	      (<AND <VERB? EXAMINE> <NOT <FSET? ,PANTRY ,OPENBIT>>>
	       <TELL "A narrow pantry door. Mother always kept the lamp oil in there." CR>)>>

<ROUTINE MOTHER-RETURNS ()
	<FCLEAR ,RADIO ,ONBIT>
	<MOVE ,MOTHER ,KITCHEN>
	<COND (<EQUAL? ,HERE ,LIVING-ROOM>
	       <TELL
"The song on the radio ends in static. Mother stops swaying, turns the dial
off without looking at it, and walks back into the kitchen." CR>)
	      (<EQUAL? ,HERE ,KITCHEN>
	       <TELL "Mother walks back into the kitchen and picks up her spoon." CR>
	       <COND (<HELD? ,LAMP>
		      <MOVE ,LAMP ,PANTRY>
		      <FCLEAR ,LAMP ,ONBIT>
		      <TELL
"{{face mother}}She holds out her hand, and you give her the lamp. You didn't
decide to. \"Not before dinner,\" she says, and puts it back.{{/face}}" CR>)>)
	      (<EQUAL? ,HERE ,UPSTAIRS-HALL ,CELLAR>
	       <TELL "Through the floor, you hear the radio go quiet." CR>)>
	<FCLEAR ,PANTRY ,OPENBIT>>

<ROUTINE LAMP-F ()
	<COND (<VERB? LAMP-ON BURN>
	       <COND (<FSET? ,LAMP ,ONBIT>
		      <TELL "It's already lit." CR>)
		     (<0? ,LAMP-FUEL>
		      <TELL "There's no oil left in it." CR>)
		     (<NOT <HELD? ,MATCHBOOK>>
		      <TELL "You have nothing to light it with." CR>)
		     (<0? ,MATCHES-LEFT>
		      <TELL "The matchbook is empty." CR>)
		     (T
		      <SETG MATCHES-LEFT <- ,MATCHES-LEFT 1>>
		      <FSET ,LAMP ,ONBIT>
		      <SETG LIT <LIT? ,HERE>>
		      <TELL
"You strike a match and touch it to the wick. The lamp catches, and a warm
circle of light opens around you." CR>
		      <COND (<NOT <FSET? ,HERE ,ONBIT>>
			     <CRLF>
			     <V-LOOK>)>
		      <RTRUE>)>)
	      (<VERB? LAMP-OFF>
	       <COND (<FSET? ,LAMP ,ONBIT>
		      <FCLEAR ,LAMP ,ONBIT>
		      <SETG LIT <LIT? ,HERE>>
		      <TELL "You turn the wick down until the flame goes out." CR>
		      <COND (<NOT ,LIT> <TELL "It is very dark." CR>)>
		      <RTRUE>)
		     (T
		      <TELL "It isn't lit." CR>)>)
	      (<VERB? EXAMINE>
	       <TELL "A kerosene lamp with a glass chimney. ">
	       <COND (<FSET? ,LAMP ,ONBIT> <TELL "It's lit. ">)>
	       <COND (<G? ,LAMP-FUEL 12> <TELL "The oil is most of the way up." CR>)
		     (<G? ,LAMP-FUEL 4> <TELL "There is some oil left." CR>)
		     (<G? ,LAMP-FUEL 0> <TELL "There's hardly any oil left." CR>)
		     (T <TELL "It's dry." CR>)>)
	      (<AND <VERB? TAKE> <IN? ,MOTHER ,KITCHEN> <EQUAL? ,HERE ,KITCHEN>>
	       <TELL
"{{face mother}}\"Not before dinner,\" says Mother, without turning around.{{/face}}" CR>)>>

"---------- the living room ----------"

<ROUTINE LIVING-ROOM-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"The living room is exactly the way it was. A grandfather clock stands against
the wall, a cabinet radio sits under the window, and a family photograph
stands on the mantel. ">
	       <COND (,RUG-MOVED
		      <TELL "A braided rug has been pushed aside, ">
		      <COND (<FSET? ,TRAP-DOOR ,OPENBIT>
			     <TELL "and a trap door stands open over a dark stairway. ">)
			    (T
			     <TELL "showing a trap door in the floor. ">)>)
		     (T
		      <TELL "A braided rug covers the middle of the floor. ">)>
	       <TELL "Stairs go up. The kitchen is east." CR>
	       <COND (<IN? ,MOTHER ,LIVING-ROOM>
		      <TELL CR
"Mother stands in front of the radio, swaying. Her head is turned toward you,
but her eyes are closed." CR>)>)>>

<ROUTINE CLOCK-F ()
	<COND (<VERB? EXAMINE READ>
	       <TELL "The clock says ">
	       <PRINT-TIME>
	       <TELL ". The pendulum hangs still, but the hands move." CR>)
	      (<VERB? LISTEN>
	       <TELL "It doesn't tick. It never ticked." CR>)
	      (<VERB? OPEN MOVE TURN>
	       <TELL "The hands won't move backward. You've tried." CR>)>>

<ROUTINE RADIO-F ()
	<COND (<VERB? LAMP-ON TURN PLAY MOVE PUSH>
	       <COND (<FSET? ,RADIO ,ONBIT>
		      <TELL "The song is still playing." CR>)
		     (T
		      <FSET ,RADIO ,ONBIT>
		      <TELL
"The radio warms up with a hum, and a slow song comes out of it, the kind that
played at weddings a long time ago." CR>
		      <COND (<IN? ,MOTHER ,KITCHEN>
			     <MOVE ,MOTHER ,LIVING-ROOM>
			     <SETG MOTHER-AWAY 6>
			     <COND (<EQUAL? ,HERE ,LIVING-ROOM>
				    <TELL CR
"{{face mother}}In the kitchen, the stirring stops. Mother walks in, stands in
front of the radio, and sways, with her eyes closed. \"Oh,\" she says. \"Our
song.\"{{/face}}" CR>)>)>)>
	       <RTRUE>)
	      (<VERB? LAMP-OFF>
	       <COND (<FSET? ,RADIO ,ONBIT>
		      <TELL "You switch the radio off." CR>
		      <COND (<G? ,MOTHER-AWAY 0>
			     <SETG MOTHER-AWAY 0>
			     <MOTHER-RETURNS>)
			    (T <FCLEAR ,RADIO ,ONBIT>)>)
		     (T
		      <TELL "It's already off." CR>)>)
	      (<VERB? EXAMINE>
	       <TELL "A wooden cabinet radio with one big dial. It's ">
	       <COND (<FSET? ,RADIO ,ONBIT> <TELL "on, playing a slow song." CR>)
		     (T <TELL "off." CR>)>)
	      (<VERB? LISTEN>
	       <COND (<FSET? ,RADIO ,ONBIT> <TELL "A slow song. Mother and Dad danced to it once, in this room." CR>)
		     (T <TELL "Nothing. Then, very faintly, somebody breathing, and then nothing." CR>)>)>>

<ROUTINE PHOTO-F ()
	<COND (<VERB? EXAMINE LOOK-INSIDE>
	       <TELL "A family photograph in a silver frame. ">
	       <COND (<EQUAL? ,SCORE 1>
		      <TELL
"Mother, Dad, June, and you, in front of the house. Everyone is smiling." CR>)
		     (<EQUAL? ,SCORE 2>
		      <TELL
"Mother, Dad, June, and you. Someone has scratched out June's face with a
fingernail." CR>)
		     (T
		      <TELL
"Mother, Dad, June, and you. June's face is scratched out. Someone has drawn
over Mother's mouth in pen, a smile that goes up to her ears. Dad is looking
at her, not the camera." CR>)>)
	      (<VERB? TAKE>
	       <TELL "It's glued to the mantel. You don't want to know why." CR>)>>

<ROUTINE RUG-F ()
	<COND (<VERB? MOVE PUSH RAISE LOOK-UNDER TAKE>
	       <COND (,RUG-MOVED
		      <TELL "You've already moved the rug aside." CR>)
		     (T
		      <SETG RUG-MOVED T>
		      <FCLEAR ,TRAP-DOOR ,INVISIBLE>
		      <THIS-IS-IT ,TRAP-DOOR>
		      <TELL
"You drag the rug to one side. Under it is a trap door with an iron ring,
and in the dust around it, small handprints." CR>)>)
	      (<VERB? EXAMINE>
	       <TELL "A braided rug. Mother made it. It's heavier than it looks." CR>)>>

<ROUTINE TRAP-DOOR-F ()
	<COND (<VERB? RAISE>
	       <PERFORM ,V?OPEN ,TRAP-DOOR>
	       <RTRUE>)
	      (<VERB? OPEN CLOSE>
	       <OPEN-CLOSE ,TRAP-DOOR
"You pull the ring. The trap door comes up and a smell of wet earth comes out.
Wooden steps go down into the dark."
"You let the trap door down.">)
	      (<VERB? LOOK-UNDER LOOK-INSIDE>
	       <COND (<FSET? ,TRAP-DOOR ,OPENBIT>
		      <TELL "Steps, going down into the dark." CR>)
		     (T <TELL "It's closed." CR>)>)>>

<ROUTINE STAIRS-F ()
	<COND (<VERB? CLIMB-UP CLIMB-FOO>
	       <DO-WALK ,P?UP>
	       <RTRUE>)
	      (<VERB? CLIMB-DOWN>
	       <DO-WALK ,P?DOWN>
	       <RTRUE>)>>

"---------- upstairs ----------"

<ROUTINE UPSTAIRS-HALL-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"A narrow hall at the top of the stairs. To the north is a yellow door with a
paper star taped to it. Your parents' room is south. The stairs go down." CR>
	       <COND (<NOT <FSET? ,JUNE-DOOR ,OPENBIT>>
		      <COND (<G? ,SCORE 1>
			     <TELL CR
"Behind the yellow door, someone is humming. Tonight you recognize the tune.
Mother used to hum it. The thing in the kitchen hums it wrong." CR>)
			    (T
			     <TELL CR "Behind the yellow door, someone is humming." CR>)>)>)>>

<ROUTINE JUNE-DOOR-F ()
	<COND (<AND <VERB? OPEN UNLOCK> <NOT <FSET? ,JUNE-DOOR ,OPENBIT>>>
	       <TELL
"It's locked from the inside. The humming stops." CR CR
"{{face june}}A small voice says, \"You're not her. Go away. Mom said don't
open the door for anybody who doesn't know the song.\"{{/face}}" CR>)
	      (<VERB? KNOCK>
	       <COND (<FSET? ,JUNE-DOOR ,OPENBIT>
		      <TELL "The door is open." CR>)
		     (T
		      <TELL
"{{face june}}\"Go away,\" says June, very quietly. \"She can hear
you.\"{{/face}}" CR>)>)
	      (<VERB? LISTEN>
	       <TELL "Humming. A lullaby, the tune going round and round." CR>)
	      (<VERB? ATTACK MUNG KICK>
	       <TELL
"You hit the door, hard. Downstairs, the stirring stops. You wait. After a
long time, it starts again." CR>)
	      (<VERB? EXAMINE>
	       <TELL "A yellow door with a paper star taped to it. It says JUNE in crayon." CR>)>>

<ROUTINE V-SING ()
	<COND (<AND <EQUAL? ,HERE ,UPSTAIRS-HALL> <NOT <FSET? ,JUNE-DOOR ,OPENBIT>>>
	       <TELL
"You hum what you remember of it. The humming behind the door stops." CR CR
"{{face june}}\"That's not it,\" says June. \"You don't remember it
right.\"{{/face}}" CR>)
	      (<IN? ,MOTHER ,HERE>
	       <TELL "Mother starts humming along, a beat behind you, in the wrong key." CR>)
	      (T
	       <TELL "Your voice sounds thin in the house." CR>)>>

<ROUTINE MUSIC-BOX-F ()
	<COND (<VERB? WIND PLAY OPEN>
	       <TELL
"You wind the key and lift the lid. A tin lullaby comes out, slow and a little
flat, the song Mother hummed when you were small." CR>
	       <COND (<AND <EQUAL? ,HERE ,UPSTAIRS-HALL>
			   <NOT <FSET? ,JUNE-DOOR ,OPENBIT>>>
		      <FSET ,JUNE-DOOR ,OPENBIT>
		      <TELL CR
"Behind the yellow door, the humming joins in, note for note. Then the lock
turns, and the door opens a crack." CR CR
"{{face june}}\"That's her song,\" says June. \"That's Mom's. The lady downstairs
doesn't know it.\"{{/face}}" CR>)
		     (<EQUAL? ,HERE ,JUNE-ROOM>
		      <TELL CR "June hums along, and for a moment she almost smiles." CR>)
		     (<IN? ,MOTHER ,HERE>
		      <TELL CR
"Mother's shoulders go stiff. She doesn't turn around. She presses her hands
over her ears until the song runs down." CR>)
		     (<NOT ,LIT>
		      <TELL CR "In the dark, something stops breathing to listen." CR>)>
	       <RTRUE>)
	      (<VERB? EXAMINE>
	       <TELL
"A small tin music box with a winding key. Painted on the lid, a woman in a
green dress holds a baby. Her smile is small and ordinary." CR>)>>

<ROUTINE JUNE-ROOM-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"A small room with a slanted ceiling. A night light in the shape of a moon
burns by the bed. Crayon drawings cover the walls, dozens of them. The hall is
south." CR>
	       <COND (<AND <IN? ,JUNE ,HERE> <NOT ,JUNE-FOLLOWING>>
		      <CRLF>
		      <COND (,JUNE-MET
			     <TELL "June sits on the bed with her knees up, watching you." CR>)
			    (T
			     <SETG JUNE-MET T>
			     <TELL
"{{face june}}A girl in a yellow dress sits on the bed with her knees pulled up.
She is eight. She has been eight for twenty years. \"You came back,\" she says.
\"You always come back. Where's Mom? My real mom.\"{{/face}}" CR>)>)>)>>

<ROUTINE JUNE-F ()
	<COND (<EQUAL? ,WINNER ,JUNE>
	       <COND (,JUNE-FOLLOWING
		      <TELL "{{face june}}\"I'm right here,\" she says. \"Go.\"{{/face}}" CR>)
		     (T
		      <TELL
"{{face june}}June shakes her head. \"Not till I know where Mom is.\"{{/face}}" CR>)>
	       <SETG P-CONT <>>
	       <SETG WINNER ,PLAYER>
	       <RFATAL>)
	      (<AND <VERB? SHOW GIVE> <EQUAL? ,PRSO ,LOCKET>>
	       <COND (,JUNE-FOLLOWING
		      <TELL "June holds your sleeve tighter. \"I know,\" she says." CR>)
		     (T
		      <SETG JUNE-FOLLOWING T>
		      <TELL
"{{face june}}June takes the locket in both hands and opens it. She looks at it
for a long time. \"That's Mom,\" she says. \"That's the real one.\" She closes it
and holds it against her chest. \"Okay. I'll come. Don't let the lady see
me.\"{{/face}}" CR CR
"She climbs off the bed and takes hold of your sleeve." CR>
		      <MOVE ,LOCKET ,JUNE>)>)
	      (<AND <VERB? SHOW GIVE> <EQUAL? ,PRSO ,MUSIC-BOX>>
	       <TELL
"{{face june}}\"That was under the house,\" says June. \"Dad put it with her. Is
she still down there?\"{{/face}}" CR>)
	      (<VERB? TELL HELLO>
	       <COND (,JUNE-FOLLOWING
		      <TELL
"{{face june}}\"Go the way Dad was going to go,\" June whispers. \"Under. Not past
the kitchen.\"{{/face}}" CR>)
		     (T
		      <TELL
"{{face june}}\"Mom said wait here till the lady stops smiling,\" June says. \"But
she never stops. Where's Mom? Did you find her?\"{{/face}}" CR>)>
	       <SETG P-CONT <>>
	       <SETG QUOTE-FLAG <>>
	       <RTRUE>)
	      (<VERB? EXAMINE>
	       <TELL
"Your sister. A yellow dress, bare feet, a scab on one knee that has never
healed. Her eyes look much older than eight." CR>)
	      (<VERB? KISS>
	       <TELL "You kiss the top of her head. Her hair smells like the cellar." CR>)
	      (<VERB? TAKE>
	       <TELL "She pulls away. \"I can walk,\" she says." CR>)>>

<ROUTINE DRAWINGS-F ()
	<COND (<VERB? EXAMINE READ>
	       <TELL
"Crayon drawings, dozens of them. The house. The well. A lady in green whose
smile runs off the edge of the paper. In one, a tall figure climbs a rope out
of the well, holding a smaller figure by the hand. In another, the tall figure
is sitting at the table, and the lady in green is smiling at it." CR>)>>

<ROUTINE PARENTS-ROOM-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"Your parents' room. The bed is made tight enough to bounce a coin on. A
nightstand stands beside it, and a tall mirror stands in the corner. The hall
is north." CR>)>>

<ROUTINE DIARY-F ()
	<COND (<VERB? READ LOOK-INSIDE OPEN>
	       <SETG DIARY-READ T>
	       <TELL
"Dad's handwriting, getting worse toward the end." CR CR
"\"Oct 3. It isn't Lena. It has her dress and her voice and it makes her soup,
but it smiles too long." CR CR
"Oct 9. It can't learn her song. When I wound Lena's music box it couldn't
stay in the room. June knows the difference. She won't open her door for
anything that doesn't know that song." CR CR
"Oct 12. I laid Lena in the root cellar in her green dress, with the box and
her locket. June asks every night where her mother is." CR CR
"Oct 14. The old coal tunnel runs from the root cellar to the bottom of the
well. With the bucket down, a person could climb out without going past the
kitchen. Tonight, before 3:33, I'm taking June out that way.\"" CR CR
"The rest of the pages are torn out." CR>)
	      (<VERB? EXAMINE>
	       <TELL "A leather diary with Dad's initials pressed into the cover." CR>)>>

<ROUTINE MIRROR-F ()
	<COND (<VERB? EXAMINE LOOK-INSIDE>
	       <COND (<AND <G? ,SCORE 1> <IN? ,MOTHER ,KITCHEN>>
		      <TELL
"{{scare}}In the mirror, Mother is standing in the doorway behind you,
smiling. You turn around. The doorway is empty. Downstairs, the spoon goes on
stirring." CR>)
		     (T
		      <TELL
"You look tired. You look older than you should, and June never will." CR>)>)
	      (<VERB? ATTACK MUNG>
	       <TELL "You raise your hand, and your reflection doesn't." CR>)>>

<ROUTINE BED-F ()
	<COND (<VERB? CLIMB-ON BOARD ENTER>
	       <TELL
"You lie down on your parents' bed and close your eyes, just for a second.
When you open them you're standing up, and you're outside." CR>
	       <LOOP-RESET>)
	      (<VERB? EXAMINE>
	       <TELL "Made tight. Nobody has slept in it for twenty years." CR>)>>

<ROUTINE V-SLEEP ()
	<TELL "You close your eyes, just for a second." CR>
	<LOOP-RESET>>

"---------- under the house ----------"

<ROUTINE CELLAR-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"A low cellar with a dirt floor. Shelves of jars line the walls, full of
something cloudy. Wooden steps go up to the trap door. A low opening leads
east." CR>)>>

<ROUTINE SHELVES-F ()
	<COND (<VERB? EXAMINE>
	       <TELL
"Preserves, labeled in Mother's handwriting. You lift one to the light, and
then you put it back, very carefully, label facing out." CR>)
	      (<VERB? TAKE>
	       <TELL "You don't want anything from these shelves." CR>)>>

<ROUTINE ROOT-CELLAR-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"A cold room dug out of the earth. In the middle of the floor someone has laid
out a green dress, neatly, the way you lay out clothes for church. There are
bones inside it. The cellar is west. An old tunnel leads east." CR>)>>

<ROUTINE DRESS-F ()
	<COND (<VERB? EXAMINE>
	       <TELL
"Mother's green dress, the one the thing in the kitchen is wearing. The bones
inside it are small and careful and have been here a long time. So you know,
now, who is stirring the soup." CR>)
	      (<VERB? TAKE MOVE>
	       <TELL "You leave her where Dad laid her." CR>)>>

<ROUTINE LOCKET-F ()
	<COND (<VERB? OPEN EXAMINE LOOK-INSIDE>
	       <TELL
"A silver locket. Inside is a tiny photograph of Mother holding June as a
baby. Mother is smiling. It is a small, ordinary smile. Engraved on the back:
LENA." CR>)>>

<ROUTINE TUNNEL-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"An old coal tunnel, shored up with rotten timbers. Water drips steadily. The
tunnel runs east toward the sound of more water, and back west to the root
cellar." CR>)>>

<ROUTINE WELL-BOTTOM-F (RARG)
	<COND (<EQUAL? .RARG ,M-LOOK>
	       <TELL
"You are standing in knee-deep water at the bottom of the well. Far above,
there is a small circle of night sky. ">
	       <COND (,BUCKET-DOWN
		      <TELL "The rope hangs down beside you, the bucket floating at your knees. ">)
		     (T
		      <TELL "The walls are slick. There is nothing to climb. ">)>
	       <TELL "The tunnel is west." CR>)>>
