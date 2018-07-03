$oneolcom

*Primay sets
SETS
   n(*)                                                                         'region or node'
   t(*)                                                                         'time interval of the year - can be day, week, month or quater'
   b(*)                                                                         'demand block'
   j(*)                                                                         'hydro junction'
   s(*)                                                                         'hydro inflow sequences'
   g(*)                                                                         'generation plant'
   f(*)                                                                         'fuel types: coal, diesel, gas, lignite, hydro, wind, geo'

   ls(*)                                                                        'loss load tranches'
   vs(*)                                                                        'Stored energy value segment'

   i(*)                                                                         'Pre-set number of iterations'

;

Alias (n, fn, tn)    ,  (j, j1, j2, fj, tj)  ,  (g, g1, g2)
      (vs, vs1, vs2) ,  (t, t1, t2, t3)      ,  (s,s1,s2)
;

SETS
* model sets
   ti(t)                                                                        'current solving time interval'
   seq(s)                                                                       'current applied hydro sequence'
;

*Secondary sets
SETS
   sea(j)                                                                       'junction represent SEA'
   reservoir(j)                                                                 'reservoir or lake that can store water'
   hydroarc(fj,tj)                                                              'definition of hydro arc'
   plantnode(g,n)                                                               'location of generation plant'
   plantfuel(g,f)                                                               'fuel used for plant(g)'
   hydrodef(g,fj,tj)                                                            'hydro generation station definition of inflow from and outflow to'

   fixed(g)                                                                     'generation plants with profiled fixed outputs'
   thermal(g)                                                                   'thermal plants using fuel to generate'
   hydro(g)                                                                     'hydro generation station'

   validcuts(t,i)                                                               'Flag the valid cuts to be applied to calculate expected future cost'
;



PARAMETERS
* Input
   demand(t,b,n)                                                                'average demand of block bl in interval t - MW'
   blockhour(t,b)                                                               'number of hours in block bl - hours'

   heatrate(g)                                                                  'heat rate of fuel(f) applied to generation plant(ge) - GJ/MWh'
   opercost(g)                                                                  'operation and maitemance cost $/MWh'
   fuelcost(t,f)                                                                'cost of fuel in interval t - $/GJ'
   co2cost(t)                                                                   'CO2 cost $/ton'
   emissionrate(f)                                                              'ton CO2/PJ <--> 1(PJ)  = 1e6(GJ)'

   fixedoutput(t,b,g)                                                           'Fixed generation output applied to fixed generation plant - MW'
   plantcapacity(t,b,g)                                                         'Capacity of generation plant(g) during timet) and block(b) - MW'

   conversionfactor(g)                                                          'Specific power conversion factor MW/cumec'
   maxspillflow(g)                                                              'Maximum flow cumec(s) through spillway at a hydro station'

   txcapacity(fn,tn)                                                            'Transmission capacity - MW'
   inflow(s,t,j)                                                                'Infows are defined in cumec(s) for locations (hydro junctions) in the system'

   voll_mw(t,b,n,ls)                                                            'Maximum shortage penalty quantity for loss load tranche ls (MW)'
   voll_nzd(t,b,n,ls)                                                           'Shortage penalty cost applied for loss load tranche ls ($/MWh)'

   minflow(fj,tj)                                                               'Min flow requirement on flow arc between two hydro junctions'
   maxflow(fj,tj)                                                               'Max flow requirement on flow arc between two hydro junctions'

   penaltycost                                                                  'Penalty cost applied to min flow, max flow, spill way and fixed generation violation'

   storagecapacity(j)                                                           'Storage capacity (m3) at each reservoir'
   initialstorage(j)                                                            'Initial storage (m3) at each reservoir'

* Calculated input
   srmc(t,g)                                                                    'Pre-calculated short run marginal cost for a thermal plant - $/MWh'
   startstorage(s,t,j)                                                          'Pre-calculated storage level at the start of time interval(t) at reservoir(j)'
   reservoirfactor(j)                                                           'Specific power factor for each reservoir'

   watersegmentgwh(t,vs)                                                        'End storage segments in GWh'
   waternzdpermwh(t,vs)                                                         'Value of end storage segments in $/MWh'

   slopes(t,j,i)                                                                'Slopes of cut i'
   intercepts(t,i)                                                               'Intercept of cut i'

