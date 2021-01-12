breed [Establishments Establishment]
breed [Neighborhoods Neighborhood]
breed [DeliveryRiders DeliveryRider]

globals[
  norders
  nidle
  ndelivery
  dridle
  drorder
  drdelivery
  drreturn
  drtired
  draveprofit
  drtotalprofit
  wsupply
  deliverytimelist
  avedeliverytime
  totaldeliverymade
  peaks
  a
  b
  %orders
  up?
  result
]

Establishments-own[
  supply
]

Neighborhoods-own[
  status                      ;idle, order, delivery
  targetestablishment
  pause3
  deliverytime
  successfulordersmade
]

DeliveryRiders-own[
  status                      ;idle, order, delivery, return
  energy
  dist
  profit
  targetestablishment
  targetneighborhood
  targetbdarea
  atestablishment
  atneighborhood
  atbdarea
  pause1
  pause2
]

to clear
  ca
end

to setup
  ca
  setup-business-district
  setup-establishments
  setup-neighborhoods
  setup-deliveryriders
  set totaldeliverymade 0
  set %orders 0.3
  set up? true
  set deliverytimelist [ ]
  set peaks 0
  update-globals
  update-display
  reset-ticks
end

to setup-business-district
  ask patches[
    if pxcor < 40 and pxcor > -40 and pycor < 40 and pycor > -40 [
      set pcolor blue
    ]
  ]
end

to setup-establishments
  create-Establishments NumberofEstablishments[
    set size 15
    let p one-of patches with [pcolor = blue]
    move-to p
    set shape "building store"
    set supply NumberofSupplyperEstablishment
  ]
end

to setup-neighborhoods
  create-Neighborhoods NumberofNeighborhoods[
    set size 10
    let p one-of patches with [pcolor = black]
    move-to p
    set shape "house"
    set status "idle"
    set targetestablishment nobody
    set pause3 0
    set deliverytime 0
    set successfulordersmade 0
  ]
end

to setup-deliveryriders
  create-DeliveryRiders NumberofDeliveryRiders[
    set size 10
    let p one-of patches with [pcolor = blue]
    move-to p
    set shape "car top"
    set status "idle"
    set energy MaximumDeliveriesperRider
    set dist 0
    set profit 0
    set targetestablishment nobody
    set targetneighborhood nobody
    set targetbdarea nobody
    set atestablishment false
    set atneighborhood false
    set pause1 EstablishmentTransactionTime
    set pause2 NeighborhoodTransactionTime
  ]
end

;--------------------------------------------------------------------------------------------------------------------------

to start
  update-globals
  update-display
  %orderschange
  countdown
  if wsupply != 0 [
    order
    while [ norders > 0 and dridle > 0 ][
    assign
    update-globals
    update-display
    ]
  ]
  move
  tick

  if (wsupply = 0 and all? deliveryriders [ status = "idle" or status = "tired"]) or (all? deliveryriders [ status = "tired" ]) or (all? neighborhoods [ successfulordersmade = NeighborhoodOrderLimit]) [   ;(wsupply = 0 and all? deliveryriders [status = "idle" or status = "tired"]) or all? deliveryriders [ energy = 0 ]
    update-globals
    update-display
    update-output
    stop
  ]
end

to update-output
  clear-output
  output-type(word "\n     --- SIMULATION RESULTS ---" "\n\n")
  if wsupply = 0 [
    output-type(word "All establishments have 0 supply."  "\n")
    set result "no more establishments with supply"
  ]
  if all? deliveryriders [ status = "tired" ] [
    output-type(word "All riders have reached their\nmaximum deliveries."  "\n")
    set result "no more riders with energy"
  ]
  if all? neighborhoods [ successfulordersmade = NeighborhoodOrderLimit] [
    output-type(word "All neighborhoods have reached\ntheir order limit."  "\n")
    set result "no more neighborhoods with order"
  ]
  output-type(word "\nTotal Time Taken:\t" ticks "\n")
  output-type(word "Total Peaks Recorded:\t" peaks "\n")
  output-type(word "Average Delivery Time:\t" avedeliverytime "\n\n")

  output-type(word "Total Delivery Made:\t" totaldeliverymade "\n")
  output-type(word "Total Supply Left:\t" wsupply "\n\n")

  output-type(word "Mean Individual Profit:\t" draveprofit "\n")
  output-type(word "Total Profit:\t\t" drtotalprofit "\n")

end

