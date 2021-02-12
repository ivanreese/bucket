# Monkey Patch
# The JS standard library leaves a lot to be desired, so let's carefully (see bottom of file)
# modify the built-in classes to add a few helpful methods.

do ()->
  monkeyPatches =

    Array:

      # Sorting
      numericSortAscending: (a, b)-> a - b
      numericSortDescending: (a, b)-> b - a
      sortNumericAscending: (arr)-> arr.sort Array.numericSortAscending
      sortNumericDescending: (arr)-> arr.sort Array.numericSortDescending

      # Misc

      clone: (arr)->
        unless arr instanceof Array
          Object.clone arr
        else
          for v, i in arr
            if not v?
              v
            else if v.id? # This is a reference to another scene object, so don't clone it
              v
            else if v instanceof Array
              Array.clone v
            else if v instanceof Object
              Object.clone v
            else
              v

      empty: (arr)->
        not arr? or arr.length is 0

      equal: (a, b)->
        return true if Object.is a, b
        return false unless (a? and b?) and (a instanceof Array and b instanceof Array) and (a.length is b.length)
        for ai, i in a
          bi = b[i]
          if Object.is ai, bi
            continue
          else if ai instanceof Array and bi instanceof Array
            continue if Array.equal ai, bi
          else if ai instanceof Object and bi instanceof Object
            continue if Object.equal ai, bi
          return false
        return true

      last: (arr)->
        arr[arr.length-1]

      pull: (arr, elms)->
        return unless arr? and elms?
        elms = [elms] unless elms instanceof Array
        for elm in elms
          while (i = arr.indexOf elm) > -1
            arr.splice i, 1
        arr

      search: (arr, key)->
        for v in arr
          if v instanceof Array
            return true if Array.search v, key
          else if v instanceof Object
            return true if Object.search v, key
        return false

      unique: (elements)->
        Array.from new Set [].concat elements


    Function:
      exists: (e)-> e?

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

      clip: (v, min = 0, max = 1)-> Math.min max, Math.max min, v
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

      roundTo: (input, precision)->
        # Using the reciprocal avoids floating point errors. Eg: 3/10 is fine, but 3*0.1 is wrong.
        p = 1 / precision
        Math.round(input * p) / p


    Object:

      by: (key, arr)->
        out = {}
        out[obj.id] = obj for obj in arr
        return out

      clone: (obj)->
        if obj instanceof Array
          Array.clone obj
        else if obj instanceof Object
          out = {}
          for k, v of obj
            out[k] = if not v?
              v
            else if v.id? # This is a reference to another scene object, so don't clone it
              v
            else if v instanceof Function
              v
            else if v instanceof Array
              Array.clone v
            else if v instanceof Object
              Object.clone v
            else
              v
          out
        else
          throw "Can't clone non-object"

      equal: (a, b)->
        return true if Object.is a, b
        return false unless (a? and b?) and ({}.constructor is a.constructor is b.constructor)
        return false unless Object.keys(a).length is Object.keys(b).length
        for k, av of a
          bv = b[k]
          if Object.is av, bv
            continue
          else if av instanceof Array and bv instanceof Array
            continue if Array.equal av, bv
          else if av instanceof Object and bv instanceof Object
            continue if Object.equal av, bv
          return false
        return true


      isObject: (obj)->
        "[object Object]" is Object.prototype.toString.call obj


      merge: (objs...)->
        out = {}
        for obj in objs
          for k, v of obj
            if v instanceof Function
              out[k] = v
            else if v instanceof Object
              out[k] = Object.clone v
            else
              out[k] = v
        out

      rmerge: (objs...)->
        Object.merge objs.reverse()...

      search: (obj, key)->
        return true if obj[key]?
        for k, v of obj
          if v instanceof Array
            return true if Array.search v, key
          else if v instanceof Object
            return true if Object.search v, key
        return false


  # Init

  for className, classPatches of monkeyPatches
    globalclass = window[className]
    for key, value of classPatches
      if globalclass[key]?
        console.log "Can't monkey patch #{className}.#{key} because it already exists."
      else
        globalclass[key] = value
