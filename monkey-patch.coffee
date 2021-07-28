# Monkey Patch
# The JS standard library leaves a lot to be desired, so let's carefully (see bottom of file)
# modify the built-in classes to add a few helpful methods.

do ()->
  monkeyPatches =

    Array:
      type: (v)-> v instanceof Array

      # Sorting
      numericSortAscending: (a, b)-> a - b
      numericSortDescending: (a, b)-> b - a
      sortAlphabetic: (arr)-> arr.sort Array.alphabeticSort ?= new Intl.Collator('en').compare
      sortNumericAscending: (arr)-> arr.sort Array.numericSortAscending
      sortNumericDescending: (arr)-> arr.sort Array.numericSortDescending

      # Accessing
      first: (arr)-> arr[0]
      second: (arr)-> arr[1]
      last: (arr)-> arr[arr.length-1]
      rest: (arr)-> arr[1...]
      butLast: (arr)-> arr[...-1]

      # Misc

      clone: (arr)->
        arr.map Function.clone

      empty: (arr)->
        not arr? or arr.length is 0

      equal: (a, b)->
        return true if Object.is a, b
        return false unless Array.type(a) and Array.type(b) and a.length is b.length
        for ai, i in a
          bi = b[i]
          if Function.equal ai, bi
            continue
          else
            return false
        return true

      mapToObject: (arr, fn = Function.identity)->
        o = {}
        o[k] = fn k for k in arr
        o

      pull: (arr, elms)->
        return unless arr? and elms?
        elms = [elms] unless Array.type elms
        for elm in elms
          while (i = arr.indexOf elm) > -1
            arr.splice i, 1
        arr

      search: (arr, key)->
        for v in arr
          if Array.type v
            return true if Array.search v, key
          else if Object.type v
            return true if Object.search v, key
        return false

      shuffle: (arr)->
        newArr = []
        for item, i in arr
          newArr.splice Math.randInt(0, newArr.length), 0, item
        return newArr

      unique: (elements)->
        Array.from new Set [].concat elements


    Function:
      type: (v)-> v instanceof Function
      identity: (v)-> v

      exists: (e)-> e?
      notExists: (e)-> !e?
      is: (a, b)-> a is b
      isnt: (a, b)-> a isnt b
      equal: (a, b)->
        if Object.is a, b
          true
        else if Array.type(a) and Array.type(b)
          true if Array.equal a, b
        else if Object.type(a) and Object.type(b)
          true if Object.equal a, b
        else
          false
      equivalent: (a, b)-> `a == b` or Function.equal a, b # Like equal, but also equates null & undefined, -0 & 0, etc
      notEqual: (a, b)-> !Function.equal a, b
      notEquivalent: (a, b)-> !Function.equivalent a, b

      clone: (v)->
        if not v?
          v
        else if Function.type v
          throw new Error "If you need to clone functions, use a custom cloner"
        else if Promise.type v
          throw new Error "If you need to clone promises, use a custom cloner"
        else if Array.type v
          Array.clone v
        else if Object.type v
          Object.clone v
        else
          v


    Math:

      TAU: Math.PI * 2

      zero: (v)-> Math.EPSILON > Math.abs v
      nonzero: (v)-> not Math.zero v

      add: (a, b)-> a + b
      div: (a, b)-> a / b
      mod: (a, b)-> a % b
      mul: (a, b)-> a * b
      sub: (a, b)-> a - b

      avg: (a, b)-> (a + b)/2

      clip: (v, ...[min = 0], max = 1)-> Math.min max, Math.max min, v
      sat: (v) -> Math.clip v

      lerpN: (input, outputMin = 0, outputMax = 1, clip = false)->
        input *= outputMax - outputMin
        input += outputMin
        input = Math.clip input, outputMin, outputMax if clip
        return input

      lerp: (input, inputMin = 0, inputMax = 1, outputMin = 0, outputMax = 1, clip = true)->
        return outputMin if inputMin is inputMax # Avoids a divide by zero
        [inputMin, inputMax, outputMin, outputMax] = [inputMax, inputMin, outputMax, outputMin] if inputMin > inputMax
        input = Math.clip input, inputMin, inputMax if clip
        input -= inputMin
        input /= inputMax - inputMin
        return Math.lerpN input, outputMin, outputMax, false

      rand: (min = -1, max = 1)-> Math.lerpN Math.random(), min, max
      randInt: (min, max)-> Math.round Math.rand min, max

      roundTo: (input, precision)->
        # Using the reciprocal avoids floating point errors. Eg: 3/10 is fine, but 3*0.1 is wrong.
        p = 1 / precision
        Math.round(input * p) / p


    Object:
      type: (v)-> "[object Object]" is Object.prototype.toString.call v

      # This should probably be a function on Array, as a mirror of Object.keys / Object.values.
      # In general, functions that take an array go on Array, even if they return a different type.
      by: (k, arr)-> # Object.by "name", [{name:"a"}, {name:"b"}] => {a:{name:"a"}, b:{name:"b"}}
        o = {}
        o[obj[k]] = obj for obj in arr
        return o

      clone: (obj)->
        Object.mapValues obj, Function.clone

      count: (obj)->
        Object.keys(obj).length

      equal: (a, b)->
        return true if Object.is a, b
        return false unless (a? and b?) and ({}.constructor is a.constructor is b.constructor)
        return false unless Object.keys(a).length is Object.keys(b).length
        for k, av of a
          bv = b[k]
          if Function.equal av, bv
            continue
          else
            return false
        return true

      mapKeys: (obj, fn = Function.identity)->
        o = {}
        o[k] = fn k for k of obj
        o

      mapValues: (obj, fn = Function.identity)->
        o = {}
        o[k] = fn v for k, v of obj
        o

      merge: (objs...)->
        out = {}
        for obj in objs when obj?
          for k, v of obj
            # DO NOT add any additional logic for merging other types (like arrays),
            # or existing apps will break (Hyperzine, Hest, etc.)
            # If you want to deep merge other types, write a custom merge function.
            out[k] = if Object.type v
              Object.merge out[k], v
            else
              v
        out

      rmerge: (objs...)->
        Object.merge objs.reverse()...

      search: (obj, key)->
        return true if obj[key]?
        for k, v of obj
          if Array.type v
            return true if Array.search v, key
          else if Object.type v
            return true if Object.search v, key
        return false

      subtractKeys: (a, b)->
        o = Object.mapKeys a # shallow clone
        delete o[k] for k of b
        o


    Promise:
      type: (v)-> v instanceof Promise

      timeout: (t)-> new Promise (resolve)-> setTimeout resolve, t


    String:
      type: (v)-> "string" is typeof v

      # https://stackoverflow.com/a/52171480/313576, public domain
      hash: (str, seed = 0)->
        return 0 unless str?
        h1 = 0xdeadbeef ^ seed
        h2 = 0x41c6ce57 ^ seed
        for c in str
          ch = c.charCodeAt 0
          h1 = Math.imul h1 ^ ch, 2654435761
          h2 = Math.imul h2 ^ ch, 1597334677
        h1 = Math.imul(h1 ^ (h1>>>16), 2246822507) ^ Math.imul(h2 ^ (h2>>>13), 3266489909)
        h2 = Math.imul(h2 ^ (h2>>>16), 2246822507) ^ Math.imul(h1 ^ (h1>>>13), 3266489909)
        return 4294967296 * (2097151 & h2) + (h1>>>0)

      pluralize: (count, string, suffix = "s")->
        suffix = "" if count is 1
        (string + suffix).replace("%%", count)

      toKebabCase: (v)->
        v.replace(/([A-Z])/g,"-$1").toLowerCase()


  # Init

  for className, classPatches of monkeyPatches
    globalclass = globalThis[className]
    for key, value of classPatches
      if globalclass[key]?
        console.log "Can't monkey patch #{className}.#{key} because it already exists."
      else
        globalclass[key] = value
