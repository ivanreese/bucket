Take [], ()->

  waiting = new Map()

  run = (fn)-> ()->
    args = waiting.get fn
    waiting.delete fn
    fn ...args

  Make "Debounced", Debounced = (delay, fn)-> (...args)->
    fn = delay unless fn? # Delay might not be given
    unless waiting.has fn
      if delay is fn # Delay was not given
        queueMicrotask run fn
      else
        setTimeout run(fn), delay
    waiting.set fn, args # save the most recently provided args
    null
