Red [
    Title: "Localization experiment"
	Author: "Alvydas Vitkauskas"
	Needs: 'View
]

rows: 20
cols: 20
cells: rows * cols

elem: function [
	"Gets or sets the element at `r` row and `c` column"
	v [vector!] "Vector of elements"
	r [integer!] "Row"
	c [integer!] "Column"
	/set "Sets the element to the value" 
		value "Value to set the element to"
][
	either set [
		return v/(r - 1 * cols + c): value
	][
		return v/(r - 1 * cols + c)
	]
]

sense: func [value] [
	repeat i cells [
		if value <> pick field i [
			poke probs i 0.0
		]
	]
	; poke probs goal/1 - 1 * cols + goal/2 0.0
	probs / sum probs
]

move-robot: func [] [
	switch direction [
		"north" [dr: -1 dc:  0]
		"south" [dr:  1 dc:  0]
		"east"  [dr:  0 dc:  1]
		"west"  [dr:  0 dc: -1]
	]
	new-pos: robot + as-pair dr dc
	cannot-move: any [
		new-pos/1 < 1 
		new-pos/1 > rows
		new-pos/2 < 1
		new-pos/2 > cols
	]
	either cannot-move [
		wall-ahead direction
	][
		clear-ahead direction
		rotate-probs direction
		robot: new-pos
	]
]

wall-ahead: func [direction] [
	switch direction [
		"north" [
			repeat i cells [
				if i > cols [
					poke probs i 0.0
				]
			]
		]
		"south" [
			repeat i cells [
				if i <= (rows - 1 * cols) [
					poke probs i 0.0
				]
			]
		]
		"east" [
			repeat i cells [
				if i % cols <> 0 [
					poke probs i 0.0
				]
			]
		]
		"west" [
			repeat i cells [
				if i % cols <> 1 [
					poke probs i 0.0
				]
			]
		]
	]
	probs / sum probs
]

clear-ahead: func [direction] [
	switch direction [
		"north" [
			repeat i cells [
				if i <= cols [
					poke probs i 0.0
				]
			]
		]
		"south" [
			repeat i cells [
				if i > (rows - 1 * cols) [
					poke probs i 0.0
				]
			]
		]
		"east" [
			repeat i cells [
				if i % cols = 0 [
					poke probs i 0.0
				]
			]
		]
		"west" [
			repeat i cells [
				if i % cols = 1 [
					poke probs i 0.0
				]
			]
		]
	]
	probs / sum probs
]

rotate-probs: func [direction] [
	switch direction [
		"north" [
			move/part probs tail probs cols
		]
		"south" [
			move/part at tail probs negate cols probs cols
		]
		"east" [
			repeat r rows [
				from: r * cols
				to: from - cols + 1
				move at probs from at probs to
			]
		]
		"west" [
			repeat r rows [
				from: r * cols - cols + 1
				to: r * cols
				move at probs from at probs to
			]
		]
	]
]

choose-direction: func [] [
	idx: max-prob-index
	r: idx - 1 / cols + 1
	c: idx - 1 % cols + 1
	either position-known [
		case [
			r > goal/1 [direction: "north"]
			r < goal/1 [direction: "south"]
			c > goal/2 [direction: "west"]
			c < goal/2 [direction: "east"]
			; r = goal/1 [return "east"]		;-- have to improve here
			; c = goal/2 [return "south"]		;-- have to improve here
		]
	][
		case [
			direction = "north" [
				case [
					r > 1 [direction: "north"]
					all [r = 1 c < cols] [direction: "east"]
					true [direction: "west"]
				]				
			]
			direction = "east" [
				case [
					c < cols [direction: "east"]
					all [c = cols r < rows] [direction: "south"]
					true [direction: "north"]
				]				
			]
			direction = "south" [
				case [
					r < rows [direction: "south"]
					all [r = rows c > 1] [direction: "west"]
					true [direction: "east"]
				]				
			]
			direction = "west" [
				case [
					c > 1 [direction: "west"]
					all [c = 1 r > 1] [direction: "north"]
					true [direction: "south"]
				]				
			]
		]
	]
]

max-prob-index: func [] [
	max: 0.0
	idx: 1
	repeat i cells [
		elm: pick probs i
		if max < elm [max: elm idx: i]
	]
	if max = 1.0 [
		position-known: true
		msg/rate: 10
	]
	idx
]

print-field: func [] [
	repeat i length? field [
		prin pick field i
		prin " "
		if i % cols = 0 [print ""]
	]
	print ""
]

print-probs: func [] [
	width: 5
	repeat i length? probs [
		elm: form/part pick probs i width
		len: length? elm
		prin elm
		loop width - len [prin "0"]
		prin " "
		if i % cols = 0 [print ""]
	]
	print ""
]

field: make vector! append/dup [] 0 cells

goal: 0x0
robot: 0x0

paused: true
position-known: false
direction: "north"

probs: make vector! append/dup [] 1.0 / cells cells

field-size: 20x20 * (to-pair rows cols) + 20x20

redraw-field: func [panel] [
	foreach pane panel/pane [
		rr: pane/offset/y / 20
		cc: pane/offset/x / 20
		idx: rr - 1 * cols + cc
		intensity-float: (40 * log-e probs/:idx) + 255
		either intensity-float < 0 [
			intensity: 255
		][
			intensity: 255 - to-integer intensity-float
		]
		pane/color: as-color intensity 255 intensity
		if field/:idx = 1 [pane/color: black]
		if (as-pair rr cc) = goal [pane/color: red]
		if (as-pair rr cc) = robot [pane/color: blue]
	]
]

view [
	title "Localization"
	below
	p: panel field-size do [
		p/offset: 0x0
		p/pane: copy []
		repeat i rows [
			repeat j cols [
				append p/pane layout/only compose [
					at (as-pair i * 20 j * 20)
					base 19x19 white [
						row: face/offset/2 / 20
						col: face/offset/1 / 20
						switch face/color [
							255.255.255 [ ;-- white
								face/color: black
								elem/set field row col 1
							]
							0.0.0 [ ;-- black
								elem/set field row col 0
								case [
									goal = 0x0 [
										face/color: red
										goal: as-pair row col
									]
									robot = 0x0 [
										face/color: blue
										robot: as-pair row col
									]
									true [
										face/color: white
									]
								] 
							]
							255.0.0 [ ;-- red
								goal: 0x0
								face/color: white
							]
							0.0.255 [ ;-- blue
								robot: 0x0
								face/color: white
							]
						]
					]
				]
			]
		]
	]
	b: button 120x20 "Start" [
		if all [goal <> 0x0 robot <> 0x0][
			either paused [
				paused: false
				face/text: "Pause"
			][
				paused: true
				face/text: "Continue"
			]
		]
	]
	msg: text "" rate 2 on-time [
		unless any [
			paused 
			all [
				robot = goal
				1.0 = pick probs goal/1 - 1 * cols + goal/2
			]
		][
			choose-direction
			move-robot
			sense elem field robot/1 robot/2
			redraw-field p
			if all [
				robot = goal 
				1.0 = pick probs goal/1 - 1 * cols + goal/2
			][
				paused: true
				b/text: "Start"
				clear probs
				append/dup probs 0.0 cells
				redraw-field p
				clear probs
				append/dup probs 1.0 / cells cells
				goal: 0x0
				position-known: false
				direction: "north"
				msg/rate: 2
			]
		]
	]
	do [
		win-center: p/size/x / 2
		b/offset/x: win-center - (b/size/x / 2) + 20
		msg/offset/x: win-center - (msg/size/x / 2) + 20
	]
]