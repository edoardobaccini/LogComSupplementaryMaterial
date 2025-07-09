;Model of Group Discussion with Myside Bias, for the paper "The wisdom of the small crowds: Myside bias and group discussion" forthcoming in Journal of Artificial Societies and Social Simulations

breed [ arguers arguer ] ;we call the agents in our model arguers

arguers-own [
  prior ;this is an agent's prior degree of belief in the correct alternative of the binary issue
  degree-of-belief ;this is an agent's degree of belief in the correct alternative after updates
  self-gamma ;this is an agent's radicality parameter gamma
  p-color; color of the pen representing an arguer's belief
]

globals [
arg-list ;this is the list of the arguments that agents exchange, ordered accoridng to the order the arguments are presented
prior-list ;this is the list of the agents' priors
degree-belief-list ; this is the list of the agents' degrees of belief after update
  correct-at-start ;this variable tells the number of agents that have a prior belief strictly bigger than 0.5 in the correct alternative (prior > 0.5)
non-maj ;list used to calculate the probability of a majority of agents casting a correct vote
  wrong-prior
  wrong-degrees
  wrong-arg
]

to setup ;this part initiate the model

  clear-all

  reset-ticks

  create-arguers n-agents ; a number of agents is created. The number of agent is set by the variable "n-agents"

   layout-circle sort arguers 10 ;the agents are set in a circle for no particular reason

  set-priors ; the prior degrees of belief of the agents are set



  set-colors ; agents are assigned a color depending on their prior belief

  set-gamma ; the radicality parameter gamma is distributed across the group of agents

  set arg-list [] ;at the setup, the list of argument is empty

  if ( probabilistic-majority-vote)[majority-vote]

  set wrong-prior false ;these three variables check that we do not get undesirable approximation error.

  set wrong-degrees false

  set wrong-arg false

  setup-plots

end

to set-priors ;in this part of the code, each agent is assigned a prior degree of belief drawn from a beta distribution with  alpha= alpha-pop and beta= beta-pop
              ; the value of the variable Majority determines the type of majority in the initial group:
              ; correct or incorrect ("any");
              ; correct, strictly more than half the arguers have an initial prior > 0.5 ("correct");
              ; incorrect, stricly more than half of the arguers have an initial prior <= 0.5 ("incorrect").


  set prior-list []

  (ifelse (Majority = "any") [while [(length prior-list < n-agents) or

    (mean prior-list <= min-group-competence) or

    (any? arguers with [prior >= 1]) or

    (any? arguers with [prior = 0]) or

    (all? arguers [prior >= 0.5]) or


        (all? arguers [prior <= 0.5])] [

    set prior-list []

     ask arguers[


set prior precision (random-beta alpha-pop beta-pop) 5

    set degree-of-belief prior

      set prior-list lput prior prior-list

    ]]] (Majority = "correct") [while[(length prior-list < n-agents) or

    (mean prior-list <= min-group-competence) or

    (any? arguers with [prior >= 1]) or

    (any? arguers with [prior = 0]) or

    (all? arguers [prior >= 0.5]) or


    (all? arguers [prior <= 0.5]) or ((count arguers with [prior > 0.5]) <= (count arguers with [prior <= 0.5]))][ set prior-list []

     ask arguers[


set prior precision (random-beta alpha-pop beta-pop) 5

    set degree-of-belief prior

      set prior-list lput prior prior-list

    ]]](Majority = "incorrect")[while[(length prior-list < n-agents) or

    (mean prior-list <= min-group-competence) or

    (any? arguers with [prior >= 1]) or

    (any? arguers with [prior = 0]) or

    (all? arguers [prior >= 0.5]) or


      (all? arguers [prior <= 0.5]) or ((count arguers with [prior > 0.5]) >= (count arguers with [prior <= 0.5]))][

    set prior-list []

     ask arguers[


set prior precision (random-beta alpha-pop beta-pop) 5

    set degree-of-belief prior

      set prior-list lput prior prior-list

    ]]])

  set correct-at-start count arguers with [prior > 0.5]


end

to set-colors

   ask arguers  [ ifelse(prior > 0.5)[
      set color red ;arguers that have a strictly higher than chance prior in the correct answer are colored red,

    ][

      ifelse(prior < 0.5)[  ;arguers that have strictly lower than change prior in the correct answer are blue


    set color blue][ ;arguers that have prior 0.5 are initially white

    set color white]

  ]]

  ask arguers [ let l random-float 1

    set p-color (one-of base-colors) / l ]


end

