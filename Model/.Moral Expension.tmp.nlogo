extensions[table csv]

globals [
  global-event-impact
  total-population
  value-change-list
  lhs-matrix
  experiment-ID
  interface-person
  list-stages-moral-concern

  gr-to-track
  sp-to-track
  sc-to-track
  pr-to-track
]

breed [people person]
undirected-link-breed [my-friends-links my-friends-link]

my-friends-links-own [
  friendly-distance
  my-color-code]
people-own [
  ;general
  my-facet   ;personal orientation, growth orientation, social orientation or self-protection orientation.
  my-population-scenario
  ;Interaction with Technology
  event-impact

  ;values
  ; list which include my-population-scenario and all value prioritizations
  value-system
  value-system-setup
  importance-hedonism-value
  importance-stimulation-value
  importance-self-direction-value
  importance-universalism-value
  importance-benevolence-value
  importance-conformity-value
  importance-tradition-value
  importance-security-value
  importance-power-value
  importance-achievement-value

  ;traits
  trait-system
  neuroticism-trait
  extraversion-trait
  agreeableness-trait
  conscientiousness-trait
  openness-trait

  ;descriptive
  education-level
  access-to-education
  my-neighbourhood
  met-neighbour?
  meeting-random-person-instead-of-friend?
  #neighbour-friends-to-make

  moral-distribution-power

  ;perception-thermometers
  pt-moral-concern
  stage-of-moral-concern
  active-RSQ
  RSQ-modifier-information
  RSQ-modifier-acknowledgement
  RSQ-modifier-Believe
  RSQ-modifier-willingness


]

;;;;;;;;;;;;;;;;;;;;;;;SETUP;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  if static-seed? [random-seed 26 ]
  setup-population-scenario
  setup-population
  setup-neighbourhood
  setup-education-level
  setup-social-network
  setup-agents-to-track
  setup-appearance
  set interface-person round random-float (total-population - 1)
  set list-stages-moral-concern (list "Unaware" "Informed" "Acknowledging" "Believing" "Willing")
  reset-ticks
  update-metrics
end

