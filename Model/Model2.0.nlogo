extensions [table nw]

globals [
  total-population
  communities-founded
  number-of-drop-outs
  number-of-died-communities
  person-to-track
  general-perturbation
  all-ep-list
  new-outgroupers
  ingroupers
  outgroupers
  min-5%-friends
  max-5%-friends
]

breed [people person]
breed [visions vision]
breed [  communities community]
undirected-link-breed [member-links member-link]
undirected-link-breed [meeting-links meeting-link]

;undirected-link-breed []

people-own [
  ;general

  internal-perturbation-impact
  external-perturbation-impact
  internal-perturbation-change
  external-perturbation-change
  last-52-ep

  ;values
  my-orientation
  my-group-pressure

  importance-self-transcendence-values
  importance-self-enhancement-values
  importance-conservation-values
  importance-openness-to-change-values


  impact-group-pressure
  impact-intersubjective-pressures
  receptiveness-to-external-perturbations
  receptiveness-to-internal-perturbations

  social-entrepeneur?

  ;moral concern
  reference-group
  level-of-moral-concern
  stage-of-moral-concern
  member-of-community?
  willingness-to-morally-expand
  attempts-to-morally-expand

  list-of-outgroupers-I-know-in-stage3
  list-of-people-beyond-ingroup-stage3
  ever-reached-stage-3?

  list-of-drop-outs-I-know

  my-community
  time-in-stage-4
  my-shape

  met-neighbor?
  my-social-reach
  people-in-my-social-reach
  normativity-table
  my-max-ties


]

communities-own [
  community-number
  creation-date
  number-of-members
  embedded-community?
  average-distance-members
]

to setup-parameters

  set #ST-OTC-oriented-people 500
  set #OTC-SE-oriented-people 500
  set #SE-C-oriented-people 500
  set #C-ST-oriented-people 500

  set ep-increasing? true
 ;external perturbation
  set Max-ep 1.8
  set ep-linear? false
  set min-EP 0.6

  ;internal
  set IP-Lambda 1.2
  ;set tipping-scenario "none"

  ;static-seed
  set static-seed? false
  set static-seed 7

  ;my-social-reach
  set green-social-reach 1.25
  set blue-social-reach 2.5

  ; value
  set value-oriented-mean 70
  set value-std-dev 10
  set cd2-max-sum-antagonistic-value-pairs 130
  set cd2-min-sum-antagonistic-value-pairs 70

  ;

  set initial-willingness-to-morally-expand-threshold 3


  ;memory


  ;receptiveness
  set social-entrepeneurs 0.05
  set ip-reduction 0.9
  set ep-reduction 0.3

  ;grouppressure
  set moral-expansion-change-individual-meeting 1.5
  set moral-expansion-change-group-pressure 1.5

  ;comm
  set min-numb-people-for-com 20
  set max-numb-people-for-com 1800
  set time-needed-to-morally-expand 25

end

to setup
  clear-all
  reset-ticks
  ask patches [set pcolor white]
 ; if static-seed? [random-seed static-seed]
  setup-population
    setup-connections
  setup-moral-concern-system

  setup-globals
  update-plots


end

to setup-population
  set total-population #ST-OTC-oriented-people + #OTC-SE-oriented-people + #SE-C-oriented-people + #C-ST-oriented-people
  repeat #ST-OTC-oriented-people [setup-person "st-otc"]
  repeat #OTC-SE-oriented-people [setup-person "otc-se"]
  repeat #SE-C-oriented-people [setup-person "se-c"]
  repeat #C-ST-oriented-people [setup-person "c-st"]

end

to setup-person [orientation]
  create-people 1 [
    set color black
    set shape "circle"
    set size 0.05
    setxy random-xcor random-ycor
    set my-orientation orientation
    setup-cognitive-architecture orientation
    set my-social-reach clamp 0.8 3 random-poisson green-social-reach
    set my-max-ties min-node-degree + random (max-connections - min-node-degree)
    set met-neighbor? false
    set member-of-community? false
    set ever-reached-stage-3? false
    set list-of-drop-outs-I-know (list)
    set last-52-ep (list)


  ]
end

to setup-globals
  set all-ep-list (list)
  set ingroupers people with [reference-group = "Ingroup"]
  set outgroupers people with [reference-group = "Outgroup"]
end