to set-gamma

  ;this part of the code determines how the radicality parameter gamma is distributed among the group of agents.
  ;gamma can be distributed in three different ways, by selecting different values for the variable distribute-gamma
  ; First, by selecting "uniform", each agent is assigned the same value of gamma that is set in the slider gamma
  ; Second, by selecting "across", for each agent, its parameter gamma is drawn from a beta-distribution with alpha=alpha-across and beta=beta-across (where alpha-across and beta-across can be fixed in the corresponding sliders)
  ; Third, by selecting "within", for each agent with b>=0.5, the parameter gamma is drawn from the beta distribution with parameters alpha-correct, beta-correct (sliders);
  ;for each agent with b<0.5, the parameter gamma is drawn from the beta distribution with parameters alpha-incorrect beta-incorrect (sliders).
  ;In all the cases for beta distribution, we require that gamma<1, for reason that we give in the paper

  if(distribute-gamma = "uniform")[

   ask arguers[ set self-gamma gamma ]

 ]

  if(distribute-gamma = "across")[

   ask arguers [

      set self-gamma 1

      while[precision self-gamma 5 >= 1][set self-gamma precision random-beta alpha-across beta-across 5]

    ]
  ]

   if(distribute-gamma = "within")[

    ask arguers with [prior >= 0.5] [

      set self-gamma 1

      while[precision self-gamma 5 >= 1][set self-gamma precision random-beta alpha-correct beta-correct 5]

    ]

    ask arguers with [prior < 0.5] [

      set self-gamma 1

      while[precision self-gamma 5 >= 1][ set self-gamma precision random-beta alpha-incorrect beta-incorrect 5]

    ]

  ]

end

to one-round-update

  ;This part encodes the discussion process, where agents exchange likelihood ratios.

  ;The simulation stops if all agents supporting the correct side of the issue have b > 0.99999, and simultaneously all the agents supporting the incorrect side have b<0.00001

  if(not any? arguers with [degree-of-belief = 0.5] and (all? arguers with [degree-of-belief > 0.5] [degree-of-belief >= 0.99999] and all? arguers with [degree-of-belief < 0.5] [degree-of-belief <= 0.00001] ))[
   stop
  ]


  let l random n-agents ;At the start of each argumentation round a random agent is selected


   ; The agent then presents an argument (argue). The single argumentation round ends here. In the next argumentation round a new agent will randomly selected, present an argument and so on ...
  ask arguer l [
argue
    ]

  if (probabilistic-majority-vote) [majority-vote

    ;print  precision sum (sublist (item (n-agents - 1) non-maj) ((n-agents + 1) / 2) (n-agents + 1) ) 5

  ]

  if(any? arguers with [prior >= 1])[set wrong-prior true]
  if(any? arguers with [degree-of-belief >= 1])[set wrong-degrees true]
  if(not empty? arg-list and max arg-list > 1000)[set wrong-arg true]


tick

  ;in this new version, the degree-of-belief of each agent after an argumentation round can be seen in the plot "Evolution of the Agents' Degrees of Belief"

end

