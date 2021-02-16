Take [], ()->

  fns = new Map()

  run = (fn)-> ()->
    fns[fn] = false
    fn()

  Debounced = (delay, fn)-> ()->
    fn = delay unless fn? # Delay might not be given
    unless fns[fn]
      fns[fn] = true
      if delay is fn # Delay was not given
        requestAnimationFrame run fn
      else
        setTimeout run(fn), delay

  Make "Debounced", Debounced