to setup-connections
;repeat 500 [layout-spring people meeting-links 0.5 0.5 1 / total-population]
  if social-network = "social-reach"[
    ask n-of (%blue-social-reach * count people / 100) people [
      set my-social-reach clamp 0.8 3 random-poisson blue-social-reach ]
    ask people [
      set people-in-my-social-reach other people in-radius my-social-reach ]
    ask people [
      let n 0
      ask people-in-my-social-reach [
        if member? myself people-in-my-social-reach and count meeting-link-neighbors < max-connections and n < max-connections [
          create-meeting-link-with myself
          set n n + 1]
      ]
    ]
    let sorted-people sort-on [distancexy 0 0] people
    let my-position 0

    foreach sorted-people [
      x ->
      if my-position > 0 [
        ask x [
          while [count meeting-link-neighbors < min-node-degree or nw:distance-to item (my-position - 1) sorted-people = false] [
            create-meeting-link-with min-one-of other people with [not member? myself meeting-link-neighbors][distance myself]
          ]
        ]
      ]
      set my-position my-position + 1
    ]
    ask people with [count meeting-link-neighbors > my-max-ties] [
      while [count meeting-link-neighbors > my-max-ties] [
        let x one-of meeting-link-neighbors with [ count meeting-link-neighbors > min-node-degree]
        ifelse x = nobody [
          stop ] [
          ask meeting-link-with x [die]]
      ]
    ]
  ]
  if social-network = "spatially-clustered-network"[
    ; based on the value of D, nodes are linked. With small value of D nodes that are closer are more likely to be linked.
    ; With higher values of D the links become more linked with nodes unrelated to distance.
    let num-links (min-node-degree * total-population) / 2
    while [ count meeting-links < num-links ]
    [
      ask one-of people
      [
        ask other people with [not meeting-link-neighbor? myself]
        [if random-float 1 < ( min-node-degree / ( 2 * pi * D ^ 2 ) ) * e ^ ( -1 * total-population * (distance myself) ^ 2 / (2 * D ^ 2) ) [
            create-meeting-link-with myself
          ]
        ]
      ]
    ]
  ]
  print 1
  ;ask people [set people-in-my-social-reach meeting-link-neighbors]
  set min-5%-friends min-n-of (total-population * 0.05) people with [count meeting-link-neighbors > 0] [count meeting-link-neighbors]
  set max-5%-friends max-n-of (total-population * 0.05) people [count meeting-link-neighbors]

 ; let k remove-duplicates sort

end



to setup-cognitive-architecture [orientation]
  setup-value-system orientation
  align-value-system
end

to setup-value-system [orientation]
  if orientation = "st-otc"[
    set importance-self-transcendence-values normalize-data-in-range value-oriented-mean value-std-dev
    set importance-self-enhancement-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev
    set importance-conservation-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev
    set importance-openness-to-change-values normalize-data-in-range value-oriented-mean value-std-dev]

 if orientation = "otc-se"[
    set importance-self-transcendence-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev
    set importance-self-enhancement-values normalize-data-in-range  value-oriented-mean value-std-dev
    set importance-conservation-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev
    set importance-openness-to-change-values normalize-data-in-range  value-oriented-mean value-std-dev]

 if orientation = "se-c"[
    set importance-self-transcendence-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev
    set importance-self-enhancement-values normalize-data-in-range  value-oriented-mean value-std-dev
    set importance-conservation-values normalize-data-in-range value-oriented-mean value-std-dev
    set importance-openness-to-change-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev]

   if orientation = "c-st"[
    set importance-self-transcendence-values normalize-data-in-range value-oriented-mean value-std-dev
    set importance-self-enhancement-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev
    set importance-conservation-values normalize-data-in-range value-oriented-mean value-std-dev
    set importance-openness-to-change-values normalize-data-in-range (100 - value-oriented-mean) value-std-dev]

end

to align-value-system
  let dVt-Ve1 importance-self-transcendence-values +  importance-self-enhancement-values
  let dVt-Ve2 importance-conservation-values + importance-openness-to-change-values
  foreach (list dVt-Ve1 dVt-Ve2) [ x ->
    let V-correction 0
    if x > cd2-max-sum-antagonistic-value-pairs  [
      set V-correction ( (x - cd2-max-sum-antagonistic-value-pairs  ) / 2)
      set importance-self-transcendence-values importance-self-transcendence-values - V-correction
      set importance-self-enhancement-values importance-self-enhancement-values - V-correction
    ]
    if x < cd2-min-sum-antagonistic-value-pairs  [
      set V-correction ( (cd2-min-sum-antagonistic-value-pairs - x  ) / 2)
      set importance-self-transcendence-values importance-self-transcendence-values + V-correction
      set importance-self-enhancement-values importance-self-enhancement-values + V-correction
    ]
  ]
end



to setup-moral-concern-system
  ask people [
    set reference-group "Ingroup"
    set shape "we"
    set my-shape "we"]

if tipping-scenario = "Shotgun" [
    ask n-of (social-entrepeneurs * total-population) people [
    set reference-group "Outgroup"
    set shape "they"
    set list-of-people-beyond-ingroup-stage3 (list self)
    set my-shape "they"
      set social-entrepeneur? true
      set size 0.05]]

    if tipping-scenario = "Silver Bullets" [
      ask max-n-of (social-entrepeneurs * total-population) people [count meeting-link-neighbors] [
    set reference-group "Outgroup"
    set shape "they"
    set list-of-people-beyond-ingroup-stage3 (list self)
    set my-shape "they"
      set social-entrepeneur? true
      set size 0.05]]

      if tipping-scenario = "Snowball" [
    let sen floor (social-entrepeneurs * total-population)
    let k min-one-of people [distancexy 0 0]
    while [sen > 0] [
      ask k [
        set reference-group "Outgroup"
        set shape "they"
        set list-of-people-beyond-ingroup-stage3 (list self)
        set my-shape "they"
        set size 0.05
        set social-entrepeneur? true
        ask up-to-n-of sen meeting-link-neighbors [
          set reference-group "Outgroup"
          set shape "they"
          set social-entrepeneur? true
          set list-of-people-beyond-ingroup-stage3 (list self)
          set my-shape "they"
          set size 0.05
        ]
        set sen floor (social-entrepeneurs * total-population) - count people with [social-entrepeneur? = true]
        set k min-one-of people with [reference-group = "Ingroup"] [distance myself]
      ]
    ]
  ]



  ask people [
    set level-of-moral-concern 0
    set stage-of-moral-concern 1

    setup-receptiveness-parameters
    setup-influence-group-pressure
  ]