to countdown
  ask neighborhoods with [pause3 > 0][
    set pause3 pause3 - 1
  ]
  ask neighborhoods with [ status = "order" or status = "delivery" ][
    set deliverytime deliverytime + 1
  ]
end

to %orderschange
  ifelse up? = true [
    set %orders %orders + 0.001
    if %orders >= 0.7 [
      set up? false
      set peaks peaks + 1
    ]
  ][
    set %orders %orders - 0.001
    if %orders <= 0.3 [
      set up? true
    ]
  ]
end

to update-globals
  set norders (count neighborhoods with [status = "order" ])
  set nidle (count neighborhoods with [status = "idle" ])
  set ndelivery (count neighborhoods with [status = "delivery" ])
  set dridle (count deliveryriders with [status = "idle" ])
  set drorder (count deliveryriders with [status = "order" ])
  set drdelivery (count deliveryriders with [status = "delivery" ])
  set drreturn (count deliveryriders with [status = "return" ])
  set drtired (count deliveryriders with [status = "tired" ])
  set draveprofit (mean [profit] of deliveryriders)
  set drtotalprofit (sum [profit] of deliveryriders)
  set wsupply (sum [supply] of establishments)
  if not empty? deliverytimelist [
    set avedeliverytime (mean deliverytimelist)
  ]
end

to update-display
  ask establishments[
    ifelse supply > 0 [
      set color green
    ][
      set color red
    ]
  ]

  ask neighborhoods[
    set color (ifelse-value
      status = "idle" [gray]
      status = "order" [orange]
      status = "delivery" [green]
    )
  ]

  ask deliveryriders[
   set color (ifelse-value
      status = "idle" [gray]
      status = "order" [orange]
      status = "delivery" [green]
      status = "return" [yellow]
      status = "tired" [red]
   )

    if targetestablishment != nobody [
      ask deliveryriders-on targetestablishment[
        set atestablishment true
      ]
    ]

    if targetneighborhood != nobody [
      ask deliveryriders-on targetneighborhood[
        set atneighborhood true
      ]
    ]

    if targetbdarea != nobody [
      ask deliveryriders-on targetbdarea[
        set atbdarea true
      ]
    ]
  ]
end

to order
  if ( norders + ndelivery ) < ( %orders * NumberofNeighborhoods) [
    ask up-to-n-of 1 neighborhoods with [status = "idle" and pause3 = 0 and successfulordersmade < NeighborhoodOrderLimit][
      set status "order"
      let r one-of establishments with [ supply > 0 ]
      ask r [
        set supply supply - 10
      ]
      set targetestablishment r
    ]
  ]
end

to assign
  ask deliveryriders with [ energy = 0 and atbdarea = true ][
    set status "tired"
  ]

  ask up-to-n-of 1 deliveryriders with [ status = "idle" and energy > 0][
    set a one-of neighborhoods with [ status = "order" ]
    ask a [
      set b targetestablishment
      set status "delivery"
    ]
    set targetneighborhood a
    set targetestablishment b
    set status "order"
  ]
end

to move
  ask deliveryriders with [status = "order"][
    ifelse atestablishment [
      transact1
    ][
      pickup
    ]
  ]

  ask deliveryriders with [status = "delivery"][
    ifelse atneighborhood[
      transact2
    ][
      deliver
    ]
  ]

  ask deliveryriders with [status = "return"][
    ifelse atbdarea[
      transact3
    ][
      return
    ]
  ]

end

to pickup
  if targetestablishment != nobody [
    face targetestablishment
    forward 1
  ]
end

to transact1
  set pause1 pause1 - 1
  if pause1 = 0 [
    set status "delivery"
  ]
end

to deliver
  face targetneighborhood
  forward 1
  set dist dist + 1
end

to transact2
  set pause2 pause2 - 1
  if pause2 = 0 [
    set status "return"
    ask targetneighborhood [
      set status "idle"
      set targetestablishment nobody
      set pause3 NeighborhoodRepeatOrderTime
      set successfulordersmade successfulordersmade + 1
      set deliverytimelist lput deliverytime deliverytimelist
      set deliverytime 0
      set totaldeliverymade totaldeliverymade + 1
    ]
    set profit ( profit + FixedServiceFee + (DeliveryFeePerKM * dist * 0.1) )
    set dist 0
    set targetbdarea one-of patches with [pcolor = blue]
    set atbdarea false
  ]
end

to return
  face targetbdarea
  forward 1
end

