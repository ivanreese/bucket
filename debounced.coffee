Take [], ()->

  waiting = new Map()

  run = (fn)-> ()->
    args = waiting.get fn
    waiting.delete fn
    fn ...args

  Make.async "Debounced", Debounced = (...[delay], fn)-> (...args)->
    unless waiting.has fn
      if delay?
        setTimeout run(fn), delay
      else
        queueMicrotask run fn
    waiting.set fn, args # save the most recently provided args
    null

  Debounced.raf = (fn)-> (...args)->
    unless waiting.has fn
      requestAnimationFrame run fn
    waiting.set fn, args # save the most recently provided args
    null