end

to setup-receptiveness-parameters
  let ep-modifier 1
  ;receptiveness-to-external-perturbations
   set ep-modifier ep-modifier - (ep-reduction * (100 - importance-self-transcendence-values) / 100)
  if reference-group = "Ingroup" [
   set ep-modifier ep-modifier - ep-reduction]
  set receptiveness-to-external-perturbations clamp 0.1 1 ep-modifier

  ;impact-intersubjective-pressures
  set impact-intersubjective-pressures moral-expansion-change-individual-meeting * ((100 - importance-openness-to-change-values)/ 100)
  set impact-group-pressure moral-expansion-change-group-pressure * ( (importance-conservation-values) / 100)

  ;receptiveness-to-internal-perturbations
  let ip-modifier 1
  set ip-modifier ip-modifier - (ip-reduction * (100 - importance-self-enhancement-values) / 100)
  set receptiveness-to-internal-perturbations clamp 0.1 1 ip-modifier
end

to setup-influence-group-pressure
  set normativity-table table:make
  ask meeting-link-neighbors [
    table:put [normativity-table] of myself who moral-concern-normativity]

end



to go
  ask people [ set met-neighbor? false]
  update-globals
  generate-perturbations
  update-stages-of-moral-concern
  interact-with-neighbour
  update-stages-of-moral-concern
  weigh-we-vs-they
  weigh-they-vs-environment
  update-stages-of-moral-concern
  check-if-community-can-sustain

  tick


end


to update-globals
  set ingroupers people with [reference-group = "Ingroup"]
  set outgroupers people with [reference-group = "Outgroup"]
end

to update-moral-concern-due-to-ep
  ask people [
    if stage-of-moral-concern < 3 [
      if internal-perturbation-change < abs (external-perturbation-change) [
        set level-of-moral-concern clamp 0 50 level-of-moral-concern + external-perturbation-change
      ]
    ]
  ]
end

to generate-perturbations
  ifelse ep-increasing? [
    ifelse ep-linear? [
      set general-perturbation min-EP + (max-EP - min-EP) / 5200 * ticks] [
      set general-perturbation random-exponential (min-EP  + (max-EP - min-EP) / 5200 * ticks)]
  ][
    ifelse ep-linear? [
      set general-perturbation min-EP ][
      set general-perturbation random-exponential min-EP] ]
  if random 100 < %-opposing-perturbation [ set general-perturbation general-perturbation  * -1 ]
  ask people [
    set external-perturbation-impact general-perturbation
    set internal-perturbation-impact random-exponential IP-Lambda
    set internal-perturbation-change internal-perturbation-impact * receptiveness-to-internal-perturbations
    set external-perturbation-change external-perturbation-impact * receptiveness-to-external-perturbations
  ]

  update-moral-concern-due-to-ep

end




to update-stages-of-moral-concern


  ask ingroupers [
    if level-of-moral-concern < 25 [
      set stage-of-moral-concern 1
      set color 1
      stop]
    if level-of-moral-concern < 50 [
      set stage-of-moral-concern 2
      set color 15
      stop]
    if level-of-moral-concern >= 50 and stage-of-moral-concern = 2 [
      set stage-of-moral-concern 3
      set color 105
      set list-of-people-beyond-ingroup-stage3 (list self)
      stop]
    if stage-of-moral-concern = 4   [
      set stage-of-moral-concern 4
      set color 45
      stop]
  ]

  ask outgroupers [
    if level-of-moral-concern < 25 [
      set stage-of-moral-concern 1
      set color 1
      stop]
    if level-of-moral-concern < 50 [
      set stage-of-moral-concern 2
      set color 15
      stop]
    if level-of-moral-concern >= 50 and stage-of-moral-concern = 2 [
      set stage-of-moral-concern 3
      set list-of-outgroupers-I-know-in-stage3 (list self)
      set color 105
      stop]
    if level-of-moral-concern >= 50 and member-of-community? and stage-of-moral-concern = 3  [
      set stage-of-moral-concern 4
      set color 45
      set willingness-to-morally-expand initial-willingness-to-morally-expand-threshold
      set time-in-stage-4 0
      stop]
  ]

end

to interact-with-neighbour
  ask people [
    let potential-neighbors-to-meet meeting-link-neighbors with [met-neighbor? = false ]
    if met-neighbor? = false and count potential-neighbors-to-meet > 0 [
      let neighbor-to-meet one-of potential-neighbors-to-meet
      start-interaction-with neighbor-to-meet
      set met-neighbor? true
      ask neighbor-to-meet [
        start-interaction-with myself
        set met-neighbor? true ]
    ]
  ]
end


to update-influence-group-pressure [neighbor]
  table:put normativity-table [who] of neighbor [moral-concern-normativity] of neighbor
 set my-group-pressure median sort table:values normativity-table
end


to-report moral-concern-normativity
  if reference-group = "Ingroup" [
    if level-of-moral-concern < 25 [
      report 1]
    if level-of-moral-concern < 50 [
      report 1.25]
    if stage-of-moral-concern = 3 or (level-of-moral-concern > 50 and stage-of-moral-concern = 2) [
      report 1.5]
    if stage-of-moral-concern = 4 [
      report 1.75]
  ]
  if reference-group = "Outgroup" [
    if level-of-moral-concern < 25 [
      report 2]
    if level-of-moral-concern < 50 [
      report 2.25]
    if stage-of-moral-concern = 3 or (level-of-moral-concern > 50 and stage-of-moral-concern = 2) [
      report 2.5]
    if stage-of-moral-concern = 4 [
      report 2.75]
    if stage-of-moral-concern = 5 [
      report 3 ]
  ]
  report 0