to argue ;this part encodes how agents draw the arguments that they present.
         ;in general, agents with degree-of-belief > 0.5 present arguments that are confirming of the correct alternative (and disconfirming of the incorrect alternative), which are numbers strictly smaller than 1
         ;agents with degree-of-belief < 0.5 presents arguments that are disconfirming of the incorrect alternative (and disconfirming of the correct alternative), which are numbers strictly bigger than 1
         ;this way, we model agents that produce arguments supporting their own preferred side of the issue

  let arg 0 ;we define a variable arg, and initially give the number 0

  while[precision arg 5 < 0.001 or precision arg 5 > 1 ][

    set arg precision (random-beta alpha-arg beta-arg) 5] ;arg is assigned a value between 0 and 1 and strictly bigger than 0, that is drawn from a beta-distribution that is

   (ifelse(degree-of-belief > 0.5)[ ;if the agent's degree of belief > 0.5, then the agent asks every other agent to update their degree of belief using arg as an argument (note indeed that arg is a confirming argument, since it is a number between 0 and 1)

        ask other arguers [

          let perc-arg precision (perceived-likelihood-update arg degree-of-belief self-gamma) 5 ;each of the other arguers does the following: first, calculates the perceived-likelihood of arg, depending on its degree of belief and self-gamma,
                                                                                                 ;using the function "perceived-likelihood-update"

        (ifelse( precision (bayesian-update degree-of-belief perc-arg) 5 < 1 and precision (bayesian-update degree-of-belief perc-arg) 5 != 0)[set degree-of-belief precision (bayesian-update degree-of-belief perc-arg) 5] ;then the agent update its degree of belief in the light
                                                                                                                                                                                                                              ;of the perceived argument that has just computed

          (precision (bayesian-update degree-of-belief perc-arg) 5 >= 1)[set degree-of-belief 0.99999]  ; due to problems with approximation errors, we set that the maximum and minimum degree of belief are 0.99999 and 0.00001, respectively. This respects the fact that, since
                                                                                                       ; we have not allowed arg to assume value 0, we should not observe any agent with degree of belief = 1
          (precision (bayesian-update degree-of-belief perc-arg) 5 = 0 )[set degree-of-belief 0.00001])

          ifelse(degree-of-belief > 0.5)[ ;each agent then changes its color depending on its new degree-of-belief
      set color red][

      ifelse(degree-of-belief < 0.5)[

    set color blue][

    set color white]

        ]]

     set arg-list lput arg arg-list ; the argument arg that the agent has produced is then added at the end of the list of the arguments of the discussion

      ]
          (degree-of-belief  < 0.5)[ ;if the agent's degree of belief < 0.5, then the agent asks every other agent to update their degree of belief using 1 / arg (the inverse of arg) as an argument (note indeed that 1 / arg is bigger than 1, since arg is smaller than 1)

        ask other arguers [ ;each arguer first, calculates the perceived-likelihood of 1 / arg, depending on its degree of belief and self-gamma,
                            ;using the function "perceived-likelihood-update"
                            ; then updates its degree of belief in the light of the perceived likelihood of 1 / arg
                            ;afterwards, the agent changes color according to its degree of belief
          let perc-arg precision (perceived-likelihood-update precision (1 / arg) 5 degree-of-belief self-gamma) 5
          (ifelse( precision (bayesian-update degree-of-belief perc-arg) 5 < 1 and precision (bayesian-update degree-of-belief perc-arg) 5 != 0)[set degree-of-belief precision (bayesian-update degree-of-belief perc-arg) 5]
          (precision (bayesian-update degree-of-belief perc-arg) 5 >= 1)[set degree-of-belief 0.99999]
          (precision (bayesian-update degree-of-belief perc-arg) 5 = 0 )[set degree-of-belief 0.00001])

 ifelse(degree-of-belief > 0.5)[
      set color red][
      ifelse(degree-of-belief < 0.5)[
    set color blue][
    set color white]
    ]
          ]
      set arg-list lput precision (1 / arg) 5 arg-list ;the argument 1/arg is inserted at the end of the list of the arguments of the discussion
      ]
       )

end

to majority-vote ;this new command calulates the probability that a majority of the agents will cast a correct vote (for a group of odd size), under the assumption that the degree-of-belief of an agent represents the chance that one agent will vote for the correct answer
                 ;the probabilities after each argumentation round appear in the plot "Condorcet-Majority"

  let base (list precision (1 - [degree-of-belief] of arguer 0) 5  precision [degree-of-belief] of arguer 0 5 )

  let i 2

  set non-maj []

  set non-maj fput base non-maj

  let c 0

  while [i != n-agents + 1][

    let relevant item (i - 2) non-maj

    let f []

    while[c != i + 1] [



      if(c = 0)[

        set f lput precision ((item c relevant) * (1 - ([degree-of-belief] of arguer (i - 1))) ) 5 f]

      if (c = i) [set f lput precision (last relevant * (([degree-of-belief] of arguer (i - 1))) ) 5 f]


      if (c != 0 and c != i)[
        set f lput precision (((item (c) relevant) * (1 - [degree-of-belief] of arguer (i - 1))) + (((item (c - 1) relevant)) * ([degree-of-belief] of arguer (i - 1)))) 5 f

      ]

             set c c + 1

    ]

;    print sum f

    set non-maj lput f non-maj

;    print non-maj

    set c 0

    set i i + 1

  ]

end

