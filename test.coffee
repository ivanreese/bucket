Tests = Test = null

do ()->
  context = null

  Tests = (name, test)->
    context = ()-> console.group "%c#{name}", "color: red"; context = null
    test()
    console.groupEnd()
    context = null

  Test = (name, ...stuff)->

    # If we've been passed any functions, run them and capture the return values.
    for thing, i in stuff when Function.type thing
      stuff[i] = thing()

    # If there's only one thing in stuff, just compare it with true
    if stuff.length is 1
      stuff.unshift true

    # Now, all things in stuff must all be equivalent. Or else.
    # (This test framework is super casual, so we just check each neighbouring pair)
    for thing, i in Array.butLast stuff
      unless Function.equivalent thing, stuff[i+1]
        context?()
        console.group "%c#{name}", "font-weight:normal;"
        console.log "this:", thing
        console.log "isnt:", stuff[i+1]
        console.groupEnd()