end


to start-interaction-with [neighbor]
  ;;;;; stage-of-moral-concern = 2
  update-influence-group-pressure neighbor
  if reference-group = "Ingroup" [
    if stage-of-moral-concern = 2 [
      if my-group-pressure < moral-concern-normativity [
        set level-of-moral-concern level-of-moral-concern - impact-group-pressure]
      if my-group-pressure > moral-concern-normativity [
        set level-of-moral-concern level-of-moral-concern + impact-group-pressure]
      ifelse [level-of-moral-concern] of neighbor < level-of-moral-concern  and [reference-group] of neighbor = "Ingroup"
      [set level-of-moral-concern level-of-moral-concern -  impact-intersubjective-pressures]
      [set level-of-moral-concern clamp 0 50 level-of-moral-concern + impact-intersubjective-pressures]
    ]

    ;;;;; stage-of-moral-concern = 3
    if stage-of-moral-concern = 3 [
      update-people-I-know-beyond-stage3-Ingroup neighbor
      if length list-of-people-beyond-ingroup-stage3 >= min-numb-people-for-com [
        set stage-of-moral-concern 4
        set willingness-to-morally-expand initial-willingness-to-morally-expand-threshold
        set time-in-stage-4 0]
    ]
  ]



  if reference-group = "Outgroup" [
    update-people-I-know-beyond-stage3-Ingroup neighbor
    if stage-of-moral-concern = 2 [
      if my-group-pressure < moral-concern-normativity [
        set level-of-moral-concern level-of-moral-concern - impact-group-pressure]
      if my-group-pressure > moral-concern-normativity [
        set level-of-moral-concern level-of-moral-concern + impact-group-pressure]
      ifelse [level-of-moral-concern] of neighbor < level-of-moral-concern or [reference-group] of neighbor = "Ingroup"
      [set level-of-moral-concern level-of-moral-concern -  impact-intersubjective-pressures]
      [set level-of-moral-concern clamp 0 50 level-of-moral-concern + impact-intersubjective-pressures]
    ]
    ;;;;; stage-of-moral-concern = 3
    if stage-of-moral-concern = 3 [
      if [stage-of-moral-concern] of neighbor = 3 and [reference-group] of neighbor = "Outgroup" [
        set list-of-outgroupers-I-know-in-stage3 remove-duplicates sentence list-of-outgroupers-I-know-in-stage3 [list-of-outgroupers-I-know-in-stage3] of neighbor
        foreach list-of-outgroupers-I-know-in-stage3 [
          x ->
          if [stage-of-moral-concern] of x != 3 [ set list-of-outgroupers-I-know-in-stage3 remove x list-of-outgroupers-I-know-in-stage3 ]
        ]
        if length list-of-outgroupers-I-know-in-stage3 >= min-numb-people-for-com [
          start-community ]
      ]
      if [stage-of-moral-concern] of neighbor >= 4 and [reference-group] of neighbor = "Outgroup"  [
        if [number-of-members] of [my-community] of neighbor + length list-of-outgroupers-I-know-in-stage3 < max-numb-people-for-com [
          join-community [my-community] of neighbor
          foreach list-of-outgroupers-I-know-in-stage3 [
            x -> ask x [
              join-community [my-community] of myself
            ]
          ]
        ]
      ]
    ]
  ]
end

to update-people-I-know-beyond-stage3-Ingroup [neighbor]
  if length list-of-people-beyond-ingroup-stage3 < 30 [
  if [stage-of-moral-concern] of neighbor >= 3 or [reference-group] of neighbor = "Outgroup" [
    set list-of-people-beyond-ingroup-stage3 remove-duplicates sentence list-of-people-beyond-ingroup-stage3 [list-of-people-beyond-ingroup-stage3] of neighbor
    foreach list-of-people-beyond-ingroup-stage3 [
      x ->
      if [stage-of-moral-concern] of x < 3 and [reference-group] of x = "Ingroup" [set list-of-people-beyond-ingroup-stage3 remove x list-of-people-beyond-ingroup-stage3 ]
    ]
  ]
  ]
end

to weigh-we-vs-they
  ask ingroupers [
    if stage-of-moral-concern = 4 [
      set willingness-to-morally-expand willingness-to-morally-expand - internal-perturbation-impact * receptiveness-to-internal-perturbations + external-perturbation-impact * receptiveness-to-external-perturbations
      if my-group-pressure < moral-concern-normativity [
        set willingness-to-morally-expand willingness-to-morally-expand - impact-group-pressure]
      if my-group-pressure > moral-concern-normativity [
        set willingness-to-morally-expand willingness-to-morally-expand + impact-group-pressure]
      if willingness-to-morally-expand < 0 [
        set stage-of-moral-concern 2
        set level-of-moral-concern 25
        set color 15
        set list-of-people-beyond-ingroup-stage3 (list self)
        set time-in-stage-4 0
        stop]
      set time-in-stage-4 time-in-stage-4 + 1
      if time-in-stage-4 > time-needed-to-morally-expand [
        set stage-of-moral-concern 1
        set level-of-moral-concern 0
        set time-in-stage-4 0
        set reference-group "Outgroup"
        set new-outgroupers new-outgroupers + 1
        set my-shape "they"
        set shape "they"
        set color black
        setup-receptiveness-parameters
        stop
      ]
    ]
  ]