;

SCALARS
   lastinterval                                                                 'Flag 1 if the currently solved interval is the last interval - 0 otherwise' /0/

VARIABLES
   COST                                                                         'Expected system cost'
;


POSITIVE VARIABLES
* Decision variables
   GENERATIONCOST(s,t,b)                                                        'Generation cost by demand block '
   SHORTAGECOST(s,t,b)                                                          'Shortage cost by demand block '
   VIOLATIONCOST(s,t,b)                                                         'Constraint violation cost by demand block'
   FUTURECOST(s,t)                                                              'Expected minimum furture cost and the and of time(t)'

   TRANSMISSIONFLOW(s,t,b,fn,tn)                                                'Energy flow on transmision branch - MW'
   SHORTAGE(s,t,b,n,ls)                                                         'Loss load allocated to each loss load tranche - MW'
   GENERATION(s,t,b,g)                                                          'Cleared generation @ plant(g) for time(t), block(b) of hydro sequence(s)'

   FLOWTHROUGHTURBINE(s,t,b,g)                                                  'Hydro flow cumec(s) through generation turnbines of hydro plant (g)'
   FLOWTHROUGHSPILLWAY(s,t,b,g)                                                 'Hydro flow cumec(s) through spillway of hydro plant (g)'
   FLOWONHYDROARC(s,t,b,fj,tj)                                                  'Hydro flow release on hydro arc between two hydro junctions - cumec(s)'

   ENDSTORAGE(s,t,j)                                                            'Storage level (m3) at the end of time interval (t) at reservoir (j)'
   ENDSTORAGESEGMENTGWH(s,t,vs)                                                 'Segment storage (GWh) at the end of time interval (t)'

* Slack variables
   SPILLWAYVIOLATION(s,t,b,g)                                                   'Violation of spillway limit - cumec(s) '
   MAXARCFLOWVIOLATION(s,t,b,fj,tj)                                             'Violation of max flow on hydro arc - cumec(s) '
   MINARCFLOWVIOLATION(s,t,b,fj,tj)                                             'Violation of min flow on hydro arc - cumec(s) '
;


EQUATIONS
   ObjectiveFunction                                                            'Objective function'
   ExpectedFutureCostForward(s,t,i)                                             'Expected minimum future cost calculated based on saved cuts'
   ExpectedFutureCostBackward(s,t,i)                                            'Expected minimum future cost calculated based on added cut'

   EnergyDemandSupplyBalance(s,t,b,n)                                           'Total Energy Supply to a node (region) equal to Demand'

   GenerationCapacityConstraint(s,t,b,g)                                        'Generation output is limited by capacity'
   HydroGenerationCumecsToMWConversion(s,t,b,g)                                 'Conversion hydro flow(cumecs) through turbines to generation output (MW)'
   HydroGenerationSpillMaxConstraint(s,t,b,g)                                   'Maximum spilled flow (cumecs)'

   FlowInEqualFlowOutConstraint(s,t,j)                                          'Total Hydro flow in should be equal to hydro flow out off a hydro junction'
   FlowInEqualFlowOutJunctionConstraint(s,t,j)                                  'Total Hydro flow in should be equal to hydro flow out off a hydro junction'
   FlowInEqualFlowOutReservoirConstraint(s,t,j)                                 'Total Hydro flow in should be equal to hydro flow out off a hydro reservoir'

   MaxFlowOnArcConstraint(s,t,b,fj,tj)                                          'Maximum hydro arc flow constraint'
   MinFlowOnArcConstraint(s,t,b,fj,tj)                                          'Minimum hydro arc flow constraint'

   EndStorageTotalGWhCalculation(s,t)                                           'Calculate end storage total GWh'
   EndStorageSegmentGWhCalculation(s,t)                                         'Allocate end storage to segment'

;

* Objective function to minimize total cost
ObjectiveFunction..
  COST
=e=
  Sum[ (seq,ti,b,g) $ thermal(g), GENERATION(seq,ti,b,g)                        !! Thermal generation cost
                                * srmc(ti,g) * blockhour(ti,b) ]