to setup-population-scenario
  if population-scenario = "none" [
    set #population-growth #population-growth
    set #population-personal #population-personal
    set #population-social #population-social
    set #population-self-protection #population-self-protection ]
  if population-scenario = "growth" [
    set #population-growth 1000
    set #population-personal 0
    set #population-social 0
    set #population-self-protection 0 ]
  if population-scenario = "personal" [
    set #population-growth 0
    set #population-personal 1000
    set #population-social 0
    set #population-self-protection 0 ]
  if population-scenario = "social" [
    set #population-growth 0
    set #population-personal 0
    set #population-social 1000
    set #population-self-protection 0 ]
  if population-scenario = "self-protection" [
    set #population-growth 0
    set #population-personal 0
    set #population-social 0
    set #population-self-protection 1000 ]
  if population-scenario = "mixed" [
    set #population-growth 250
    set #population-personal 250
    set #population-social 250
    set #population-self-protection 250 ]
end




to setup-population
  set total-population #population-growth + #population-personal + #population-social + #population-self-protection
  repeat #population-growth [setup-person "growth"]
  repeat #population-personal [setup-person "personal"]
  repeat #population-social [setup-person "social"]
  repeat #population-self-protection [setup-person "self-protection"]
end

to setup-person [facets]
  create-people 1 [
    set color 9
    set size 0.5
    set #neighbour-friends-to-make round (random-gamma #friends-alpha #friends-lambda )
    set my-population-scenario population-scenario
    setup-cognitive-architecture facets
    setup-moral-concern-system
    set met-neighbour? false



  ]

end

to setup-cognitive-architecture [facets]
  setup-value-system facets
  align-value-systems value-system
  setup-trait-system
  setup-moral-concern-system
end


to-report normalize-data-in-range [mean-data std-data]
  let x -1
  while [x < 0 or x > 100] [
    set x precision (random-normal mean-data std-data) 3 ]
  report x
end

to setup-value-system [facets]
  ;Values systems of agents is configured based on a population mean and a variance based on personality.
  ; The variance that makes each agent having unique values is based on the correlation between traits
  ; and personality in table 10 in Parks-leduc et al. 2014:
  ; https://journals.sagepub.com/doi/pdf/10.1177/1088868314538548?casa-token=tdvVldj2csQAAAAA:ma3A7WYS2RddpoaZaKMYdsZU9YENSPyKwHNF2ASSbVrWVc5-0Bm-OjTRaIotsfDqQN3y8agetZ0U

  let hedonism-mean	0
  let stimulation-mean	0
  let self-direction-mean	0
  let universalism-mean	0
  let benevolence-mean	0
  let conformity-mean	0
  let tradition-mean	0
  let security-mean	0
  let power-mean	0
  let achievement-mean	0

  set my-facet facets
  if facets = "growth" [
    set hedonism-mean	value-facets-mean
    set stimulation-mean	value-facets-mean
    set self-direction-mean	value-facets-mean
    set universalism-mean	value-facets-mean
    set benevolence-mean	value-facets-mean
    set conformity-mean 100 -	value-facets-mean
    set tradition-mean 100 -	value-facets-mean
    set security-mean 100 -	value-facets-mean
    set power-mean	100 - value-facets-mean
    set achievement-mean	100 - value-facets-mean
  ]

  if facets = "social" [
    set hedonism-mean 100 -	value-facets-mean
    set stimulation-mean 100 -	value-facets-mean
    set self-direction-mean 100 -	value-facets-mean
    set universalism-mean	value-facets-mean
    set benevolence-mean	value-facets-mean
    set conformity-mean	value-facets-mean
    set tradition-mean	value-facets-mean
    set security-mean	value-facets-mean
    set power-mean 100 -	value-facets-mean
    set achievement-mean 100 -	value-facets-mean
  ]

  if facets = "personal" [
    set hedonism-mean	value-facets-mean
    set stimulation-mean	value-facets-mean
    set self-direction-mean	value-facets-mean
    set universalism-mean 100 -	value-facets-mean
    set benevolence-mean	100 - value-facets-mean
    set conformity-mean	100 - value-facets-mean
    set tradition-mean 100 -	value-facets-mean
    set security-mean	100 - value-facets-mean
    set power-mean	value-facets-mean
    set achievement-mean	value-facets-mean
  ]

  if facets = "self-protection" [
    set hedonism-mean 100 -	value-facets-mean
    set stimulation-mean 100 -	value-facets-mean
    set self-direction-mean	100 - value-facets-mean
    set universalism-mean	100 - value-facets-mean
    set benevolence-mean 100 -	value-facets-mean
    set conformity-mean	value-facets-mean
    set tradition-mean	value-facets-mean
    set security-mean	value-facets-mean
    set power-mean	value-facets-mean
    set achievement-mean	value-facets-mean
  ]

  set importance-hedonism-value normalize-data-in-range hedonism-mean value-std-dev
  set importance-stimulation-value normalize-data-in-range stimulation-mean value-std-dev
  set importance-self-direction-value normalize-data-in-range self-direction-mean value-std-dev
  set importance-universalism-value normalize-data-in-range universalism-mean value-std-dev
  set importance-benevolence-value normalize-data-in-range benevolence-mean value-std-dev
  set importance-conformity-value normalize-data-in-range conformity-mean value-std-dev
  set importance-tradition-value normalize-data-in-range tradition-mean value-std-dev
  set importance-security-value normalize-data-in-range security-mean value-std-dev
  set importance-power-value normalize-data-in-range power-mean value-std-dev
  set importance-achievement-value normalize-data-in-range achievement-mean value-std-dev

  set value-system (list
    importance-hedonism-value
    importance-stimulation-value
    importance-self-direction-value
    importance-universalism-value
    importance-benevolence-value
    importance-conformity-value
    importance-tradition-value
    importance-security-value
    importance-power-value
    importance-achievement-value)

end

to align-value-systems [disaligned-value-system]
  ; This procedure is used to make sure that the range between each of the Schwartz values doesn't exceed the pre-set range (max-range-between-values)
  let value-system-copy disaligned-value-system
  let value-system-copy2 disaligned-value-system
  let value-consistant? (list true true true true )
  while [member? true value-consistant?] [
    let N length value-system-copy
    let k 0

    let index-i 0
    let index-j 0

    let Vi-update 0
    let Vj-update 0
    let v-update-list 0

    while [k < N ] [
      set index-j 0
      while [index-j < N] [
        set v-update-list calibrate-values index-i index-j value-system-copy
        set Vi-update item 0 v-update-list
        set Vj-update item 1 v-update-list

        set value-system-copy replace-item index-i value-system-copy Vi-update
        set value-system-copy replace-item index-j value-system-copy Vj-update
        set index-j index-j + 1
      ]
      set value-system-copy lput item 0 value-system-copy value-system-copy
      set value-system-copy remove-item 0 value-system-copy
      set k k + 1
    ]
    set value-consistant? (map != value-system-copy value-system-copy2)
    set value-system-copy2 value-system-copy
  ]


  set importance-hedonism-value precision (item 0 value-system-copy) 3
  set importance-stimulation-value precision item 1 value-system-copy 3
  set importance-self-direction-value precision item  2 value-system-copy 3
  set importance-universalism-value precision item 3 value-system-copy 3
  set importance-benevolence-value precision item 4 value-system-copy 3
  set importance-conformity-value precision item 5 value-system-copy 3
  set importance-tradition-value precision item 6 value-system-copy 3
  set importance-security-value precision item 7 value-system-copy 3
  set importance-power-value precision item 8 value-system-copy 3
  set importance-achievement-value precision item 9 value-system-copy 3

  set value-system value-system-copy



end

;the computational procedure within this reporter is based on Heidari et al. (2018): https://link.springer.com/chapter/10.1007/978-3-030-34127-5_19
to-report calibrate-values [#index-i #index-j #value-system]
  ;; Condition 1 from Heidari: The difference in prioritization of affiliating values (values that are placed close to one another within the Schwartz circumplex) cannot exceed
  ;; the set limit: cd1-max-range-between values.

  ;Load value levels into local variable
  let V-i (item #index-i #value-system)
  let V-j (item #index-j #value-system)

  ;determine difference between indices (i.e. distance between values on the Schwartz circumplex)
  let d-index abs (#index-i - #index-j)
  ;determine difference in value levels
  let d-V abs (V-i - V-j)
  ;load calibration factor (a lower calibration factor means that values placed close to one another on the Schwartz circumplex will hold more similar importance levels)
  ;default setting for value-system-calibration-factor is 25 (based on Heidari et al., 2018)
  let cf cd1-max-range-between-values

  ;initiate boundaries LB (lower bound), UB (upper bound) (this is based on condition 1; see Heidari et al., 2018)
  let LB 0
  let UB 0
  let UB-i d-index * cf
  let UB-j (10 - d-index) * cf

  ifelse d-index <= 5 [
    set UB UB-i
  ][
    set UB UB-j
  ]

  ;d-Vc is constrained (c) difference (d) between value levels (V)
  let d-Vc 0
  ifelse d-V > UB [
    ;if difference between value levels is higher than UB, set dVc to UB
    set d-Vc UB
  ][
    ;if difference between value levels is NOT higher than UB, set dVc to dV
    set d-Vc d-V
  ]

  ;determine difference between unconstrained delta value levels [dV] and constrained delta value levels [dVc]
  let diff-dV-dVc (d-V - d-Vc)

  let delta 0

  ;ONLY if dV > dVc, then values move closer towards one another as to respect the condition LB < dV < UB
  if d-V > d-Vc [
    set delta diff-dV-dVc / 2
    ifelse V-i > V-j [
      ;if Vi is larger than Vj, then Vi decreases and Vj increases
      set V-i V-i - delta
      set V-j V-j + delta
    ][
      ;if Vi is smaller than Vj, then Vi increases and Vj decreases
      set V-i V-i + delta
      set V-j V-j - delta
    ]
  ]
  ;; Condition 2 from heidari et. al 2018: SUM of importances of antagonistic value pairs within Schwartz circumplex could never exceed cd2-max-sum-antagonistic-value-pairs. When
  ;; the sum exceeds the set limit, half of the difference between the sum and the limit is substracted from each value priorization.
  ;; This condition can be switched on and off by using this switch within the interface: cd2-limit-max-sum-antagonistic-value-pairs?
  if cd2-active-limitation-max-sum-antagonistic-value-pairs? [
    if #index-j = 4 [
      let dVi-Vj 0
      let V-correction 0
      set dVi-Vj V-i + V-j
      if dVi-Vj > cd2-max-sum-antagonistic-value-pairs  [
        set V-correction ( (dVi-Vj - cd2-max-sum-antagonistic-value-pairs  ) / 2)
        set V-i V-i - V-correction
        set V-j V-j - V-correction
      ]
      if dVi-Vj < cd2-min-sum-antagonistic-value-pairs  [
        set V-correction ( (cd2-min-sum-antagonistic-value-pairs - dVi-Vj  ) / 2)
        set V-i V-i + V-correction
        set V-j V-j + V-correction
      ]
    ]
  ]

  set V-i clamp 0 100 V-i
  set V-j clamp 0 100 V-j
  report (list V-i V-j)
end

to setup-trait-system
  let neuroticism-mean neuroticism-trait-population ; no correlating values
  let extraversion-mean precision ((0.31 * importance-power-value + 0.31 * importance-achievement-value + 0.20 * importance-hedonism-value + 0.36 * importance-stimulation-value ) / (0.31 + 0.31 + 0.20 + 0.36) ) 3
  let agreeableness-mean precision (( 0.42 * (100 - importance-power-value) + 0.39 * importance-universalism-value + 0.61 * importance-benevolence-value + 0.26 * importance-conformity-value + 0.22 * importance-tradition-value ) / ( 0.42 + 0.39 + 0.61 + 0.26 + 0.22)) 3
  let conscientiousness-mean precision (( 0.17 * importance-achievement-value + 0.27 * importance-conformity-value + 0.37 * importance-security-value ) / (0.17 + 0.27 + 0.37) ) 3
  let openness-mean precision (( 0.36 * importance-stimulation-value + 0.52 * importance-achievement-value + 0.33 * importance-universalism-value + 0.27 * ( 100 - importance-conformity-value)  + 0.31 * ( 100 - importance-tradition-value)  + 0.24 * ( 100 - importance-security-value) ) / ( 0.36 + 0.52 + 0.33 + 0.27 + 0.31 + 0.24 ) ) 3

  set neuroticism-trait normalize-data-in-range neuroticism-mean (trait-std-dev)
  set extraversion-trait normalize-data-in-range extraversion-mean trait-std-dev
  set agreeableness-trait normalize-data-in-range agreeableness-mean trait-std-dev
  set conscientiousness-trait normalize-data-in-range conscientiousness-mean trait-std-dev
  set openness-trait normalize-data-in-range openness-mean trait-std-dev

  set trait-system (list openness-trait conscientiousness-trait agreeableness-trait extraversion-trait neuroticism-trait)
end



to setup-education-level
  ask people [
    if access-to-education > random-float 100 [
      if conscientiousness-trait > high-educ-trait-level and openness-trait > high-educ-trait-level [
        set education-level "high"
        set RSQ-modifier-information (200 - openness-trait - agreeableness-trait ) / 200 * ( 1 / high-education-information-modifier) * Raw-RSQ-Modifier stop]
      if conscientiousness-trait > medium-educ-trait-level and openness-trait > medium-educ-trait-level [
        set education-level "medium"
        set RSQ-modifier-information (200 - openness-trait - agreeableness-trait ) / 200 * (1 / medium-education-information-modifier) * Raw-RSQ-Modifier stop]
    ]
    set education-level "low"
    set RSQ-modifier-information (200 - openness-trait - agreeableness-trait ) / 200 * (1 / low-education-information-modifier) * Raw-RSQ-Modifier
  ]
end

to setup-moral-concern-system
  set pt-moral-concern 50
  set stage-of-moral-concern 0
  set moral-distribution-power (base-moral-distribution-power + stage-of-moral-concern * bonus-power-per-extra-stage-of-moral-concern) * (extraversion-trait / 100)
  set RSQ-modifier-acknowledgement (100 - conscientiousness-trait) / 100 * Raw-RSQ-Modifier
  set RSQ-modifier-believe (100 - (openness-trait + extraversion-trait) / 2) / 100 * Raw-RSQ-Modifier
  set RSQ-modifier-willingness (100 - importance-universalism-value + 100 - importance-benevolence-value) / 2 / 100 * Raw-RSQ-Modifier
end

to setup-social-network
  ifelse setup-number-of-friends-based-on-extraversion-trait?
  [setup-#number-of-friends-people-have ]
  [ask people [  set #neighbour-friends-to-make round (random-gamma #friends-alpha #friends-lambda ) ] ]

  if setup-friends-based-on-value-similarity? [
    ifelse setup-friends-based-on-agreeableness-trait?
    [
      foreach sort-on [agreeableness-trait] people [
        x -> ask x [
          let favourable-friends-list (sort-on [value-euclidean-distance myself] potential-friends)
          repeat clamp 0 #neighbour-friends-to-make (#neighbour-friends-to-make - count my-friends) [
            if length favourable-friends-list > 0 [
              create-my-friends-link-with item 0 favourable-friends-list
              set favourable-friends-list but-first favourable-friends-list
            ]
          ]
        ]
      ]
    ]
    [
      ask people [
        repeat clamp 0 #neighbour-friends-to-make (#neighbour-friends-to-make - count my-friends) [
          let favourable-friends-list (sort-on [value-euclidean-distance myself] potential-friends)
          if length favourable-friends-list > 0 [
            create-my-friends-link-with person 1
            set favourable-friends-list but-first favourable-friends-list
          ]
        ]
      ]
    ]
    ask n-of round (%-of-non-value-based-friends / 100 * count my-friends-links) my-friends-links [
      die ]
    ]

    setup-friends-randomly
end

to setup-#number-of-friends-people-have   ;;https://www.researchgate.net/publication/336738796_Personality_and_Friendships
  let list-people-sorted-on-extraversion-decending sort-on [(- extraversion-trait)] people
  let list-generator#-friends (list)
  repeat total-population [
    set list-generator#-friends lput (round (random-gamma #friends-alpha #friends-lambda )) list-generator#-friends ]
  set list-generator#-friends sort-by > list-generator#-friends
  (foreach list-generator#-friends list-people-sorted-on-extraversion-decending [
    [x y] -> ask y [set #neighbour-friends-to-make x ] ] )
end

to setup-friends-randomly
  ask people [
    create-my-friends-links-with up-to-n-of clamp 0 #neighbour-friends-to-make (#neighbour-friends-to-make - count my-friends) potential-friends]
end

to-report potential-friends
  report other people with [my-neighbourhood = [my-neighbourhood] of myself and #neighbour-friends-to-make > count my-friends and not member? self [my-friends-link-neighbors] of myself ]
end

to-report my-friends
  report my-friends-link-neighbors
end

to-report number-of-friends
  report count my-friends-link-neighbors
end

to-report identity-of-friends
  let k (list)
  ask my-friends [
    set k lput who k]
  report k
end

to-report value-euclidean-distance [other-agent]
  report sqrt sum (list
    ((importance-hedonism-value - [importance-hedonism-value] of other-agent) ^ 2)
    ((importance-stimulation-value - [importance-stimulation-value] of other-agent) ^ 2)
    ((importance-self-direction-value - [importance-self-direction-value] of other-agent) ^ 2)
    ((importance-universalism-value - [importance-universalism-value] of other-agent) ^ 2)
    ((importance-benevolence-value - [importance-benevolence-value] of other-agent) ^ 2)
    ((importance-conformity-value - [importance-conformity-value] of other-agent) ^ 2)
    ((importance-tradition-value - [importance-tradition-value] of other-agent) ^ 2)
    ((importance-security-value - [importance-security-value] of other-agent) ^ 2)
    ((importance-power-value - [importance-power-value] of other-agent) ^ 2)
    ((importance-achievement-value - [importance-achievement-value] of other-agent) ^ 2))
end

to setup-appearance
  ask people [
    set size 0.3 + 0.075 * count my-friends
    ask my-friends [
      let vs value-similarity-between-two-friends myself self
      ask my-friends-link who [who] of myself [
        set friendly-distance vs
        set my-color-code vs / 150 * 255
        set color rgb 0 (255 - (vs / 150 * 255)) 0] ]
  ]
  ask patches [
    set pcolor white]

  layout-circle people with [my-neighbourhood = "high-income"]  8
  ask people with [my-neighbourhood = "high-income"] [
    setxy xcor  - 8.2 ycor + 7.5
    set color 12 + (agreeableness-trait / 100 * 6) ]
  layout-circle people with [my-neighbourhood = "medium-income"]  8
  ask people with [my-neighbourhood = "medium-income"] [
    setxy xcor + 8.2 ycor + 7.5
    set color 92 + (agreeableness-trait / 100 * 6) ]
  layout-circle people with [my-neighbourhood = "low-income"]  8
  ask people with [my-neighbourhood = "low-income"] [
    setxy xcor + 0 ycor - 7.5
    set color 42 + (agreeableness-trait / 100 * 6) ]



end

to-report value-similarity-between-two-friends [agent-one agent-two]
  let ved (list)
  (foreach [value-system] of agent-one [value-system] of agent-two [
    [x y] -> set ved lput ((x - y) ^ 2) ved ])
  report sqrt sum ved
end

to-report link-color-based-on-value-similarity [friends]
  report 48 - (value-similarity-between-two-friends item 0 friends item 1 friends) / 50 * 6
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Dynamic Cognitve Architecture ;;;;;;;;;;;;;;;;;;;;;;;;;;;;





to go
  tick
  update-metrics
  disruptive-event
  update-moral-concern
  social-interaction
  update-moral-concern
  apply-return-to-status-quo
end

to disruptive-event
  set global-event-impact generate-impact-event
  if random 100 < %-opposing-information [ set global-event-impact global-event-impact * -1 ]
  ask people [
    ifelse random 100 < %-global-event  ;; determine on an individual level whether the global event applies for each individual. %-global-event = 30 means that durin each tick about 30% will not experience the global event but generate an individual event.
    [
      set event-impact global-event-impact
      set pt-moral-concern pt-moral-concern + event-impact
    ]
    [set event-impact generate-impact-event
      if random 100 < %-opposing-information [ set global-event-impact global-event-impact * -1 ]
      set pt-moral-concern pt-moral-concern + event-impact
    ]
  ]
end

to-report generate-impact-event
  ifelse cap-impact-event?
  [report clamp 0 max-impact-event (random-exponential Event-mean-exponential-distribution) ]
  [report random-exponential Event-mean-exponential-distribution]
end

to update-moral-concern
  ask people [
    if pt-moral-concern > 100 and stage-of-moral-concern = 4 [
      set pt-moral-concern 100 ]
    if pt-moral-concern > 100 and stage-of-moral-concern < 4 [
      set pt-moral-concern 50
      set stage-of-moral-concern stage-of-moral-concern + 1 ]
    if pt-moral-concern < 0 and stage-of-moral-concern > 0 [
      set pt-moral-concern 50
      set stage-of-moral-concern stage-of-moral-concern - 1 ]
    if pt-moral-concern < 0 and stage-of-moral-concern = 0 [
      set pt-moral-concern 0]

    set moral-distribution-power (base-moral-distribution-power + stage-of-moral-concern * bonus-power-per-extra-stage-of-moral-concern) * (extraversion-trait / 100)
  ]
end


to social-interaction
  ask people [
    if random 100 < %-to-meet-random-person [
      set meeting-random-person-instead-of-friend? true ] ]

  friendly-interaction
  random-interaction

end

to random-interaction
  ask people with [number-of-friends > 0 and meeting-random-person-instead-of-friend?] [
    if not met-neighbour? [
      if any? random-people-to-meet [
        ifelse any? random-people-to-meet with [not met-neighbour? ]
        [meet-neighbour-procedure self one-of random-people-to-meet with [not met-neighbour?] ]
        [meet-neighbour-procedure self one-of random-people-to-meet ]
      ]
    ]
  ]
end

to-report random-people-to-meet
  report other people with [meeting-random-person-instead-of-friend? and my-neighbourhood = [my-neighbourhood] of myself]
end


to friendly-interaction
  ask people with [number-of-friends > 0 and not meeting-random-person-instead-of-friend?] [

    if not met-neighbour? [
      ifelse any? my-friends with [not met-neighbour?]
      [meet-neighbour-procedure self one-of my-friends with [not met-neighbour?] ]
      [meet-neighbour-procedure self one-of my-friends ]
    ]
  ]
end


;!!!!!!!!!!!!!!!! This need attention: How does one agents influences the other agents moral conern.
to meet-neighbour-procedure [civ-one civ-two]
  if [extraversion-trait] of civ-one > (100 - [agreeableness-trait] of civ-two) [
    change-perception-thermometer-due-to-interaction-with-other-agent civ-one civ-two [moral-distribution-power] of civ-one ]
  if [extraversion-trait] of civ-two > (100 - [agreeableness-trait] of civ-one) [
    change-perception-thermometer-due-to-interaction-with-other-agent civ-two civ-one [moral-distribution-power] of civ-two ]
  ask civ-two [set met-neighbour? true]
  set met-neighbour? true
end

to change-perception-thermometer-due-to-interaction-with-other-agent [persuader recipient impact-meeting]
  if [stage-of-moral-concern] of persuader > [stage-of-moral-concern] of recipient [
    ask recipient [set pt-moral-concern pt-moral-concern + impact-meeting stop]
  ]
  if [stage-of-moral-concern] of persuader < [stage-of-moral-concern] of recipient [
    ask recipient [set pt-moral-concern pt-moral-concern - impact-meeting ]
  ]
end



to apply-return-to-status-quo
  ask people [
  if pt-moral-concern > 50 [
    set pt-moral-concern max (list 50 (pt-moral-concern - define-RSQ-modifier)) ]
  if pt-moral-concern < 50 [
    set pt-moral-concern min (list 50 (pt-moral-concern + define-RSQ-modifier)) ]
  ]

end

to-report define-RSQ-modifier
  let RSQ 0
  if stage-of-moral-concern = 4 and pt-moral-concern > 50 [
    set RSQ RSQ-modifier-willingness
    set active-RSQ "Willingness"
    report RSQ]
  if stage-of-moral-concern = 4 and pt-moral-concern < 50 [
    set RSQ RAW-RSQ-modifier - RSQ-modifier-willingness
    set active-RSQ "Reverse Willingness"
    report RSQ]
  if stage-of-moral-concern = 3 and pt-moral-concern > 50 [
    set RSQ RSQ-modifier-willingness
    set active-RSQ "Willingness"
    report RSQ]
  if stage-of-moral-concern = 3 and pt-moral-concern < 50 [
    set RSQ RAW-RSQ-modifier - RSQ-modifier-Believe
    set active-RSQ "Reverse Believing"
    report RSQ]
  if stage-of-moral-concern = 2 and pt-moral-concern > 50 [
    set RSQ RSQ-modifier-Believe
    set active-RSQ "Believing"
    report RSQ]
  if stage-of-moral-concern = 2 and pt-moral-concern < 50 [
    set RSQ RAW-RSQ-modifier - RSQ-modifier-acknowledgement
    set active-RSQ "Reverse Acknowledging"
    report RSQ]
  if stage-of-moral-concern = 1 and pt-moral-concern > 50 [
    set RSQ RSQ-modifier-acknowledgement
    set active-RSQ "Acknowledging"
    report RSQ]
  if stage-of-moral-concern = 1 and pt-moral-concern < 50 [
    set RSQ (1 / low-education-information-modifier) * Raw-RSQ-Modifier - RSQ-modifier-information
    set active-RSQ "Reverse Information"
    report RSQ]
  IF stage-of-moral-concern = 0 [
    set RSQ RSQ-modifier-information
    set active-RSQ "Information"
   report RSQ]


end

to update-metrics
  ask people [
    set met-neighbour? false
    set meeting-random-person-instead-of-friend? false
  ]
  set global-event-impact 0

end









;;;;;;;;;;;;;;;;;   Utility stuff for plots and behaviorspace ;;;;;;;;;;;;;;;;;;;;;



;; When using behaviorspace put ";" for the parameters you would like to vary and place those parameters within the vary variable section of the behaviorspace
to setup-default-settings

  set static-seed? false
  ;set population-scenario "mixed"
  set track-individual-agents "none"

  ; events
  set %-global-event 75
  set Event-mean-exponential-distribution 5
  set %-opposing-information 15

  ; perception-thermometers
  set Raw-RSQ-Modifier 0.1

  ; social interaction
  set %-to-meet-random-person 20

  ; social network
  set #friends-alpha 1.5
  set #friends-lambda 0.35
  set setup-number-of-friends-based-on-extraversion-trait? true
  set setup-friends-based-on-value-similarity? true
  set %-of-non-value-based-friends 10
  set setup-friends-based-on-agreeableness-trait? true


  ; Moral concern and Return to Status Quo (RSQ)
  set Raw-RSQ-Modifier 13
  set base-moral-distribution-power 20
  set bonus-power-per-extra-stage-of-moral-concern 1.2
  set high-education-information-modifier 1.2
  set medium-education-information-modifier 0.8
  set low-education-information-modifier 0.6

  ; values
  set value-facets-mean 75
  set value-std-dev 20
  set cd2-active-limitation-max-sum-antagonistic-value-pairs? true
  set cd2-max-sum-antagonistic-value-pairs 120

  ; traits
  set neuroticism-trait-population 50
  set trait-std-dev 20

  ;education
  set access-to-education-high-income 100
  set access-to-education-medium-income 80
  set access-to-education-low-income 60

  set high-educ-trait-level 45
  set medium-educ-trait-level 25


end

to setup-agents-to-track
  if track-individual-agents = "growth" [
    ask one-of people [set gr-to-track self ]
  ]

  if track-individual-agents = "personal" [
    ask one-of people [set pr-to-track self ]
  ]

  if track-individual-agents = "social" [
    ask one-of people [ set sc-to-track self ]
  ]

  if track-individual-agents = "self-protection" [
    ask one-of people [  set sp-to-track self ]
  ]

  if track-individual-agents = "all" [
    ask one-of people with [my-facet = "growth"] [
      set gr-to-track self ]
    ask one-of people with [ my-facet = "personal"] [
      set pr-to-track self ]
    ask one-of people with [ my-facet = "social"] [
      set sc-to-track self ]
    ask one-of people with [ my-facet = "self-protection"] [
      set sp-to-track self ]
  ]
end

to update-high-income-plots
  set-current-plot "Edu-lvl -- HIGH-income NBH"
  clear-plot
  let a table:counts [ education-level ] of people with [my-neighbourhood = "high-income"]
  let b sort table:keys a
  let c length b
  let k 0
  let colors (list blue red yellow)
  set-plot-x-range 0 c
  let step 0.05 ; tweak this to leave no gaps
  (foreach b range c [ [s i] ->
    let y table:get a s
    let d item k colors
    set k k + 1
    create-temporary-plot-pen s
    set-plot-pen-mode 1 ; bar mode
    set-plot-pen-color d
    foreach (range 0 y step) [ _y -> plotxy i _y ]
    set-plot-pen-color black
    plotxy i y
    set-plot-pen-color d ; to get the right color in the legend
  ])

end
to update-medium-income-plots
  set-current-plot "Edu-lvl -- MIDDLE-income NBH"
  clear-plot
  let a table:counts [ education-level ] of people with [my-neighbourhood = "medium-income"]
  let b sort table:keys a
  let c length b
  let k 0
  let colors (list blue red yellow)
  set-plot-x-range 0 c
  let step 0.05 ; tweak this to leave no gaps
  (foreach b range c [ [s i] ->
    let y table:get a s
    let d item k colors
    set k k + 1
    create-temporary-plot-pen s
    set-plot-pen-mode 1 ; bar mode
    set-plot-pen-color d
    foreach (range 0 y step) [ _y -> plotxy i _y ]
    set-plot-pen-color black
    plotxy i y
    set-plot-pen-color d ; to get the right color in the legend
  ])

end

to update-low-income-plots

  set-current-plot "Edu-lvl -- LOW-income NBH"
  clear-plot
  let a table:counts [ education-level ] of people with [my-neighbourhood = "low-income"]
  let b sort table:keys a
  let c length b
  let k 0
  let colors (list blue red yellow)
  set-plot-x-range 0 c
  let step 0.05 ; tweak this to leave no gaps
  (foreach b range c [ [s i] ->
    let y table:get a s
    let d item k colors
    set k k + 1
    create-temporary-plot-pen s
    set-plot-pen-mode 1 ; bar mode
    set-plot-pen-color d
    foreach (range 0 y step) [ _y -> plotxy i _y ]
    set-plot-pen-color black
    plotxy i y
    set-plot-pen-color d ; to get the right color in the legend
  ])

end



to write-network-to-file [file]
  if file-exists? file [file-delete file]
  file-open file
  file-print "graph {"
  file-print "graph [overlap=false];"
  file-print "node [style=filled];"
  ask my-friends-links [
    let turtle1 min-one-of both-ends [who]
    let turtle2 max-one-of both-ends [who]
    file-print (word "\"" [who] of turtle1 "\" -- \"" [who] of turtle2 "\";")
  ]
  file-print "}"
  file-close
end

to write-cognitive-identity-to-csv
  csv:to-file "identity-cards.csv" [my-cognitive-identity] of people
end





to-report my-cognitive-identity
  let vsr (list)
  set vsr lput who vsr
  set vsr lput my-population-scenario vsr
  (foreach value-system-setup [
    [x] -> set vsr lput x vsr
  ])
  (foreach trait-system [
    [x] -> set vsr lput x vsr
  ])
  report vsr
end



to-report neighbours-orientation
  let x (list)
  ask my-friends [
    set x lput my-facet x ]
  report x
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

; Clamps a number between 0 and 1, but doesn't let it reach either value
; Based on a Gompertz function
to-report clamp-soft [number]
  ifelse number < 0.5
  [report exp(-5 * exp(-4 * number))]
  [let x 1 - number
    set x exp(-5 * exp(-4 * x))
    report 1 - x ]
end

to-report return-position-of-item-from-list [#criteria #list]
  let indices n-values length #list [ i -> i ]
  let result filter [ i -> item i #list = #criteria ] indices
  report result
end

to-report TRANSFORM-LIST! [#list #sep]
  if  #list = 0 [report #list]
  if not empty? #list [report reduce [[x y] -> (word x #sep y)] #list]
  report #list
end

to update-value-plot
  set-current-plot "Value system Person X"
  clear-plot
  ask person interface-person [
    let name-value-list (list
      "Hedonism"
      "Stimulation"
      "Self-direction"
      "Universalism"
      "Benevolence"
      "Conformity"
      "Tradition"
      "Security"
      "Power"
      "Achievement" )
    let vtable table:make
    (foreach name-value-list value-system
      [ [ a b] -> table:put vtable a b])
    let values table:keys vtable
    let n length values
    set-plot-x-range 0 n
    let step 0.05 ; tweak this to leave no gaps
    (foreach values range n [ [s i] ->
      let y table:get vtable s
      let c hsb (i * 360 / n) 50 75
      create-temporary-plot-pen s
      set-plot-pen-mode 1 ; bar mode
      set-plot-pen-color c
      foreach (range 0 y step) [ _y -> plotxy i _y ]
      set-plot-pen-color black
      plotxy i y
      set-plot-pen-color c ; to get the right color in the legend
    ])
  ]
end


to update-trait-plot
  set-current-plot "Trait System Person X"
  clear-plot
  ask person interface-person [
    let trait-list (list
      neuroticism-trait
      extraversion-trait
      agreeableness-trait
      conscientiousness-trait
      openness-trait )
    let name-trait-list (list
      "Neuroticism"
      "Extraversion"
      "Agreeableness"
      "Conscientiousness"
      "Openness")
    let ttable table:make
    (foreach name-trait-list trait-list
      [ [ a b] -> table:put ttable a b])
    let traits table:keys ttable
    let n length traits
    set-plot-x-range 0 n
    let step 0.05 ; tweak this to leave no gaps
    (foreach traits range n [ [s i] ->
      let y table:get ttable s
      let c hsb (i * 360 / n) 50 75
      create-temporary-plot-pen s
      set-plot-pen-mode 1 ; bar mode
      set-plot-pen-color c
      foreach (range 0 y step) [ _y -> plotxy i _y ]
      set-plot-pen-color black
      plotxy i y
      set-plot-pen-color c ; to get the right color in the legend
    ])
  ]
end

to update-RSQ-modifiers-plot
  set-current-plot "RSQ modifiers Person X"
  clear-plot
  ask person interface-person [
    let RSQ-list (list
      RSQ-modifier-information
      RSQ-modifier-acknowledgement
      RSQ-modifier-Believe
      RSQ-modifier-willingness )
    let name-trait-list (list
      "RSQ-Information"
      "RSQ-Acknowledgement"
      "RSQ-Believing"
      "RSQ-Willingness")
    let ttable table:make
    (foreach name-trait-list RSQ-list
      [ [ a b] -> table:put ttable a b])
    let traits table:keys ttable
    let n length traits
    set-plot-x-range 0 n
    let step 0.05 ; tweak this to leave no gaps
    (foreach traits range n [ [s i] ->
      let y table:get ttable s
      let c hsb (i * 360 / n) 50 75
      create-temporary-plot-pen s
      set-plot-pen-mode 1 ; bar mode
      set-plot-pen-color c
      foreach (range 0 y step) [ _y -> plotxy i _y ]
      set-plot-pen-color black
      plotxy i y
      set-plot-pen-color c ; to get the right color in the legend
    ])
  ]
end




to update-friends-plot
  set-current-plot "Value Orientations of Friends of Person X"
  clear-plot
  ask person interface-person [
    let friend-list (list
      count my-friends with [my-facet = "growth"]
      count my-friends with [my-facet = "personal"]
      count my-friends with [my-facet = "self-protection"]
      count my-friends with [my-facet = "social"] )
    let name-trait-list (list
      "#-Growth"
      "#-Personal"
      "#-Self-Protection"
      "#-Social")
    let ttable table:make
    (foreach name-trait-list friend-list
      [ [ a b] -> table:put ttable a b])
    let traits table:keys ttable
    let n length traits
    set-plot-x-range 0 n
    let step 0.05 ; tweak this to leave no gaps
    (foreach traits range n [ [s i] ->
      let y table:get ttable s
      let c hsb (i * 360 / n) 50 75
      create-temporary-plot-pen s
      set-plot-pen-mode 1 ; bar mode
      set-plot-pen-color c
      foreach (range 0 y step) [ _y -> plotxy i _y ]
      set-plot-pen-color black
      plotxy i y
      set-plot-pen-color c ; to get the right color in the legend
    ])
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1812
124
2427
740
-1
-1
18.4
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

BUTTON
11
18
75
51
NIL
Setup
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
10
61
73
94
NIL
Go
T
1
T
OBSERVER
NIL
P
NIL
NIL
1

BUTTON
9
146
88
179
Go once
Go 
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
1

SLIDER
402
99
629
132
cd1-max-range-between-values
cd1-max-range-between-values
0
100
25.0
1
1
NIL
HORIZONTAL

BUTTON
9
189
132
222
inspect Person 1
inspect person 1
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

PLOT
402
138
880
385
Value Distribution Population
Value prioritization (Interval 5)
Number of People
0.0
100.0
0.0
500.0
true
true
"\n" "set-plot-x-range 0 100\nset-plot-y-range 0 20"
PENS
"HED" 5.0 0 -5298144 true "" "histogram [importance-hedonism-value] of people"
"STI" 5.0 0 -612749 true "" "histogram [importance-stimulation-value] of people"
"SD" 5.0 0 -4079321 true "" "histogram [importance-self-direction-value] of people"
"UNI" 5.0 0 -8330359 true "" "histogram [importance-universalism-value] of people"
"BEN" 5.0 0 -11881837 true "" "histogram [importance-benevolence-value] of people"
"CON" 5.0 0 -11221820 true "" "histogram [importance-conformity-value] of people"
"TRA" 5.0 0 -13345367 true "" "histogram [importance-tradition-value] of people"
"SEC" 5.0 0 -11783835 true "" "histogram [importance-security-value] of people"
"PWR" 5.0 0 -6917194 true "" "histogram [importance-power-value] of people"
"ACH" 5.0 0 -4699768 true "" "histogram [importance-achievement-value] of people"

PLOT
203
1378
681
1618
Value System Person X
Value type
Value Prioritization
0.0
10.0
0.0
100.0
true
true
"" "update-value-plot"
PENS

SLIDER
951
83
1123
116
trait-std-dev
trait-std-dev
1
40
20.0
0.5
1
NIL
HORIZONTAL

PLOT
896
138
1370
391
Trait Distribution Population 
Trait score (Interval 5)
Number of People
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range 0 100\nset-plot-y-range 0 40" ""
PENS
"Neuroticism" 5.0 0 -4079321 true "" "histogram [neuroticism-trait] of people"
"Extraversion" 5.0 0 -8330359 true "" "histogram [extraversion-trait] of people"
"Agreeableness" 5.0 0 -8990512 true "" "histogram [agreeableness-trait] of people"
"Conscientiousness" 5.0 0 -8630108 true "" "histogram [conscientiousness-trait] of people"
"Openness" 5.0 0 -3508570 true "" "histogram [openness-trait] of people"

PLOT
708
1379
1122
1617
Trait System Person X
Trait Type
Trait Score
0.0
6.0
0.0
100.0
false
true
"update-trait-plot" ""
PENS

SLIDER
951
48
1123
81
neuroticism-trait-population
neuroticism-trait-population
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
952
18
1119
43
Traits (OCEAN)
20
0.0
1

TEXTBOX
198
15
393
65
Values (Schwartz)
20
0.0
1

TEXTBOX
212
68
362
86
Population Size
14
0.0
1

SLIDER
203
223
375
256
#Population-growth
#Population-growth
0
1000
250.0
1
1
NIL
HORIZONTAL

SLIDER
203
265
375
298
#population-personal
#population-personal
0
1000
250.0
50
1
NIL
HORIZONTAL

SLIDER
206
348
381
381
#population-social
#population-social
0
1000
250.0
50
1
NIL
HORIZONTAL

SLIDER
206
308
380
341
#population-self-protection
#population-self-protection
0
1000
250.0
50
1
NIL
HORIZONTAL

SLIDER
402
55
574
88
value-std-dev
value-std-dev
0
20
20.0
1
1
NIL
HORIZONTAL

MONITOR
208
88
309
133
NIL
total-population
17
1
11

SLIDER
403
15
575
48
value-facets-mean
value-facets-mean
55
95
75.0
1
1
NIL
HORIZONTAL

TEXTBOX
655
772
805
798
Moral-Change
20
0.0
1

SLIDER
652
799
917
832
Raw-RSQ-Modifier
Raw-RSQ-Modifier
0
15
15.0
1
1
NIL
HORIZONTAL

CHOOSER
203
173
341
218
population-scenario
population-scenario
"none" "growth" "personal" "social" "self-protection" "mixed"
5

BUTTON
9
104
107
137
Go 40 years
repeat 2040 [go]
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

SWITCH
8
427
131
460
static-seed?
static-seed?
1
1
-1000

BUTTON
5
332
140
366
write network as a dote
write-network-to-file user-new-file
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
11
374
144
419
track-individual-agents
track-individual-agents
"none" "all" "growth" "personal" "social" "self-protection"
0

TEXTBOX
1188
18
1386
70
Social Interaction
20
0.0
1

PLOT
199
909
621
1165
Global-event-impact
Time (ticks)
Impact of event
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot global-event-impact"

SLIDER
205
829
402
862
Event-mean-exponential-distribution
Event-mean-exponential-distribution
0
7.5
5.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
205
759
431
793
Disruptive Events
20
0.0
1

SWITCH
592
15
907
48
cd2-active-limitation-max-sum-antagonistic-value-pairs?
cd2-active-limitation-max-sum-antagonistic-value-pairs?
0
1
-1000

SLIDER
588
55
849
88
cd2-max-sum-antagonistic-value-pairs
cd2-max-sum-antagonistic-value-pairs
100
130
130.0
1
1
NIL
HORIZONTAL

BUTTON
5
236
135
269
NIL
setup-default-settings
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
703
1246
1120
1366
Impact event Person X
Time (ticks)
Impact-event
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [event-impact] of person interface-person"

PLOT
203
1246
683
1366
Value Orientations of Friends of Person X
Value Orientation
Number of Friends
0.0
10.0
0.0
4.0
true
true
"update-friends-plot" ""
PENS

SLIDER
205
792
433
825
%-global-event
%-global-event
0
100
75.0
1
1
NIL
HORIZONTAL

MONITOR
593
1188
770
1233
Value-Orientation of Person X
[my-facet] of person interface-person
17
1
11

BUTTON
463
1202
588
1235
Inspect Person X
inspect person interface-person
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
783
1186
881
1231
Identiy-number
[who] of person interface-person
17
1
11

TEXTBOX
213
1218
505
1252
Cognitive Architecture of Person X:
14
0.0
1

BUTTON
6
284
172
317
write-cognitive-identity-to-csv
write-cognitive-identity-to-csv
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
1386
88
1558
121
#friends-alpha
#friends-alpha
0
10
1.5
0.5
1
NIL
HORIZONTAL

SLIDER
1383
125
1558
158
#friends-lambda
#friends-lambda
0.05
0.5
0.35
0.05
1
NIL
HORIZONTAL

SLIDER
445
462
617
495
high-educ-trait-level
high-educ-trait-level
0
60
45.0
1
1
NIL
HORIZONTAL

SLIDER
203
462
434
495
access-to-education-high-income
access-to-education-high-income
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
203
498
432
531
access-to-education-medium-income
access-to-education-medium-income
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
205
533
432
566
access-to-education-low-income
access-to-education-low-income
0
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
938
798
1178
831
high-education-information-modifier
high-education-information-modifier
0
1.5
1.2
0.01
1
NIL
HORIZONTAL

SLIDER
445
498
625
531
medium-educ-trait-level
medium-educ-trait-level
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
938
836
1178
869
medium-education-information-modifier
medium-education-information-modifier
0
1.5
0.8
.01
1
NIL
HORIZONTAL

SLIDER
935
873
1177
906
low-education-information-modifier
low-education-information-modifier
0
1.5
0.6
0.01
1
NIL
HORIZONTAL

TEXTBOX
446
442
596
460
Traits --> Education
13
0.0
1

TEXTBOX
206
439
426
472
Income --> Access education
13
0.0
1

TEXTBOX
952
778
1172
805
Education --> Impact Information
13
0.0
1

TEXTBOX
1386
18
1536
43
Social Network
20
0.0
1

SLIDER
652
836
868
869
base-moral-distribution-power
base-moral-distribution-power
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
652
873
925
906
bonus-power-per-extra-stage-of-moral-concern
bonus-power-per-extra-stage-of-moral-concern
1
2
1.2
0.1
1
NIL
HORIZONTAL

PLOT
1386
279
1796
488
#number-of-friends
Number of Friends
Number of People
0.0
30.0
0.0
60.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [number-of-friends] of people"

PLOT
203
578
527
728
Edu-lvl -- HIGH-income NBH
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"update-high-income-plots" ""
PENS

PLOT
542
579
856
729
Edu-lvl -- MIDDLE-income NBH
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"update-medium-income-plots" ""
PENS

PLOT
875
579
1189
729
Edu-lvl -- LOW-income NBH
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"update-low-income-plots" ""
PENS

PLOT
648
912
1041
1166
Moral Concern ---- HIGH Income NBH
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
"Unware" 1.0 0 -16777216 true "" "plot count people with [stage-of-moral-concern = 0 and my-neighbourhood = \"high-income\" ]"
"Informed" 1.0 0 -13840069 true "" "plot count people with [stage-of-moral-concern = 1 and my-neighbourhood = \"high-income\" ]"
"Acknowledged" 1.0 0 -2674135 true "" "plot count people with [stage-of-moral-concern = 2 and my-neighbourhood = \"high-income\" ]"
"Believing" 1.0 0 -13345367 true "" "plot count people with [stage-of-moral-concern = 3 and my-neighbourhood = \"high-income\" ]"
"Willing" 1.0 0 -6459832 true "" "plot count people with [stage-of-moral-concern = 4 and my-neighbourhood = \"high-income\" ]"

TEXTBOX
206
412
356
437
Education
20
0.0
1

SLIDER
1156
49
1356
82
%-to-meet-random-person
%-to-meet-random-person
0
100
20.0
1
1
NIL
HORIZONTAL

PLOT
1045
912
1421
1166
Moral Concern ---- MEDIUM Income NBH
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
"Unaware" 1.0 0 -16777216 true "" "plot count people with [stage-of-moral-concern = 0 and my-neighbourhood = \"medium-income\" ]"
"Informed" 1.0 0 -13840069 true "" "plot count people with [stage-of-moral-concern = 1 and my-neighbourhood = \"medium-income\"  ]"
"Acknowledging" 1.0 0 -2674135 true "" "plot count people with [stage-of-moral-concern = 2 and my-neighbourhood = \"medium-income\"  ]"
"Believing" 1.0 0 -13345367 true "" "plot count people with [stage-of-moral-concern = 3 and my-neighbourhood = \"medium-income\"  ]"
"Willing" 1.0 0 -6459832 true "" "plot count people with [stage-of-moral-concern = 4 and my-neighbourhood = \"medium-income\"  ]"

PLOT
1425
912
1771
1162
Moral Concern ---- LOW Income NBH
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
"Unaware" 1.0 0 -16777216 true "" "plot count people with [stage-of-moral-concern = 0 and my-neighbourhood = \"low-income\" ]"
"Informed" 1.0 0 -13840069 true "" "plot count people with [stage-of-moral-concern = 1 and my-neighbourhood = \"low-income\" ]"
"Acknowledging" 1.0 0 -2674135 true "" "plot count people with [stage-of-moral-concern = 2 and my-neighbourhood = \"low-income\" ]"
"Believing" 1.0 0 -14070903 true "" "plot count people with [stage-of-moral-concern = 3 and my-neighbourhood = \"low-income\" ]"
"Willing" 1.0 0 -6459832 true "" "plot count people with [stage-of-moral-concern = 4 and my-neighbourhood = \"low-income\" ]"

PLOT
1133
1382
1459
1619
Perception Thermometer Person X
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
"default" 1.0 0 -16777216 true "" "plot [pt-moral-concern] of person interface-person"

MONITOR
1462
1382
1605
1427
Stage of Moral Concern
item ([stage-of-moral-concern] of person interface-person) list-stages-moral-concern
17
1
11

MONITOR
893
1188
998
1233
Neighbourhood
[my-neighbourhood] of person interface-person
17
1
11

MONITOR
1005
1188
1102
1233
Education level
[education-level] of person interface-person
17
1
11

PLOT
1133
1248
1477
1381
RSQ modifiers Person X
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"update-rsq-modifiers-plot" ""
PENS

SLIDER
203
868
409
901
%-opposing-information
%-opposing-information
0
100
15.0
1
1
NIL
HORIZONTAL

MONITOR
1133
1192
1370
1237
Active RSQ-modifier
[active-RSQ] of person interface-person
17
1
11

SWITCH
1386
52
1741
85
setup-number-of-friends-based-on-extraversion-trait?
setup-number-of-friends-based-on-extraversion-trait?
0
1
-1000

SLIDER
1383
199
1589
232
%-of-non-value-based-friends
%-of-non-value-based-friends
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
1383
163
1660
196
setup-friends-based-on-value-similarity?
setup-friends-based-on-value-similarity?
0
1
-1000

SWITCH
1383
238
1686
271
setup-friends-based-on-agreeableness-trait?
setup-friends-based-on-agreeableness-trait?
0
1
-1000

PLOT
1385
495
1771
669
Value Differentiation between friendships
Euclidian differences between all values
Number of Friendships
0.0
200.0
0.0
10.0
true
false
"" ""
PENS
"default" 5.0 1 -16777216 true "" "histogram [friendly-distance] of my-friends-links"

BUTTON
9
505
152
539
inspect friendly links
inspect one-of my-friends-links
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1827
540
2015
563
NIL
11
0.0
1

TEXTBOX
1832
533
1972
772
Red shape = High Income \nBlue Shape = Medium Income\nYellow Shape = Low Income\n\nBigger Shape = More Friends\n\nDarker Color = More Agreeable\n\nMore Dark Green Link = More Value Differentiation between Friends\n
11
0.0
1

SWITCH
470
802
625
835
cap-impact-event?
cap-impact-event?
0
1
-1000

SLIDER
469
840
624
873
max-impact-event
max-impact-event
0
30
30.0
1
1
NIL
HORIZONTAL

PLOT
1782
914
2332
1163
Average Moral Concern of Top 10% Influencers by NBH
NIL
NIL
0.0
10.0
0.0
4.0
true
true
"" ""
PENS
"High income" 1.0 0 -2674135 true "" "plot mean [stage-of-moral-concern] of max-n-of (0.1 * count people with [my-neighbourhood = \"high-income\"]) people with [my-neighbourhood = \"high-income\"] [extraversion-trait]"
"Medium Income" 1.0 0 -13345367 true "" "plot mean [stage-of-moral-concern] of max-n-of (0.1 * count people with [my-neighbourhood = \"medium-income\"]) people with [my-neighbourhood = \"medium-income\"] [extraversion-trait]"
"Low Income" 1.0 0 -1184463 true "" "plot mean [stage-of-moral-concern] of max-n-of (0.1 * count people with [my-neighbourhood = \"low-income\"]) people with [my-neighbourhood = \"low-income\"] [extraversion-trait]"

SLIDER
656
99
912
132
cd2-min-sum-antagonistic-value-pairs
cd2-min-sum-antagonistic-value-pairs
0
100
70.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model illustrates the designing of heterogeneous populations within agent-based social simulations by equipping agents with Dynamic Value-based Cognitive Architectures (DVCA-model). The DVCA-model uses the psychological theories on values by Schwartz (2012) and character traits by McCrae and Costa (2008) to create an unique trait- and value prioritization system for each individual.Furthermore, the DVCA-model simulates the impact of both social persuasion and life-events (e.g. information, experience) on the value  systems of individuals by introducing the innovative concept of perception thermometers. Perception thermometers, controlled by the character traits, operate as buffers between the internal value prioritizations of agents and their external interactions. By introducing the concept of perception thermometers, the DVCA-model allows to study the dynamics of individual value prioritizations under a variety of external perturbations over extensive time periods. Possible applications are the use of the DVCA-model within artificial sociality, opinion dynamics social learning modelling, behavior selection algorithms and social-economic modelling.

## HOW IT WORKS

Based on the population group within the Schwartz circumplex (personal-focus, social-focus, growth-orientation, self-protection-orientation) an Agent configures its own cognitive architecture which consists of value prioritzations (Schwartz) and character traits (OCEAN). 

**Values prioritization system**
Values which are highly affiliated with their group (e.g. Benevolence, Universalism, Stimulation, Self-Direction and Hedonism for the Growth orientation population) have a higher prioritization score (towards 100), while values on the opposite of the circle have a lower prioritization score (towards 0). The unique value prioritization systems are generated by using an random normal distribution in which the affiliated values have a mean of equal to the **values-facet-mean** parameter and the non-affiliated values have a mean of 100 - **value-facets-mean** parameter. To increase/decrease the heterogeneity of the population, the std-dev of the value can be adjusted by using the **value-std-dev** parameter
![schwartz-circumplex](file:Schwartz-Circumplex.png) 
Afterwards, by using two conditions discussed in Heidair et al. (2018), the value prioritization systems are adjusted to make them consistent with the value theory of Schwartz. The first condition is that values that are close to one another within the Schwartz Value circumplex ('neighbouring value pairs') should hold a similar prioritizations. The maximum difference in prioritization between 'neighbouring value pairs' are capped and can be adjusted by the **cd1-max-range-between-values** parameter. The second condition is that values on the opposite site of the circle ('antagonistic value pairs') cannot BOTH have a high prioritization. Therefore the sum of the prioritization of each of the antagonistic value pairs is capped and can be adjusted by **cd2-max-sum-antagonistic-value-pairs** parameter. Within Heidari et al. (2018) the setting for the **cd2-max-sum-antagonistic-value-pairs** parameter is capped at 100. Simulation of this model however shows that this would limits the possibility for values to increase in importance, resulting in the tendency that on the long run, the total prioritization of all values decreases. Because of this effect, the limitation of the maximum sum of antagonistic value pairs can be (dis)activated by using the **cd2-active-limitation-max-sum-antagonistic-value-pairs?** switch. 

**Character Trait system**
Whereas values describe the long-term goals of individuals, character traits describe how people tend to actin dierent situations. Character traits are defined as "endogenous basic tendencies that influence patterns ofthoughts, feelings, and actions and that can be altered by exogenous interventions, processes, or events that affect their biological bases" (McCrae & Costa Jr 2008, p. 165). In contrary to values, trait scores are assumed to be static. Agents are equipped with 5 different character traits (i.e. Openness, Conscientiousness, Extraversion, Agreeableness and Neuroticism), which have a stable score between 0 (low affiliation) and 100 (high affiliation). According to the meta-analyses fo Parks-Leduc et al. (2015) the prioritization of values are correlated with 4 of the 5 OCEAN character traits (i.e. Openness, Conscientiousness, Extraversion and Agreeableness). The last character trait, Neuroticism does not show any correlation with the value prioritization of individuals. Based on this research, this model creates unique trait systems by using the value prioritization system of individuals.Based on the weighted mean from the **bold** correlations from the table below and the value prioritization scores, each individual computes its own mean for each of their traits. By using a normal random distribution with this computed mean and the **trait-std-dev** parameter an unique trait score is configured. For the neuroticism trait the mean for each agent can be set by the **neuroticism-trait-population**. 
![traitcorrel](corrtraits.png)

**Perception Thermometers**
Within this model the change in value prioritizations are induced by value-weighted experiences which can have be interactions with technology and social developments (Van de Poel, 2018). According to Schwartz's Value Theory however, the change in prioritization is limited and only occurs when experiencing life changing events (Sagiv, 2017). So to simulate impact of value-weighted experiences on changes in value prioritization and to prevent eruptive and invalidated behaviour, it is necessary to create this buffer between the environment and value prioritization systems. Perception thermometers function as these buffers as they absorb the impact of value-weighted experiences (e.g. social interaction and events) by increasing (positive weighted experiences) or decreasing (negatively weighted experiences) its temperature. Once the temperature of a value-related perception thermometer reaches 0 or 100 degrees celsius, the related value will respectively decrease or increase with the pre-set **value-change-para** parameter. The moment the prioritization of a value changes, the complete value system will be aligned according to condition one and two (respectively 'neighbouring value pairs' and 'antagonistic value pairs'). The temperature of the related perception thermometer will reset to the level of status quo (50 degrees celsius).

Combining the perception thermometer mechanism with the assumption that the impact of value-weighted experiences diminishes over time, the temperature of the perception thermometers always tend to return to the level of status quo (50 degree Celsius). This diminishing effect is dependent on the score for the openness-trait of individuals. The more open an individual tends to be, to more receptive it will be to new ideas/influences. So the tendency to return to the status quo of an individual is the product of the negative openness of an individual times the **ptc-rsq-modifier** parameter. 

All in All, only after continuous and one-sided impacts of value-weighted experiences, change in value prioritizations will occur for more information on the functioning of perception thermometers within this research). 
![](perception-thermometers.png)


**The interaction with technology**
The interaction with technology is understood as an event during which the acquisition of information and/or experiences due to the use technologies lead to the change in perceptions of individuals. During each tick only one events occurs that varies in three different dimensions: i) the values that are triggered by the event (i.e. event-orientation), ii) the impact of the event (event-impact), and iii) the magnitude of the event (i.e. event-magnitude). 

_Event Orientation_
An event can occur in four different event orientations. Each of these events stimulates (+) the perception thermometers of the values that are in one of the Schwartz's Value Circumplex quarter, while suppressing (-) the perception thermometers of the values at the opposite quarter (Sagiv, 2017). The table below shows for each of these event-orientations which perception thermometers are stimulated (+) and which are suppressed. The occurrence of the event-orientation is based on the probability settings of the following parameters: **%-conservation-event**, **%-self-transcendence-event**, **%-openness-to-change-event**, **%-self-enhancement-event**. Note that the sum of these probabilities should always equal 100, to let the model run correctly. 

![](Event-effects.png)

_Event Impact_
Although it is assumed that every individual experiences events, not every individual will adapts its perception thermometer. Only whenever the impact of the event exceeds the awareness-threshold of the individual, the perception thermometers will change increase/decrease with the impact of the event. The awareness-threshold of individuals is an linear scaled attributed that holds a value between the **Min-awareness-threshold** and the **Max-awareness-threshold** parameters. It is assumed that the higher the individual score for the _openness_ and _conscientiousness_ trait the lower the individual awareness-threshold.  The impact of the event is equal for each individual and is calibrated each tick using a exponential distributed random number of which the mean can be altered by using the **Event-mean-exponential-distribution** parameter.

_Event Magnitude_
The magnitude of the event can differ between individual-level and global-level. During an event with an magnitude on the _global-level_ every person experiences the same event (i.e. equal impact and equal orientation). On the contrary, for an event on the _individual-level_, every person generates its own event-impact and event-orientation. Whether the event-magnitude is on a individual-level or the global-level is determined by the probability **%global-event** parameter (A high setting will result on more global-events, while a lower setting will result in more individual events). This variation allows the adjust the globalisation and connectivity of the population (the more globalized and connected the population, the more often a global-event will occur).   
**Social development through Social Interaction**
Social development is conceptualized as an emergent effect of multiple social interactions between peoples. Within this model, these social interactions actions is understood as a process of social learning in which two individuals who have an intimate relationship (friendship) persuade each other to adopt their own particular vision on life (i.e. value prioritizations). During this process of social learning both individuals ones play the role of persuader and ones the role of recipient. Whenever the persuader is able to convince to recipient (Extraversion-trait of persuader > (100 - Agreeableness trait of recipient)), each of the perception thermometers of the recipient will change. The direction of change for each perception thermometer is dependent on the positive/negative difference in prioritization between the persuader and recipient (e.g. if the prioritzation of Self-Direction of the persuader > prioritization of Self-Direction of the recipient, the Self-Direction Perception Thermometer will increase). Whenever both individuals are not able to persuade each other, the possibility occurs of perception divergence (can be set by the **perception-divergence-no-consensus?** parameter. During a moment of perception divergence the perception thermometers of both individuals will move away from each other. The increase/decrease of the perception thermometers due to social interaction can be adjusted by the **ptc-neighbour-consensus** parameter. Once every tick, each of the agents has an social interaction with one of their friends. It is assummed that Agents have random friends, independently from their value system, which do not change over the course of the simulation. The number friends each agents has can be adjusted with the **#neighbour-friends** parameter.  

## HOW TO USE IT
The model can be executed by using the **setup** button in combination with the **go** button. Based on the description above, the input parameters can be adjusted to get a sense of the how the model works. To get back to original settings of the model, the **setup-default-settings** button can be used. 

**Monitors**
At the top the two monitors, _Trait Distribution Population_ and _Value Distribution Population_, show the distribution of the values prioritization and character traits for the total population with an interval of 5. 

The monitor in the middle on the left side, _Global Direction & Magnitude of change in Value Prioritization_, shows the increase/decrease of each of the value prioritizations on a population level compared at the situation at t = 0. So negative change of 2.5 points at t = 300 for the conformity value means that compared to the situation at t = 0 the prioritization of the conformity value is on average decreased with 2.5 points. 

The middle monitor on the right shows the impact of the event that occured during each tick. 

Lastly the monitors on the bottom visualizes the value prioritization, traits and perception thermometers of civilian 1. The idea of visualizing this cognitive archictecture on the individual level is to give the user a sense of how the change in prioritizations works. 

  

## THINGS TO NOTICE AND TRY

Important to note is that the goal of this model is to illustrate how dynamic value prioritizations can be modeled within agent-based social simulation. Tendencies on how the value prioritizations on a population level change, are highly dependent on the modelling assumptions (people with a high score on extraversion traits are more persuasive). Therefore, when drawing conslusions from change in value prioritization based on this model, it is recommend to keep this notion in mind. 

Having that said, it is interesting to explore the possibilities of the model by altering the odds of each of the event types, the initial value orientations of the population, and the settings of the impact of the event. Especially the longitudinal effect of events with a high impact are interesting to notice.

Moreover, it is interesting to experiment with the event magnitude by altering the **%-global-event** parameter. Note that when events only occur on the individual level, the diversity in the orientation of events, in combination with social interaction, diminishes the effect of events on value prioritization. While having global events a strong relation between change in value prioritizations and the event orientation is visible, due to the collective experience of similar events. 


## POSSIBLE APPLICATIONS AND EXTENSIONS OF THE MODEL


The intention of this model is to create an universal basis that can be adjusted/specified/extended for specific cases. When linking the value-prioritization to certain preferences in a certain action situation (e.g. transport, energy, health, economy), this model can be used to study the attitude of population groups. Moreover, this model can be combined with the field of Artificial Sociality to study the dynamics between individual and group dynamics. 

Possible extensions to model are numerous. Within the current version (1.0), the configuration of the friendly relationships, the distribution of events among, the types of events, the type of initial value orientations, consequences of social interaction on value systems are simplified. Extending upon this processes would be this model even more valuable. 



## CREDITS AND REFERENCES
Grimm, V., Berger, U., DeAngelis, D. L., Polhill, J. G., Giske, J. & Railsback, S. F. (2010). The odd protocol: a review and first update. Ecological modelling,221(23), 2760–2768

Heidari, S., Jensen, M. & Dignum, F. (2020).  Simulations with values.  In Advances in SocialSimulation, (pp. 201–215). Springer

McCrae, R. R. & Costa Jr, P. T. (2008). The five-factor theory of personality. In Handbook of personality: Theory and research, (pp. 159––181). The Guilford Press

Parks-Leduc, L., Feldman, G. & Bardi, A. (2015).  Personality traits and personal values: Ameta-analysis. Personality and Social Psychology Review,19(1), 3–29

Sagiv, L., Roccas, S., Cieciuch, J. & Schwartz, S. H. (2017). Personal values in human life. NatureHuman Behaviour,1(9), 630–639

Schwartz, S. H. (1994). Are there universal aspects in the structure and contents of human values? Journal of social issues,50(4), 19–45

Schwartz, S. H., Cieciuch, J., Vecchione, M., Davidov, E., Fischer, R., Beierlein, C., Ramos,A., Verkasalo, M., Lönnqvist, J.-E., Demirutku, K. et al. (2012). Refining the theory of basic individual values.Journal of personality and social psychology,103(4), 663

van de Poel, I. (2018). Design for value change.Ethics and Information Technology, (pp. 1–5)
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="individual-tracking" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-default-settings
setup</setup>
    <go>go</go>
    <timeLimit steps="520"/>
    <metric>impact-event</metric>
    <metric>event-type</metric>
    <metric>TRANSFORM-LIST! growth-individual ","</metric>
    <metric>TRANSFORM-LIST! personal-individual ","</metric>
    <metric>TRANSFORM-LIST! social-individual ","</metric>
    <metric>TRANSFORM-LIST! self-protection-individual ","</metric>
    <enumeratedValueSet variable="static-seed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-scenario">
      <value value="&quot;mixed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track-individual-agents">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="individual-tracking-growth" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-default-settings
setup</setup>
    <go>go</go>
    <timeLimit steps="520"/>
    <metric>impact-event</metric>
    <metric>event-type</metric>
    <metric>TRANSFORM-LIST! growth-individual ","</metric>
    <enumeratedValueSet variable="static-seed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-scenario">
      <value value="&quot;growth&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track-individual-agents">
      <value value="&quot;growth&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="individual-tracking-personal" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-default-settings
setup</setup>
    <go>go</go>
    <timeLimit steps="520"/>
    <metric>impact-event</metric>
    <metric>event-type</metric>
    <metric>TRANSFORM-LIST! personal-individual ","</metric>
    <enumeratedValueSet variable="static-seed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-scenario">
      <value value="&quot;personal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track-individual-agents">
      <value value="&quot;personal&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="individual-tracking-social" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-default-settings
setup</setup>
    <go>go</go>
    <timeLimit steps="520"/>
    <metric>impact-event</metric>
    <metric>impact-type</metric>
    <metric>TRANSFORM-LIST! social-individual ","</metric>
    <enumeratedValueSet variable="static-seed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-scenario">
      <value value="&quot;social&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track-individual-agents">
      <value value="&quot;social&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="individual-tracking-self-protection" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-default-settings
setup</setup>
    <go>go</go>
    <timeLimit steps="520"/>
    <metric>impact-event</metric>
    <metric>event-type</metric>
    <metric>TRANSFORM-LIST! self-protection-individual ","</metric>
    <enumeratedValueSet variable="static-seed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-scenario">
      <value value="&quot;self-protection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="track-individual-agents">
      <value value="&quot;self-protection&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-default-settings
setup</setup>
    <go>go</go>
    <metric>event-impact</metric>
    <metric>event-type</metric>
    <metric>value-change-list-reporter</metric>
    <metric>mean [importance-hedonism-value] of civilians</metric>
    <metric>mean [importance-stimulation-value] of civilians</metric>
    <metric>mean [importance-self-direction-value] of civilians</metric>
    <metric>mean [importance-universalism-value] of civilians</metric>
    <metric>mean [importance-benevolence-value] of civilians</metric>
    <metric>mean [importance-conformity-value] of civilians</metric>
    <metric>mean [importance-tradition-value] of civilians</metric>
    <metric>mean [importance-security-value] of civilians</metric>
    <metric>mean [importance-power-value] of civilians</metric>
    <metric>mean [importance-achievement-value] of civilians</metric>
  </experiment>
  <experiment name="value-plots" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-default-settings
setup</setup>
    <go>go</go>
    <timeLimit steps="1"/>
    <metric>TRANSFORM-LIST! value-system-reporter ","</metric>
    <enumeratedValueSet variable="population-scenario">
      <value value="&quot;mixed&quot;"/>
      <value value="&quot;personal&quot;"/>
      <value value="&quot;growth&quot;"/>
      <value value="&quot;self-protection&quot;"/>
      <value value="&quot;social&quot;"/>
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