end

to weigh-they-vs-environment
  ask outgroupers [
    if stage-of-moral-concern = 4 [
      set willingness-to-morally-expand willingness-to-morally-expand - internal-perturbation-impact * receptiveness-to-internal-perturbations + external-perturbation-impact * receptiveness-to-external-perturbations
       if my-group-pressure < moral-concern-normativity [
        set willingness-to-morally-expand willingness-to-morally-expand - impact-group-pressure]
      if my-group-pressure > moral-concern-normativity [
        set willingness-to-morally-expand willingness-to-morally-expand + impact-group-pressure]
      if willingness-to-morally-expand < 0 [
        quit-community
        set time-in-stage-4 0
        stop]
      set time-in-stage-4 time-in-stage-4 + 1
      if time-in-stage-4 > time-needed-to-morally-expand [
        set stage-of-moral-concern 5
        set color 55
        set shape "tree"
        stop
      ]
    ]
  ]


end

to check-if-community-can-sustain
  ask communities [
    if count member-link-neighbors with [stage-of-moral-concern = 5] >= min-numb-people-for-com [
      set embedded-community? true ]
    if number-of-members < min-numb-people-for-com [
      ask member-link-neighbors [
        set stage-of-moral-concern 3
        set member-of-community? false
        set my-community 0
        set shape my-shape
        set color 105]
      ask my-member-links [die]
      set number-of-died-communities number-of-died-communities + 1
      die
    ]
  ]
  ask communities with [embedded-community? = true ] [
    let distances 0
    ask member-link-neighbors [
      set distances distances + distance myself]
    set average-distance-members distances / number-of-members
  ]

end

to start-community
  foreach list-of-outgroupers-I-know-in-stage3 [
    x -> set list-of-outgroupers-I-know-in-stage3 remove-duplicates sentence list-of-outgroupers-I-know-in-stage3 [list-of-outgroupers-I-know-in-stage3] of x]
  foreach list-of-outgroupers-I-know-in-stage3 [
    x -> ask x [
      if stage-of-moral-concern != 3 [
        ask myself [set list-of-outgroupers-I-know-in-stage3 remove x list-of-outgroupers-I-know-in-stage3 ]
      ]
    ]
  ]
  hatch-communities 1 [
    set communities-founded communities-founded + 1
    set community-number communities-founded
    set creation-date ticks
    set shape "bread"
    set size 0.08
    setxy [xcor] of myself [ycor] of myself
    foreach [list-of-outgroupers-I-know-in-stage3] of myself [
      x -> ask x [
        join-community myself
        update-stages-of-moral-concern
      ]
    ]

  ]
end

to join-community [commune]
  create-member-link-with commune
  set member-of-community? true
  set my-community commune
  ask commune [set number-of-members count in-member-link-neighbors]


end

to quit-community
  ask my-community [ set number-of-members number-of-members - 1]
  ask my-member-links [die]
  set stage-of-moral-concern 2
  set level-of-moral-concern 25
  set color 15
  set list-of-outgroupers-I-know-in-stage3 (list )
  set member-of-community? false
  set attempts-to-morally-expand attempts-to-morally-expand + 1
  set number-of-drop-outs number-of-drop-outs + 1
end


to-report value-difference [person1 person2]
  let vd abs([importance-self-transcendence-values] of person1 - [importance-self-transcendence-values] of person2)
  set vd vd + abs([importance-self-enhancement-values] of person1 - [importance-self-enhancement-values] of person2)
  report vd
end


to-report clamp [low high number]
  if number < low [
    report low
  ]
  if number > high [
    report high
  ]
  report number
end


to-report normalize-data-in-range [mean-data std-data]
  let x -1
  while [x < 0 or x > 100] [
    set x precision (random-normal mean-data std-data) 3 ]
  report x
end

to-report random-float-in-range [low high]
  let x 0
  ifelse low < 0 [
    set x random-float (high + abs(low)) + low]
  [set x random-float (high - low) + low]
  report x
end


to-report occurrences [x the-list]
  report reduce
    [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 the-list)
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
642
443
-1
-1
212.0
1
10
1
1
1
0
1
1
1
0
1
0
1
0
0
1
ticks
30.0

SWITCH
20
18
143
51
static-seed?
static-seed?
1
1
-1000

INPUTBOX
21
56
144
116
static-seed
7.0
1
0
Number

SLIDER
655
38
860
71
#ST-OTC-oriented-people
#ST-OTC-oriented-people
0
2500
250.0
25
1
NIL
HORIZONTAL