to transact3
  set status "idle"
  set energy energy - 1
  set targetestablishment nobody
  set targetneighborhood nobody
  set targetbdarea nobody
  set targetbdarea nobody
  set atestablishment false
  set atneighborhood false
  set pause1 EstablishmentTransactionTime
  set pause2 NeighborhoodTransactionTime
end
@#$#@#$#@
GRAPHICS-WINDOW
4
11
513
521
-1
-1
1.783
1
10
1
1
1
0
0
0
1
-140
140
-140
140
1
1
1
ticks
30.0

BUTTON
519
10
582
43
NIL
clear
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

BUTTON
588
10
651
43
NIL
setup
NIL
1
T
OBSERVER
NIL
X
NIL
NIL
1

SLIDER
520
66
721
99
NumberofEstablishments
NumberofEstablishments
1
30
20.0
1
1
NIL
HORIZONTAL

SLIDER
520
102
721
135
NumberofNeighborhoods
NumberofNeighborhoods
1
200
100.0
1
1
NIL
HORIZONTAL

BUTTON
657
10
720
43
NIL
start
T
1
T
OBSERVER
NIL
C
NIL
NIL
0

SLIDER
520
139
721
172
NumberofDeliveryRiders
NumberofDeliveryRiders
1
50
50.0
1
1
NIL
HORIZONTAL

PLOT
727
72
1040
289
Neighborhoods Status
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"idle" 1.0 0 -7500403 true "" "plot nidle"
"with orders" 1.0 0 -955883 true "" "plot norders"
"on delivery" 1.0 0 -10899396 true "" "plot ndelivery"

SLIDER
520
324
719
357
EstablishmentTransactionTime
EstablishmentTransactionTime
10
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
521
362
720
395
NeighborhoodTransactionTime
NeighborhoodTransactionTime
10
100
10.0
1
1
NIL
HORIZONTAL

PLOT
725
305
1038
522
Delivery Riders Status
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"idle" 1.0 0 -7500403 true "" "plot dridle"
"with orders" 1.0 0 -955883 true "" "plot drorder"
"on delivery" 1.0 0 -10899396 true "" "plot drdelivery"
"returning" 1.0 0 -1184463 true "" "plot drreturn"
"tired" 1.0 0 -2674135 true "" "plot drtired"

MONITOR
1046
123
1154
168
Total Supply Left
wsupply
17
1
11

SLIDER
520
233
721
266
NumberofSupplyperEstablishment
NumberofSupplyperEstablishment
100
1000
1000.0
10
1
NIL
HORIZONTAL

SLIDER
522
398
720
431
NeighborhoodRepeatOrderTime
NeighborhoodRepeatOrderTime
10
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
519
449
717
482
FixedServiceFee
FixedServiceFee
10
100
60.0
10
1
NIL
HORIZONTAL

SLIDER
519
487
717
520
DeliveryFeePerKM
DeliveryFeePerKM
0
10
4.0
1
1
NIL
HORIZONTAL

MONITOR
1159
73
1323
118
Riders Mean Individual Profit
draveprofit
2
1
11

MONITOR
1046
73
1154
118
Total Delivery Made
totaldeliverymade
17
1
11

MONITOR
1159
123
1323
168
Average Delivery Time
avedeliverytime
2
1
11

SLIDER
520
195
721
228
MaximumDeliveriesperRider
MaximumDeliveriesperRider
1
20
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
527
49
677
68
Agent Quantities
12
0.0
1

TEXTBOX
527
178
677
197
Agent Attributes
12
0.0
1

TEXTBOX
528
307
678
326
Time Variables
12
0.0
1

TEXTBOX
527
433
677
452
Delivery Pricing
12
0.0
1

TEXTBOX
732
49
882
68
Simulation Plots
15
0.0
1

OUTPUT
1048
173
1325
523
11

TEXTBOX
1056
49
1206
68
Monitors and Output
15
0.0
1

TEXTBOX
742
10
1341
41
An Agent-Based Modelling of Online Food Delivery Services
22
0.0
1

TEXTBOX
730
27
1326
45
-------------------------------------------------------------------------------------
20
0.0
1

SLIDER
521
271
721
304
NeighborhoodOrderLimit
NeighborhoodOrderLimit
5
10
5.0
1
1
NIL
HORIZONTAL

PLOT
8
552
345
729
Number of Orders
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"allowed" 1.0 0 -16777216 true "" "plot NumberofNeighborhoods * %orders"
"actual" 1.0 0 -7500403 true "" "plot norders"

