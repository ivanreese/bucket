Take [], ()->
  state = "Default"
  transitions = "*": "*": []


  transition = (to)->
    transitionsToRun = []
    transitionsToRun = transitionsToRun.concat transitions[state][to]  if transitions[state]?[to]?
    transitionsToRun = transitionsToRun.concat transitions[state]["*"] if transitions[state]?
    transitionsToRun = transitionsToRun.concat transitions["*"][to]    if transitions["*"][to]?
    transitionsToRun = transitionsToRun.concat transitions["*"]["*"]
    fn state, to for fn in transitionsToRun
    state = to


  addTransition = (from, to, cb)->
    transitions[from] ?= "*": []
    transitions[from][to] ?= []
    transitions[from][to].push cb


  Make "StateMachine", StateMachine = (a, b, c)->
    return state                            unless a?  # 0 arity
    return transition a                     unless b?  # 1 arity
    throw Error "Invalid StateMachine Call" unless c?  # 2 arity
    addTransition a, b, c                              # 3 arity