BUTTON
21
125
84
158
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
22
164
95
197
go
 if total-population = count people with [reference-group = \"Outgroup\" and stage-of-moral-concern = 5 ][stop]\n go\n 
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
22
201
97
234
go once
go
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
656
233
828
266
value-oriented-mean
value-oriented-mean
50
80
60.0
1
1
NIL
HORIZONTAL

SLIDER
656
271
828
304
value-std-dev
value-std-dev
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
656
308
917
341
cd2-max-sum-antagonistic-value-pairs
cd2-max-sum-antagonistic-value-pairs
70
130
130.0
1
1
NIL
HORIZONTAL

SLIDER
658
345
914
378
cd2-min-sum-antagonistic-value-pairs
cd2-min-sum-antagonistic-value-pairs
0
100
70.0
1
1
NIL
HORIZONTAL

TEXTBOX
658
15
808
35
Population
16
0.0
1

TEXTBOX
959
14
1128
54
Perturbations
16
0.0
1

SLIDER
959
148
1205
181
Max-ep
Max-ep
0
3
2.95
0.05
1
NIL
HORIZONTAL

SLIDER
959
241
1149
274
%-opposing-perturbation
%-opposing-perturbation
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1229
155
1413
188
ep-reduction
ep-reduction
0
1
0.45
0.01
1
NIL
HORIZONTAL

TEXTBOX
1219
15
1465
58
Agent's reaction to perturbations
16
0.0
1

PLOT
6
696
993
1055
Ingroup to Outgroup: Stages of Moral Expansion
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
"IN:Stage 1" 1.0 0 -16777216 true "" "plot count people with [reference-group = \"Ingroup\" and stage-of-moral-concern = 1 ]"
"IN Stage 2" 1.0 0 -2674135 true "" "plot count people with [reference-group = \"Ingroup\" and stage-of-moral-concern = 2 ]"
"IN:Stage 3" 1.0 0 -13345367 true "" "plot count people with [reference-group = \"Ingroup\" and stage-of-moral-concern = 3 ]"
"IN:Stage 4" 1.0 0 -1184463 true "" "plot count people with [reference-group = \"Ingroup\" and stage-of-moral-concern = 4 ]"
"TO OUTGROUP" 1.0 0 -7500403 true "" "plot new-outgroupers"

PLOT
1229
418
1429
568
Receptiveness EP
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [receptiveness-to-external-perturbations] of people"

PLOT
1484
278
1684
428
Interactions
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count people with [met-neighbor? = true]"

SLIDER
1480
53
1655
86
blue-social-reach
blue-social-reach
0
5
4.2
0.05
1
NIL
HORIZONTAL

SLIDER
1479
169
1767
202
moral-expansion-change-individual-meeting
moral-expansion-change-individual-meeting
1
4
1.0
0.5
1
NIL
HORIZONTAL

SLIDER
1488
450
1680
483
min-numb-people-for-com
min-numb-people-for-com
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1489
486
1685
519
max-numb-people-for-com
max-numb-people-for-com
0
total-population
2000.0
25
1
NIL
HORIZONTAL

SLIDER
1234
300
1406
333
ip-reduction
ip-reduction
0
1
0.9
0.01
1
NIL
HORIZONTAL

TEXTBOX
961
216
1128
238
External Perturbation
16
0.0
1

TEXTBOX
1235
274
1402
296
to Internal
13
0.0
1

PLOT
1228
574
1428
724
Receptiveness IP
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [receptiveness-to-internal-perturbations] of people"

SLIDER
1800
454
2103
487
initial-willingness-to-morally-expand-threshold
initial-willingness-to-morally-expand-threshold
0
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
1802
488
2028
521
time-needed-to-morally-expand
time-needed-to-morally-expand
0
30
25.0
1
1
NIL
HORIZONTAL

MONITOR
1492
520
1622
565
NIL
number-of-drop-outs
17
1
11

MONITOR
1625
521
1795
566
NIL
number-of-died-communities
17
1
11

TEXTBOX
1489
429
1656
451
Community 
16
0.0
1

TEXTBOX
1478
19
1645
41
Interactions
16
0.0
1

TEXTBOX
1803
428
1970
450
Willingness to expand
16
0.0
1

TEXTBOX
1235
136
1402
156
to External
13
0.0
1

BUTTON
22
239
127
273
Go 1 run
repeat 7500 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1803
520
1883
565
Stage fivers
count people with [stage-of-moral-concern = 1]
17
1
11

PLOT
1496
726
2057
944
Value distribution population
Value Prioritization
Number of People
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Self-Transcendence" 2.5 0 -5825686 true "" "histogram [importance-self-transcendence-values] of people "
"Self-Enhancement" 2.5 0 -13791810 true "" "histogram [importance-self-enhancement-values] of people "
"Openness-to-change" 2.5 0 -2674135 true "" "histogram [importance-openness-to-change-values] of people"
"Conservation" 2.5 0 -7500403 true "" "histogram [importance-conservation-values] of people"

MONITOR
1492
569
1681
614
Number of existing Communities
count communities
17
1
11

MONITOR
1494
620
1796
665
People that lack enough people to create community
count people with [stage-of-moral-concern = 3 and attempts-to-morally-expand = 0]
17
1
11

BUTTON
21
278
180
311
Inspect random person
inspect one-of people
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1688
278
1888
428
Meeting radius
NIL
NIL
0.0
50.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [count meeting-link-neighbors] of people"

SLIDER
1218
102
1390
135
social-entrepeneurs
social-entrepeneurs
0
0.1
0.05
0.001
1
NIL
HORIZONTAL

TEXTBOX
1219
82
1387
101
Ingroup vs Outgroup
13
0.0
1

SLIDER
958
182
1205
215
IP-Lambda
IP-Lambda
0
2.00
1.2
0.05
1
NIL
HORIZONTAL

SLIDER
959
114
1131
147
min-EP
min-EP
0
max-ep
1.2
0.1
1
NIL
HORIZONTAL

MONITOR
1150
27
1209
72
std-EP
standard-deviation all-ep-list
4
1
11

MONITOR
1151
73
1211
118
mean EP
mean general-perturbation
4
1
11

SWITCH
958
39
1068
72
ep-linear?
ep-linear?
1
1
-1000

PLOT
12
473
916
695
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot general-perturbation"

BUTTON
29
317
161
351
NIL
setup-parameters
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
4
1062
995
1366
Outgroup to Environment: Stages of Moral expansion
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
"Out:Stage 1" 1.0 0 -16777216 true "" "plot count people with [reference-group = \"Outgroup\" and stage-of-moral-concern = 1 ]"
"Out:Stage 2" 1.0 0 -2674135 true "" "plot count people with [reference-group = \"Outgroup\" and stage-of-moral-concern = 2 ]"
"Out:Stage 3" 1.0 0 -13345367 true "" "plot count people with [reference-group = \"Outgroup\" and stage-of-moral-concern = 3 ]"
"Out:Stage 4" 1.0 0 -1184463 true "" "plot count people with [reference-group = \"Outgroup\" and stage-of-moral-concern = 4 ]"
"Out:Stage 5" 1.0 0 -13840069 true "" "plot count people with [reference-group = \"Outgroup\" and stage-of-moral-concern = 5 ]"

SLIDER
1480
207
1770
240
moral-expansion-change-group-pressure
moral-expansion-change-group-pressure
0
8
4.0
0.1
1
NIL
HORIZONTAL

SLIDER
652
73
863
106
#OTC-SE-oriented-people
#OTC-SE-oriented-people
0
2500
250.0
25
1
NIL
HORIZONTAL

SLIDER
652
107
864
140
#SE-C-oriented-people
#SE-C-oriented-people
0
2500
250.0
25
1
NIL
HORIZONTAL

SLIDER
653
142
862
175
#C-ST-oriented-people
#C-ST-oriented-people
0
2500
250.0
25
1
NIL
HORIZONTAL

CHOOSER
1224
197
1362
242
tipping-scenario
tipping-scenario
"none" "Shotgun" "Silver Bullets" "Snowball"
1

MONITOR
177
522
298
567
social entrepeneurs
count people with [social-entrepeneur? = true]
17
1
11

PLOT
1017
418
1217
568
Receptiveness GP
NIL
NIL
0.0
4.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [impact-group-pressure] of people"

PLOT
1018
576
1218
726
Receptiveness IM
NIL
NIL
0.0
4.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [impact-intersubjective-pressures] of people"

SWITCH
958
80
1092
113
ep-increasing?
ep-increasing?
0
1
-1000

SLIDER
1479
91
1651
124
green-social-reach
green-social-reach
0
5
1.25
0.05
1
NIL
HORIZONTAL

SLIDER
1481
129
1653
162
%blue-social-reach
%blue-social-reach
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1785
116
1957
149
max-connections
max-connections
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1786
150
1958
183
min-node-degree
min-node-degree
0
10
6.0
1
1
NIL
HORIZONTAL

CHOOSER
1787
34
1977
79
social-network
social-network
"social-reach" "spatially-clustered-network"
1

SLIDER
1788
81
1960
114
D
D
0
32
4.0
1
1
NIL
HORIZONTAL

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

bread
false
0
Polygon -16777216 true false 140 145 170 250 245 190 234 122 247 107 260 79 260 55 245 40 215 32 185 40 155 31 122 41 108 53 28 118 110 115 140 130
Polygon -7500403 true true 135 151 165 256 240 196 225 121 241 105 255 76 255 61 240 46 210 38 180 46 150 37 120 46 105 61 47 108 105 121 135 136
Polygon -1 true false 60 181 45 256 165 256 150 181 165 166 180 136 180 121 165 106 135 98 105 106 75 97 46 107 29 118 30 136 45 166 60 181
Polygon -16777216 false false 45 255 165 255 150 180 165 165 180 135 180 120 165 105 135 97 105 105 76 96 46 106 29 118 30 135 45 165 60 180
Line -16777216 false 165 255 239 195

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
Circle -7500403 false true 33 33 234

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

orbit 6
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 26 176 67
Circle -7500403 true true 206 176 67
Circle -7500403 false true 45 45 210
Circle -7500403 true true 26 58 67
Circle -7500403 true true 206 58 67
Circle -7500403 true true 116 221 67

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

they
true
0
Polygon -7500403 true true 120 225 75 240 225 240 180 225 180 90 225 120 225 60 75 60 75 120 120 90 120 150 105 150 105 180 120 180 120 225
Polygon -7500403 true true 165 180 180 180
Polygon -7500403 true true 180 150 195 150 195 180 180 180

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

we
true
0
Polygon -7500403 true true 225 120 210 120
Polygon -7500403 true true 195 150 210 135 210 135
Polygon -10899396 true false 108 104 107 134
Polygon -7500403 true true 60 120 60 135 105 225 150 180 195 225 240 135 240 105 180 60 195 135 180 165 150 135 120 165 105 135 120 60 60 105
Polygon -6459832 true false 165 105

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment 1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup-parameters
setup</setup>
    <go>go</go>
    <timeLimit steps="7500"/>
    <metric>count people with [moral-concern-normativity = 1]</metric>
    <metric>count people with [moral-concern-normativity = 1.25]</metric>
    <metric>count people with [moral-concern-normativity = 1.5]</metric>
    <metric>count people with [moral-concern-normativity = 1.75]</metric>
    <metric>count people with [moral-concern-normativity = 2]</metric>
    <metric>count people with [moral-concern-normativity = 2.25]</metric>
    <metric>count people with [moral-concern-normativity = 2.5]</metric>
    <metric>count people with [moral-concern-normativity = 2.75]</metric>
    <metric>count people with [moral-concern-normativity = 3]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "st-otc"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "otc-se"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "se-c"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "c-st"]</metric>
    <enumeratedValueSet variable="value-oriented-mean">
      <value value="60"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ep-linear?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 3" repetitions="5" runMetricsEveryStep="true">
    <setup>setup-parameters