to-report random-beta [ #alpha #beta ] ;beta-distribution
  let XX random-gamma #alpha 1
  let YY random-gamma #beta 1
   report XX / (XX + YY)
end

to-report perceived-likelihood-update [a b c] ;this is the function that determines the perceived likelihood ratio
ifelse (b >= 0.5)[
    report (2 * a) * ((1 - b) ^ (c) /(b ^ (c) + (1 - b) ^ (c)))]
  [report (a / 2) * ((b ^ (c) + (1 - b) ^ (c)) / (b ^ c)) ]

end

to-report bayesian-update [a b] ;Bayesian update

   report ((a) / (a +  ((b) * (1 - a))))

end
@#$#@#$#@
GRAPHICS-WINDOW
152
18
589
456
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
748
11
920
44
n-agents
n-agents
2
501
6.0
1
1
NIL
HORIZONTAL

BUTTON
606
142
669
175
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1310
68
1482
101
gamma
gamma
0
1
0.17
0.01
1
NIL
HORIZONTAL

BUTTON
606
219
739
252
start
one-round-update
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1024
11
1186
56
initial-average competence
precision mean prior-list 2
17
1
11

MONITOR
1190
11
1247
56
maj
max list count arguers with [prior > 0.5] count arguers with [prior < 0.5] = count arguers with [prior > 0.5]
17
1
11

SLIDER
748
93
952
126
min-group-competence
min-group-competence
0
1
0.5
0.01
1
NIL
HORIZONTAL

PLOT
605
270
953
457
number-of-correct-agents
NIL
NIL
0.0
20.0
0.0
40.0
true
false
"set-plot-y-range 0 n-agents" "set-plot-x-range 0 ticks + 1"
PENS
"pen-0" 1.0 0 -2674135 true "" "plot (n-agents + 1) / 2"
"pen-1" 1.0 0 -13840069 true "" "ifelse(ticks = 0)[plot count arguers with [prior > 0.5]][plot count arguers with [degree-of-belief > 0.5]]"

CHOOSER
1507
10
1645
55
distribute-gamma
distribute-gamma
"uniform" "across" "within"
0

SLIDER
1492
68
1664
101
alpha-across
alpha-across
1
20
64.0
1
1
NIL
HORIZONTAL

SLIDER
1492
107
1664
140
beta-across
beta-across
1
20
16.0
1
1
NIL
HORIZONTAL

SLIDER
1676
68
1848
101
alpha-correct
alpha-correct
1
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
1677
105
1849
138
beta-correct
beta-correct
1
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
1677
153
1849
186
alpha-incorrect
alpha-incorrect
1
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
1678
188
1850
221
beta-incorrect
beta-incorrect
1
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
749
133
921
166
alpha-pop
alpha-pop
1
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
750
172
922
205
beta-pop
beta-pop
1
20
2.0
1
1
NIL
HORIZONTAL

PLOT
964
234
1370
398
Distribution of Degrees of Belief
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"set-plot-pen-mode 1\nset-histogram-num-bars 100\nhistogram [degree-of-belief] of arguers" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [degree-of-belief] of arguers "

BUTTON
607
181
740
214
NIL
one-round-update
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
751
210
889
255
Majority
Majority
"any" "correct" "incorrect"
0

SLIDER
1039
137
1211
170
alpha-arg
alpha-arg
1
20
14.0
1
1
NIL
HORIZONTAL

SLIDER
1039
101
1211
134
beta-arg
beta-arg
1
20
3.0
1
1
NIL
HORIZONTAL

PLOT
59
467
954
705
Evolution of the Agents' Degrees of Beliefs
Time
Degrees-of-Belief
0.0
10.0
0.0
1.0
true
false
"ask arguers [create-temporary-plot-pen (word who)\n  set-plot-pen-color p-color\n  plotxy ticks degree-of-belief]" "set-plot-x-range 0 ticks + 1\nask arguers [create-temporary-plot-pen (word who)\n  set-plot-pen-color p-color\n  plotxy ticks degree-of-belief]"
PENS

PLOT
965
528
1370
704
Condorcet-Majority
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"if(ticks > 0)[plot precision sum (sublist (item (n-agents - 1) non-maj) ((n-agents + 1) / 2) (n-agents + 1) ) 5]" "set-plot-x-range 0 ticks + 1"
PENS
"pen-0" 1.0 0 -16777216 true "" "if(ticks > 0)[ifelse ((sum (sublist (item (n-agents - 1) non-maj) ((n-agents + 1) / 2) (n-agents + 1) )) > 1) [plot 0.99999][plot sum (sublist (item (n-agents - 1) non-maj) ((n-agents + 1) / 2) (n-agents + 1) )]]"

SWITCH
748
51
948
84
probabilistic-majority-vote
probabilistic-majority-vote
0
1
-1000

PLOT
964
403
1370
523
histogram-presented-arguments
NIL
NIL
0.0
5.0
0.0
10.0
true
false
"set-plot-pen-mode 1\nset-histogram-num-bars 100\n" ""
PENS
"default" 1.0 0 -16777216 true "" "if(ticks > 0)[histogram arg-list]"

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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>one-round-update</go>
    <enumeratedValueSet variable="gamma">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="10"/>
      <value value="20"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="gamma_within_172217" repetitions="10000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>one-round-update</go>
    <metric>ticks</metric>
    <metric>precision mean prior-list 2</metric>
    <metric>max list count arguers with [prior &gt; 0.5] count arguers with [prior &lt; 0.5] = count arguers with [prior &gt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &gt; 0.5] or all? arguers [degree-of-belief &lt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &gt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &lt; 0.5]</metric>
    <metric>correct-at-start</metric>
    <metric>count arguers with [prior &gt; 0.5]</metric>
    <metric>count arguers with [prior &lt; 0.5]</metric>
    <metric>count arguers with [prior = 0.5]</metric>
    <metric>count arguers with [degree-of-belief &gt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &lt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief = 0.5]</metric>
    <metric>count arguers with [degree-of-belief &gt; 0.5 and prior &gt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &lt; 0.5 and prior &lt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &gt; 0.5 and prior = 0.5]</metric>
    <metric>count arguers with [degree-of-belief &lt; 0.5 and prior = 0.5]</metric>
    <metric>final-round</metric>
    <metric>arg-list</metric>
    <enumeratedValueSet variable="alpha-correct">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-correct">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-incorrect">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-incorrect">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="50"/>
      <value value="100"/>
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protocols">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribute-gamma">
      <value value="&quot;within&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="try out" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>one-round-update</go>
    <metric>ticks</metric>
    <metric>arg-list</metric>
    <metric>all? arguers [degree-of-belief &gt; 0.5]</metric>
    <enumeratedValueSet variable="gamma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protocols">
      <value value="&quot;alternate&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>one-round-update</go>
    <enumeratedValueSet variable="gamma">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protocols">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribute-gamma">
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>one-round-update</go>
    <metric>ticks</metric>
    <metric>precision mean prior-list 2</metric>
    <metric>max list count arguers with [prior &gt; 0.5] count arguers with [prior &lt; 0.5] = count arguers with [prior &gt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &gt; 0.5] or all? arguers [degree-of-belief &lt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &gt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &lt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &gt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &lt; 0.5]</metric>
    <metric>final-round</metric>
    <metric>arg-list</metric>
    <enumeratedValueSet variable="gamma">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protocols">
      <value value="&quot;alternate&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="beta-across">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gamma">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-across">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-correct">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-correct">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-incorrect">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-incorrect">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribute-gamma">
      <value value="&quot;within&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protocols">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="20000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="gamma">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.7"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-across">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-correct">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-correct">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-incorrect">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-incorrect">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protocols">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribute-gamma">
      <value value="&quot;across&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="to_501_2552_within_incorrect" repetitions="30000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>one-round-update</go>
    <metric>ticks</metric>
    <metric>precision mean prior-list 2</metric>
    <metric>max list count arguers with [prior &gt; 0.5] count arguers with [prior &lt; 0.5] = count arguers with [prior &gt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &gt; 0.5] or all? arguers [degree-of-belief &lt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &gt; 0.5]</metric>
    <metric>all? arguers [degree-of-belief &lt; 0.5]</metric>
    <metric>correct-at-start</metric>
    <metric>count arguers with [prior &gt; 0.5]</metric>
    <metric>count arguers with [prior &lt; 0.5]</metric>
    <metric>count arguers with [prior = 0.5]</metric>
    <metric>count arguers with [degree-of-belief &gt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &lt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief = 0.5]</metric>
    <metric>count arguers with [degree-of-belief &gt; 0.5 and prior &gt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &lt; 0.5 and prior &lt; 0.5]</metric>
    <metric>count arguers with [degree-of-belief &gt; 0.5 and prior = 0.5]</metric>
    <metric>count arguers with [degree-of-belief &lt; 0.5 and prior = 0.5]</metric>
    <metric>arg-list</metric>
    <metric>wrong-prior</metric>
    <metric>wrong-degrees</metric>
    <metric>wrong-arg</metric>
    <enumeratedValueSet variable="min-group-competence">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-agents">
      <value value="11"/>
      <value value="21"/>
      <value value="31"/>
      <value value="51"/>
      <value value="101"/>
      <value value="301"/>
      <value value="501"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Majority">
      <value value="&quot;incorrect&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribute-gamma">
      <value value="&quot;within&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-pop">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-pop">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-arg">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-arg">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-correct">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-correct">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-incorrect">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-incorrect">
      <value value="2"/>
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
