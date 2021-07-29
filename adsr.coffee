# ADSR
# This gives your function an "attack" phase and a "release" phase
# (borrowing terminology from ADSR on synthesizers).
# The attack phase is a debounce — your function will run just once after the attack phase ends,
# no matter how many times it's called until then.
# When the function runs, it'll use the args from the most recent time it was called.
# The release is a throttle — if your function is called during the release phase,
# then after the release phase ends the attack phase will start over again.
# This is useful if you want a function that will run shortly after it's called (good for fast reactions)
# but doesn't run again until a while later (good for reducing strain).
# Attack and release are specified in ms, and are optional.
# If you pass a time of 0 ms for either the attack, release, or both, the phase will last until the next microtask.
# If you pass a time less than 5 ms, the phase will last until the next animation frame.
# It's idiomatic to pass a time of 1 ms if you want the next frame.
# We also keep a count of how many functions are currently waiting, and support adding watchers
# that will run a callback when the count changes, just in case you want to (for example)
# wait for them all to finish before quitting / closing, or monitor their performance.

Take [], ()->

  active = new Map()
  watchers = []

  Make.async "ADSR", ADSR = (...[attack = 0, release = 0], fn)-> (...args)->
    if not active.has fn
      afterDelay attack, afterAttack fn, attack, release
      ADSR.count++
      updateWatchers()
    active.set fn, {args} # Always use the most recent args

  ADSR.count = 0

  ADSR.watcher = (watcher)->
    watchers.push watcher

  afterAttack = (fn, attack, release)-> ()->
    {args} = active.get fn
    active.set fn, {}
    fn ...args
    afterDelay release, afterRelease fn, attack, release

  afterRelease = (fn, attack, release)-> ()->
    {args} = active.get fn
    if args
      afterDelay attack, afterAttack fn, attack, release
    else
      active.delete fn
      ADSR.count--
      updateWatchers()

  afterDelay = (delay = 0, cb)->
    if delay is 0
      queueMicrotask cb
    else if delay < 5
      requestAnimationFrame cb
    else
      setTimeout cb, delay

  updateWatchers = ()->
    watcher ADSR.count for watcher in watchers
    null