setup</setup>
    <go>go</go>
    <timeLimit steps="7500"/>
    <metric>count people with [moral-concern-normativity = 1]</metric>
    <metric>count people with [moral-concern-normativity = 1.25]</metric>
    <metric>count people with [moral-concern-normativity = 1.5]</metric>
    <metric>count people with [moral-concern-normativity = 1.75]</metric>
    <metric>count people with [moral-concern-normativity = 2]</metric>
    <metric>count people with [moral-concern-normativity = 2.25]</metric>
    <metric>count people with [moral-concern-normativity = 2.5]</metric>
    <metric>count people with [moral-concern-normativity = 2.75]</metric>
    <metric>count people with [moral-concern-normativity = 3]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "st-otc"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "otc-se"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "se-c"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "c-st"]</metric>
    <metric>mean [moral-concern-normativity] of min-5%-friends</metric>
    <metric>mean [moral-concern-normativity] of max-5%-friends</metric>
    <enumeratedValueSet variable="tipping-scenario">
      <value value="&quot;none&quot;"/>
      <value value="&quot;Shotgun&quot;"/>
      <value value="&quot;Silver Bullets&quot;"/>
      <value value="&quot;Snowball&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup-parameters
setup</setup>
    <go>go</go>
    <timeLimit steps="7500"/>
    <metric>count people with [moral-concern-normativity = 1]</metric>
    <metric>count people with [moral-concern-normativity = 1.25]</metric>
    <metric>count people with [moral-concern-normativity = 1.5]</metric>
    <metric>count people with [moral-concern-normativity = 1.75]</metric>
    <metric>count people with [moral-concern-normativity = 2]</metric>
    <metric>count people with [moral-concern-normativity = 2.25]</metric>
    <metric>count people with [moral-concern-normativity = 2.5]</metric>
    <metric>count people with [moral-concern-normativity = 2.75]</metric>
    <metric>count people with [moral-concern-normativity = 3]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "st-otc"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "otc-se"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "se-c"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "c-st"]</metric>
    <metric>mean [moral-concern-normativity] of min-5%-friends</metric>
    <metric>mean [moral-concern-normativity] of max-5%-friends</metric>
    <enumeratedValueSet variable="moral-expansion-change-group-pressure">
      <value value="0.5"/>
      <value value="1.5"/>
      <value value="2.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 4" repetitions="10" runMetricsEveryStep="true">
    <setup>setup-parameters
