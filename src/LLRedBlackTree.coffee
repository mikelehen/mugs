###*
# @author Mads Hartmann Jensen (2011, mads379@gmail.com)
###
LLRBNode = (() ->

  ###
  # Immutable implementation of Left Leaning Red Black Tree as
  # described in this paper: http://www.cs.princeton.edu/~rs/talks/LLRB/LLRB.pdf
  #
  # Invartiant 1: No red node has a red child
  # Invartiant 2: Every leaf path has the same number of black nodes
  # Invartiant 3: Only the left child can be red (left leaning)
  ###

  ###
  # Public interface
  ###

  F = (key,value,color,left,right) ->
    this.key   = key
    this.value = value
    this.color = if color? then color else RED
    this.left  = if left?  then left  else new None()
    this.right = if right? then right else new None()
    this.comparator = standard_comparator
    return this

  F.prototype.copy = (key,value,color,left,right) ->
    new LLRBNode(
      if key?   && key    != _ then key   else this.key,
      if value? && value  != _ then value else this.value,
      if color? && color  != _ then color else this.color,
      if left?  && left   != _ then left  else this.left,
      if right? && right  != _ then right else this.right)

  F.prototype.insert       = (key,item) -> insert(new Some(this),key,item).copy(_,_,BLACK,_,_)
  F.prototype.remove       = (key)      -> remove(new Some(this),key).get().copy(_,_,BLACK,_,_)
  F.prototype.removeMinKey = ()         -> removeMin(new Some(this)).get().copy(_,_,BLACK,_,_)
  F.prototype.minKey       = ()         -> min(new Some(this)).get().key
  F.prototype.get          = (key)      -> get(new Some(this),key)
  F.prototype.count        = ()         -> count(new Some(this))

  ###
  # Private : ADT Operations
  ###

  # return the value associated with the given wrapped in an option.
  get = (optionNode, key) ->
    while !optionNode.isEmpty()
      cmp = optionNode.get().comparator(key,optionNode.get().key)
      if      cmp == 0 then return new Some(optionNode.get().value)
      else if cmp <  0 then optionNode = optionNode.get().left;
      else if cmp >  0 then optionNode = optionNode.get().right;
    return new None()

  # returns the node with the minimum key is tree rooted at optionNode
  min = (optionNode) ->
    if (optionNode.isEmpty())
      return new None();
    n = optionNode.get() # it's okay. just checked that it wasn't empty
    if n.left.isEmpty()
      return new Some(n)
    else
      min(n.left)

  # Returns a plain node
  insert = (optionNode,key,item) ->
    if optionNode.isEmpty() then return new LLRBNode(key,item)

    n   = optionNode.get()
    cmp = n.comparator(key,n.key)

    if (cmp < 0)     then n = n.copy(_,_,_,new Some(insert(n.left,key,item)),_)
    else if cmp == 0 then n = n.copy(_,item,_,_,_)
    else                  n = n.copy(_,_,_,_,new Some(insert(n.right,key,item)))

    return fixUp(n)

  # takes option wrapper node and returns an option wrapped node
  removeMin = (optionNode) ->
    if (optionNode.isEmpty() or optionNode.get().left.isEmpty())
      return new None()

    n = optionNode.get()

    if !isRed(n.left) and !isRed(n.left.get().left)
      n = moveRedLeft(n)

    n = n.copy(_,_,_,removeMin(n.left),_)
    return new Some(fixUp(n))

  # takes an option wrapped node and returns an option wrapped node
  remove = (optionNode,key) ->

    if optionNode.isEmpty()
      return new None()

    n = optionNode.get() # it's okay. just checked that it wasn't empty

    if n.comparator(key,n.key) < 0
      if !n.left.isEmpty() and !isRed(n.left) and !isRed(n.left.get().left)
         n = moveRedLeft(n)
      n = n.copy(_,_,_,remove(n.left,key),_)
    else
      if isRed(n.left)
        n = rotateRight(n)
      if !n.right.isEmpty() and !isRed(n.right) and !isRed(n.right.get().left)
        n = moveRedRight(n)
      if n.comparator(key, n.key) == 0
        if n.right.isEmpty()
          return new None()
        else
          smallest = min(n.right).get()
          n  = n.copy(smallest.key,smallest.val,_,_,removeMin(n.right))
      n = n.copy(_,_,_,_,remove(n.right, key))
    return new Some(fixUp(n))

  ###
  # Misc. other relevant functions
  ###

  # returns the elements in the tree rooted at the node
  count = (optionNode) ->
    if optionNode.isEmpty()
      0
    else
      n = optionNode.get()
      count(n.left) + 1 + count(n.right)

  ###
  # Private : Bunch of small helper functions
  ###

  RED       = true
  BLACK     = false
  _         = {}      # used in copy if you want to keep the old value

  # looks inside an option to see if the node is red. false if it's empty.
  isRed = (optionNode) -> optionNode.map( (n) -> n.color).getOrElse(false)

  standard_comparator = (elem1, elem2) ->
    if      (elem1 < elem2) then -1
    else if (elem1 > elem2) then  1
    else                          0

  # takes a plain node and returns a plain node
  fixUp = (n) ->
    if isRed(n.right) and !isRed(n.left)           then n = rotateLeft(n)
    if isRed(n.left)  and isRed(n.left.get().left) then n = rotateRight(n)
    if isRed(n.left)  and isRed(n.right)           then n = colorFlip(n)
    return n

  # takes a plain node and returns a plain node
  moveRedLeft = (node) ->
    n = colorFlip(node)
    if isRed(n.right.get().left)
      n = n.copy(_,_,_,_,new Some(rotateRight(n.right.get())))
      n = rotateLeft(n)
      n = colorFlip(n)
    return n

  # takes a plain node and returns a plain node
  moveRedRight = (node) ->
    n = colorFlip(node)
    if isRed(n.left.get().left)
      n = rotateRight(n)
      n = colorFlip(n)
    return n

  # takes a plain node and returns a plain node
  rotateLeft = (node) ->
    nl = node.copy(_,_,RED,_,node.right.get().left)
    node.right.get().copy(_,_,node.color,new Some(nl),_)

  # takes a plain node and returns a plain node
  rotateRight = (node) ->
    nr = node.copy(_,_,RED,node.left.get().right,_)
    node.left.get().copy(_,_,node.color,_,new Some(nr))

  # takes a plain node and returns a plain node
  colorFlip = (node) ->
    left  = node.left.get().copy(_,_,!node.left.get().color,_,_)
    right = node.right.get().copy(_,_,!node.right.get().color,_,_)
    node.copy(_,_,!node.color,new Some(left),new Some(right))

  ###
  # These methods are only for test purposes
  ###

  # returns true if the depth is below the max allowed depth
  checkMaxDepth = (node) ->
    blackDepth = check(new Some(node))
    if Math.pow(2.0, blackDepth) <= count(new Some(node)) + 1 then true else false

  # returns the black-depth if three is well-formed, else throws an exception
  check = (optionNode) ->
    if optionNode.isEmpty()
      0
    else
      node = optionNode.get()
      if isRed(optionNode) && isRed(optionNode.get().left)
        throw new Error("Red node has red child(" + node.key+","+node.value+")")
      if isRed(node.right)
        throw new Error("Right child of (" + node.key+","+node.value+") is red")
      blackDepth = check(node.left)
      if blackDepth != check(node.right)
        throw new Error("Black depths differ")
      else
        return blackDepth + if isRed(optionNode) then 0 else 1

  F.prototype.checkMaxDepth = () -> checkMaxDepth(this)
  F.prototype.rotateRight   = () -> rotateRight(this)
  F.prototype.rotateLeft    = () -> rotateLeft(this)

  return F
)()