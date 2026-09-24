"HOLLOW for
		HOLLOW HOUSE
	An interactive horror, built from the Zork I source.
	Zork I (c) Infocom. Source released under the MIT license by Microsoft, 2025.
	Hollow House story and code (c) 2026 NICOH-YAY, MIT license."

<VERSION ZIP>

<CONSTANT RELEASEID 1>

;"0 is no Zork game, so the engine leaves out its Zork I/II/III branches"
<SETG ZORK-NUMBER 0>

<SET REDEFINE T>

<OR <GASSIGNED? ZILCH>
    <SETG WBREAKS <STRING !\" !,WBREAKS>>>

<PRINC "Hollow House
">

<FREQUENT-WORDS?>

<INSERT-FILE "engine/gmacros" T>
<INSERT-FILE "engine/gsyntax" T>

"verbs Hollow House adds to the Zork parser"
<SYNTAX SHOW OBJECT (HELD CARRIED) TO OBJECT (FIND ACTORBIT) (IN-ROOM) = V-SHOW>
<SYNTAX SHOW OBJECT (FIND ACTORBIT) (IN-ROOM) OBJECT (HELD CARRIED) = V-SSHOW>
<SYNTAX SING = V-SING>
<SYNONYM SING HUM WHISTLE>
<SYNTAX KNOCK ON OBJECT = V-KNOCK>
<SYNTAX SLEEP = V-SLEEP>
<SYNTAX LIE = V-SLEEP>
<SYNTAX LIE ON OBJECT = V-SLEEP>
<SYNONYM SLEEP NAP REST>

<INSERT-FILE "hdungeon" T>
<INSERT-FILE "engine/gglobals" T>

<PROPDEF SIZE 5>
<PROPDEF CAPACITY 0>
<PROPDEF VALUE 0>
<PROPDEF TVALUE 0>

<INSERT-FILE "engine/gclock" T>
<INSERT-FILE "engine/gmain" T>
<INSERT-FILE "engine/gparser" T>
<INSERT-FILE "engine/gverbs" T>
<INSERT-FILE "hactions" T>

<ROUTINE V-SHOW ()
	<TELL "It doesn't seem interested." CR>>

<ROUTINE V-SSHOW ()
	<PERFORM ,V?SHOW ,PRSI ,PRSO>
	<RTRUE>>