setup</setup>
    <go>go</go>
    <timeLimit steps="7500"/>
    <metric>count people with [moral-concern-normativity = 1]</metric>
    <metric>count people with [moral-concern-normativity = 1.25]</metric>
    <metric>count people with [moral-concern-normativity = 1.5]</metric>
    <metric>count people with [moral-concern-normativity = 1.75]</metric>
    <metric>count people with [moral-concern-normativity = 2]</metric>
    <metric>count people with [moral-concern-normativity = 2.25]</metric>
    <metric>count people with [moral-concern-normativity = 2.5]</metric>
    <metric>count people with [moral-concern-normativity = 2.75]</metric>
    <metric>count people with [moral-concern-normativity = 3]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "st-otc"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "otc-se"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "se-c"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "c-st"]</metric>
    <metric>mean [moral-concern-normativity] of min-5%-friends</metric>
    <metric>mean [moral-concern-normativity] of max-5%-friends</metric>
    <enumeratedValueSet variable="social-entrepeneurs">
      <value value="0"/>
      <value value="0.02"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 5" repetitions="10" runMetricsEveryStep="true">
    <setup>setup-parameters
setup</setup>
    <go>go</go>
    <timeLimit steps="7500"/>
    <metric>count people with [moral-concern-normativity = 1]</metric>
    <metric>count people with [moral-concern-normativity = 1.25]</metric>
    <metric>count people with [moral-concern-normativity = 1.5]</metric>
    <metric>count people with [moral-concern-normativity = 1.75]</metric>
    <metric>count people with [moral-concern-normativity = 2]</metric>
    <metric>count people with [moral-concern-normativity = 2.25]</metric>
    <metric>count people with [moral-concern-normativity = 2.5]</metric>
    <metric>count people with [moral-concern-normativity = 2.75]</metric>
    <metric>count people with [moral-concern-normativity = 3]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "st-otc"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "otc-se"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "se-c"]</metric>
    <metric>mean [moral-concern-normativity] of people with [my-orientation = "c-st"]</metric>
    <metric>mean [moral-concern-normativity] of min-5%-friends</metric>
    <metric>mean [moral-concern-normativity] of max-5%-friends</metric>
    <enumeratedValueSet variable="tipping-scenario">
      <value value="&quot;none&quot;"/>
      <value value="&quot;Shotgun&quot;"/>
      <value value="&quot;Silver Bullets&quot;"/>
      <value value="&quot;Snowball&quot;"/>
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