+ Sum[ (seq,ti,b,n,ls), SHORTAGE(seq,ti,b,n,ls)                                 !! Shortage cost
                      * voll_nzd(ti,b,n,ls) * blockhour(ti,b) ]
+ Sum[ (seq,ti), FUTURECOST(seq,ti) ] $ (lastinterval = 0)                      !! Expected furure cost based on saved cuts

- Sum[ (seq,ti,vs) $ waternzdpermwh(ti,vs), ENDSTORAGESEGMENTGWH(seq,ti,vs)     !! Storage value at the end of simulation time zone
                                          * waternzdpermwh(ti,vs)
     ] $ (lastinterval = 1)
+ Sum[ (seq,ti,b,g) $ hydro(g), SPILLWAYVIOLATION(seq,ti,b,g)                   !! Spillway violation cost
                              * blockhour(ti,b) * penaltycost ]
+ Sum[ (seq,ti,b,fj,tj) $ hydroarc(fj,tj), MAXARCFLOWVIOLATION(seq,ti,b,fj,tj)  !! Max arc flow violation cost
                                         * blockhour(ti,b) * penaltycost ]
+ Sum[ (seq,ti,b,fj,tj) $ hydroarc(fj,tj), MINARCFLOWVIOLATION(seq,ti,b,fj,tj)  !! Min arc flow violation cost
                                         * blockhour(ti,b) * penaltycost ]
  ;


* Future cost is estimated baed on saved cuts
ExpectedFutureCostForward(seq,ti,i)
  $ { validcuts(ti,i) and (lastinterval = 0) }..
  FUTURECOST(seq,ti)
=g=
  Sum[ reservoir(j), slopes(ti,j,i) * ENDSTORAGE(seq,ti,j) ] + intercepts(ti,i)
  ;

* Supply Demand Balance
EnergyDemandSupplyBalance(seq,ti,b,n)..
  Sum[ g  $  plantnode(g,n) , GENERATION(seq,ti,b,g) ]
+ Sum[ fn $ txcapacity(fn,n), TRANSMISSIONFLOW(seq,ti,b,fn,n)   ]
- Sum[ tn $ txcapacity(n,tn), TRANSMISSIONFLOW(seq,ti,b,n,tn)   ]
+ Sum[ ls                   , SHORTAGE(seq,ti,b,n,ls)           ]
=e=
  demand(ti,b,n)
  ;


* Generation Constraint
GenerationCapacityConstraint(seq,ti,b,g) $ { thermal(g) or hydro(g) }..
  GENERATION(seq,ti,b,g) =l= plantcapacity(ti,b,g)
  ;

HydroGenerationCumecsToMWConversion(seq,ti,b,g) $ hydro(g)..
  GENERATION(seq,ti,b,g)
=e=
  FLOWTHROUGHTURBINE(seq,ti,b,g) * conversionfactor(g)
  ;

HydroGenerationSpillMaxConstraint(seq,ti,b,g) $ hydro(g)..
  FLOWTHROUGHSPILLWAY(seq,ti,b,g) - SPILLWAYVIOLATION(seq,ti,b,g)
=l=
  maxspillflow(g)
  ;


* Hydro arc/flow constraints
MaxFlowOnArcConstraint(seq,ti,b,fj,tj)
  $ {hydroarc(fj,tj) and maxflow(fj,tj)}..
  FLOWONHYDROARC(seq,ti,b,fj,tj) - MAXARCFLOWVIOLATION(seq,ti,b,fj,tj)          !! Flow on a hysro arc may have maximum limit
=l=
  maxflow(fj,tj)
 ;

MinFlowOnArcConstraint(seq,ti,b,fj,tj)
  $ {hydroarc(fj,tj) and minflow(fj,tj)}..
  FLOWONHYDROARC(seq,ti,b,fj,tj) + MINARCFLOWVIOLATION(seq,ti,b,fj,tj)          !! Flow on a hysro arc may have mimimum requirement
=g=
  minflow(fj,tj)
  ;

FlowInEqualFlowOutJunctionConstraint(seq,ti,j)
  $ {not (reservoir(j) or sea(j))}..
  Sum[ (b,tj) $ hydroarc(j,tj),
       FLOWONHYDROARC(seq,ti,b,j,tj)   * blockhour(ti,b) * 3600 ]               !! Hydro flow out of a junction into a hydro arc