PLOT
353
552
689
729
Neighborhood Successful Orders Made
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"0" 1.0 0 -16777216 true "" "plot count neighborhoods with [ successfulordersmade = 0 ]"
"1" 1.0 0 -7500403 true "" "plot count neighborhoods with [ successfulordersmade = 1 ]"
"2" 1.0 0 -2674135 true "" "plot count neighborhoods with [ successfulordersmade = 2 ]"
"3" 1.0 0 -955883 true "" "plot count neighborhoods with [ successfulordersmade = 3 ]"
"4" 1.0 0 -6459832 true "" "plot count neighborhoods with [ successfulordersmade = 4 ]"
"5" 1.0 0 -1184463 true "" "plot count neighborhoods with [ successfulordersmade = 5 ]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="repeat" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="EstVSNei" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofEstablishments" first="5" step="5" last="30"/>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofNeighborhoods" first="5" step="5" last="200"/>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="EstVSDR" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofEstablishments" first="5" step="5" last="30"/>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofDeliveryRiders" first="5" step="5" last="50"/>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NeiVSDR" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofNeighborhoods" first="5" step="5" last="200"/>
    <steppedValueSet variable="NumberofDeliveryRiders" first="5" step="5" last="50"/>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FSFVSDFperKM" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="FixedServiceFee" first="10" step="5" last="100"/>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="DeliveryFeePerKM" first="0" step="1" last="10"/>
  </experiment>
  <experiment name="ETimeVSNTime" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <steppedValueSet variable="EstablishmentTransactionTime" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NeighborhoodTransactionTime" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ETimeVSNRTime" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <steppedValueSet variable="EstablishmentTransactionTime" first="10" step="10" last="100"/>
    <steppedValueSet variable="NeighborhoodRepeatOrderTime" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NTimeVSNRTime" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NeighborhoodRepeatOrderTime" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NeighborhoodTransactionTime" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="edited backup" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>drtotalprofit</metric>
    <metric>totaldeliverymade</metric>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="edited" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>drtotalprofit</metric>
    <metric>totaldeliverymade</metric>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofNeighborhoods" first="10" step="10" last="200"/>
    <steppedValueSet variable="NumberofDeliveryRiders" first="5" step="5" last="50"/>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="complete (est,nei,dr)" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <steppedValueSet variable="NumberofEstablishments" first="5" step="5" last="30"/>
    <steppedValueSet variable="NumberofNeighborhoods" first="10" step="10" last="200"/>
    <steppedValueSet variable="NumberofDeliveryRiders" first="5" step="5" last="50"/>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="complete (time)" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="EstablishmentTransactionTime" first="10" step="10" last="100"/>
    <steppedValueSet variable="NeighborhoodTransactionTime" first="10" step="10" last="100"/>
    <steppedValueSet variable="NeighborhoodRepeatOrderTime" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="complete (price)" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="FixedServiceFee" first="10" step="10" last="100"/>
    <steppedValueSet variable="DeliveryFeePerKM" first="0" step="1" last="10"/>
  </experiment>
  <experiment name="complete (energy)" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <steppedValueSet variable="MaximumDeliveriesperRider" first="5" step="5" last="20"/>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="complete (supply)" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofSupplyperEstablishment" first="100" step="100" last="1000"/>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="complete (order limit)" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NeighborhoodOrderLimit" first="5" step="1" last="10"/>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="add more supply or create new estab" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <enumeratedValueSet variable="MaximumDeliveriesperRider">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofSupplyperEstablishment" first="100" step="100" last="1000"/>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofEstablishments" first="1" step="1" last="30"/>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofDeliveryRiders">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="increase dr limit or employ new ones" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>start</go>
    <metric>result</metric>
    <metric>ticks</metric>
    <metric>peaks</metric>
    <metric>avedeliverytime</metric>
    <metric>totaldeliverymade</metric>
    <metric>wsupply</metric>
    <metric>draveprofit</metric>
    <metric>drtotalprofit</metric>
    <steppedValueSet variable="MaximumDeliveriesperRider" first="1" step="1" last="20"/>
    <enumeratedValueSet variable="NumberofSupplyperEstablishment">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodOrderLimit">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofEstablishments">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberofNeighborhoods">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="NumberofDeliveryRiders" first="1" step="1" last="50"/>
    <enumeratedValueSet variable="EstablishmentTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodTransactionTime">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NeighborhoodRepeatOrderTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixedServiceFee">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DeliveryFeePerKM">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