- Sum[ (b,fj) $ hydroarc(fj,j),
       FLOWONHYDROARC(seq,ti,b,fj,j)   * blockhour(ti,b) * 3600 ]               !! Hydro flow into a junction from a hydro arc
+ Sum[ (b,g,tj) $ hydrodef(g,j,tj),
       FLOWTHROUGHTURBINE(seq,ti,b,g)  * blockhour(ti,b) * 3600 ]               !! Hydro flow out of a junction into a hydro station
- Sum[ (b,g,fj) $ hydrodef(g,fj,j),
       FLOWTHROUGHTURBINE(seq,ti,b,g)  * blockhour(ti,b) * 3600 ]               !! Hydro flow into a junction from a hydro station
+ Sum[ (b,g,tj) $ hydrodef(g,j,tj),
       FLOWTHROUGHSPILLWAY(seq,ti,b,g) * blockhour(ti,b) * 3600 ]               !! Hydro flow out of a junction into a hydro station spillway
- Sum[ (b,g,fj) $ hydrodef(g,fj,j),
       FLOWTHROUGHSPILLWAY(seq,ti,b,g) * blockhour(ti,b) * 3600 ]               !! Hydro flow into a junction from a hydro station spillway
=e=
  Sum[ b, inflow(seq,ti,j) * blockhour(ti,b) * 3600 ]
  ;

FlowInEqualFlowOutReservoirConstraint(seq,ti,j) $ reservoir(j)..
  Sum[ (b,tj) $ hydroarc(j,tj),
       FLOWONHYDROARC(seq,ti,b,j,tj)   * blockhour(ti,b) * 3600 ]               !! Hydro flow out of a junction into a hydro arc
- Sum[ (b,fj) $ hydroarc(fj,j),
       FLOWONHYDROARC(seq,ti,b,fj,j)   * blockhour(ti,b) * 3600 ]               !! Hydro flow into a junction from a hydro arc
+ Sum[ (b,g,tj) $ hydrodef(g,j,tj),
       FLOWTHROUGHTURBINE(seq,ti,b,g)  * blockhour(ti,b) * 3600 ]               !! Hydro flow out of a junction into a hydro station
- Sum[ (b,g,fj) $ hydrodef(g,fj,j),
       FLOWTHROUGHTURBINE(seq,ti,b,g)  * blockhour(ti,b) * 3600 ]               !! Hydro flow into a junction from a hydro station
+ Sum[ (b,g,tj) $ hydrodef(g,j,tj),
       FLOWTHROUGHSPILLWAY(seq,ti,b,g) * blockhour(ti,b) * 3600 ]               !! Hydro flow out of a junction into a hydro station spillway
- Sum[ (b,g,fj) $ hydrodef(g,fj,j),
       FLOWTHROUGHSPILLWAY(seq,ti,b,g) * blockhour(ti,b) * 3600 ]               !! Hydro flow into a junction from a hydro station spillway
+  ENDSTORAGE(seq,ti,j)
=e=
  startstorage(seq,ti,j)
+ Sum[ b, inflow(seq,ti,j) * blockhour(ti,b) * 3600 ]
  ;

* Storage constraints
EndStorageTotalGWhCalculation(seq,ti) $ (lastinterval = 1)..
  Sum[ vs, ENDSTORAGESEGMENTGWH(seq,ti,vs) ]
=e=
  Sum[ reservoir(j), ENDSTORAGE(seq,ti,j) * reservoirfactor(j) / 3.6e6 ];



Model HydroThermalModel /
* Objective function
   ObjectiveFunction
* Cost Calculation
   ExpectedFutureCostForward
* Supply Demand
   EnergyDemandSupplyBalance
* Generation Constraint
   GenerationCapacityConstraint
   HydroGenerationCumecsToMWConversion
   HydroGenerationSpillMaxConstraint
* Hydro arc/flow constraints
   MaxFlowOnArcConstraint
   MinFlowOnArcConstraint
   FlowInEqualFlowOutJunctionConstraint
   FlowInEqualFlowOutReservoirConstraint
* Storage constraint
   EndStorageTotalGWhCalculation
   / ;
