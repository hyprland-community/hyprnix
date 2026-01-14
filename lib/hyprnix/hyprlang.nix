# The design of this library avoids treating the AST as objects containing the parse state as well as their curried operands.
# To avoid this however, we rely on a nontrivial Nix-expression to Hyprlang AST transformer, and it can be difficult to encapsulate
# both the Nix side and the Hyprlang side cohesively. This is not using the Nixpkgs type system for the sake of
# performance, forwards-compatibility with itself and user's configuration, and just general simplicity.
# It does however depend on some simple functions for transforming Nix expressions from `bird-nix-lib`,
# which probably needs some attention.
#
# Without injucting functions into the configuration's expression,
# 1. Turn Nix values into corresponding nodes and leaf values for AST (`attrsToNodeList` unless overridden).
# 2. Walk the AST and prune empty nodes,
# 3. Sort the AST recursively by a predicate.
#    The default predicate is defined by the user's Nix configuration, with sensible defaults.
#    It is exposed as a function which (hopefully) is easy to interpret. See the library function
#    `orderOfPath` in `ordering.nix`, then how the default predicate is constructed as an index
#    comparison in `hm-module/configFormat.nix`.
# 4. Post-process with niceties, like extra line breaks between dissimilar blocks and indentation.
#    This heavily influenced the design of a "node list" (AST). These are inserted as AST nodes,
#    and their values can't be represented by the input of step 1.
# 5. Finally, a function walks the AST and accumulates the text of the Hyprlang configuration (`renderNodeList`).

lib: _:
let
  toConfigString = {
    # If a custom Nix structure is desired, the parser may be replaced.
    astBuilder ? attrsToNodeList [ ],
    # Given two attribute paths, return `true` if the
    # first should precede the second.
    sortPred ? _: _: false,
    # String to use for indentation characters.
    indentChars ? "    ",
    # Given two nodes (from the AST) return `true` if a line-break
    # should be inserted between them.
    lineBreakPred ? prev: next:
      let
        betweenDifferent = nodeType prev != nodeType next;
        betweenRepeats = isRepeatNode prev && isRepeatNode next;
        betweenSections = isSectionNode prev && isSectionNode next;
      in prev != null && (betweenDifferent || betweenRepeats || betweenSections)
    ,
    # Whether the output should be formatted with spaces around
    # the `=` character in a keyword assignment.
    spaceAroundEquals ? true,
    #
    }:
    attrs:
    lib.pipe attrs [
      astBuilder
      pruneEmptyNodesRecursive
      (sortNodeListRecursive sortPred)
      (insertLineBreakNodesRecursive lineBreakPred)
      (insertIndentNodesRecursive indentChars)
      (renderNodeList { inherit indentChars spaceAroundEquals; })
    ];

  toPrettyM = lib.generators.toPretty { multiline = true; };

  renderNodeList = opts: nodes: lib.concatStrings (map (renderNode opts) nodes);

  isNode = node: lib.isAttrs node && node ? _node_type;
  isNodeType = type: node: isNode node && node._node_type == type;
  isStringNode = isNodeType "string";
  isIndentNode = isNodeType "indent";
  isVariableNode = isNodeType "variable";
  isRepeatNode = isNodeType "repeatBlock";
  isSectionNode = isNodeType "configDocument";

  # Produces amorphous node prototypes
  mkNodeType = type: path: name: value: {
    _node_type = type;
    inherit name value;
    # `path` is somewhat arbitrary depending upon the implementation of `toConfigString`,
    # It is used for levels of indentation and sorting.
    path = path ++ [ name ];
  };
  # Curry off the `_node_type` identifier and produce the factories that `renderNodeList` can handle.
  # Apply `path`, `name`, `value` arguments.
  mkStringNode = mkNodeType "string";
  mkIndentNode = mkNodeType "indent";
  # This is the leaf node.
  mkVariableNode = mkNodeType "variable";
  mkRepeatNode = mkNodeType "repeatBlock";
  mkSectionNode = mkNodeType "configDocument";

  nodeType = builtins.getAttr "_node_type";
  # Apply a function to an AST node's Nix value.
  mapValue = fn: node: node // { value = fn node.value; };

  # concatListsSep = sep: lib.foldl' (a: b: a ++ [sep] ++ b) [];

  # This function will be invoked recursively. `path` is the current depth of Hyprlang sections,
  # represented as a list of Nix attribute names. `attrs` is the current document to transform.
  attrsToNodeList = path: attrs:
    let
      # Variables can't be attributes or lists. These are the leaves.
      variables = lib.pipe attrs [
        # Exclude sections and repeats.
        (lib.filterAttrs (_: v: !(lib.isAttrs v || lib.isList v)))
        # For every remaining attribute, convert each `name` and `value` pair to a variable node.
        (lib.mapAttrsToList (mkVariableNode path))
      ];
      # These are variables which have been provided as a list of values for the same keyword.
      repeats = lib.pipe attrs [
        # Repeats are always lists.
        (lib.filterAttrs (_: lib.isList)) 
        (lib.mapAttrsToList (name: values:
          mkRepeatNode path name (map (value:
            if lib.isAttrs value then
              mkSectionNode path name (attrsToNodeList (path ++ [ name ]) value)
            else
              mkVariableNode path name value) values)))
      ];
      sections = lib.pipe attrs [
        # Configuration sections can only be attributes.
        (lib.filterAttrs (_: lib.isAttrs))
        # For every top-level attribute name and value, create a node with a path, name, and value.
        # The node's name is pushed to the top of the path stack.
        (lib.mapAttrsToList (name: value:
          mkSectionNode path name (attrsToNodeList (path ++ [ name ]) value)))
      ];
    # Finally, emit a recursive list of lists.
    # Variables will be flat nodes at the end of the intermediate AST,
    # repeats will be a list of variables but with a path depth different
    # than what is represented by this output,
    # and sections are recursive lists of variables, repeats, and sections.
    in lib.concatLists [ variables repeats sections ];

  # Does what it says on the tin.
  pruneEmptyNodesRecursive = lib.foldl' (nodes: next:
    let
      next' = if isRepeatNode next || isSectionNode next then
        mapValue pruneEmptyNodesRecursive next
      else
        next;
    in if next'.value == [ ] then nodes else nodes ++ [ next' ]) [ ];

  # Recursively walk the AST lists and compare the paths of each pair of adjacent nodes,
  # and order them according to the predicate function provided.
  # The predicate emits `true` if the first node must be positioned
  # after its successor in the Hyprlang output.
  sortNodeListRecursive = sortPred:
    let
      recurse = l:
        lib.pipe l [
          (map (node:
            if isRepeatNode node || isSectionNode node then
              mapValue recurse node
            else
              node))
          (lib.sort (a: b: sortPred a.path b.path))
        ];
    in recurse;

  insertLineBreakNodesRecursive = breakPred:
    let
      recurse = lib.foldl' (nodes: next:
        let
          prev = if nodes == [ ] then
            null
          else
            builtins.elemAt nodes (builtins.length nodes - 1);
          next' = if isRepeatNode next || isSectionNode next then
            mapValue recurse next
          else
            next;
          newline = mkStringNode next.path "newline" "\n";
        in if breakPred prev next' then
          nodes ++ [ newline ] ++ [ next' ]
        else
          nodes ++ [ next' ]) [ ];
    in recurse;

  insertIndentNodesRecursive = indentChars:
    let
      recurse = lib.foldl' (nodes: next:
        let
          level = builtins.length next.path - 1;
          indent = mkIndentNode next.path "indent" level;
        in if isVariableNode next then
          nodes ++ [ indent ] ++ [ next ]
        else if isRepeatNode next then
          nodes ++ [ (mapValue recurse next) ]
        else if isSectionNode next then
          nodes ++ [ indent (mapValue (v: (recurse v) ++ [ indent ]) next) ]
        else
          nodes ++ [ next ]) [ ];
    in recurse;

  # Creates a string with chars repeated N times.
  repeatChars = chars: level:
    lib.concatStrings (map (_: chars) (lib.range 1 level));

  renderNode = opts: node:
    if isStringNode node then
      node.value
    else if isIndentNode node then
      repeatChars opts.indentChars node.value
    else if isVariableNode node then
      let equals = if opts.spaceAroundEquals then " = " else "=";
      in ''
        ${node.name}${equals}${valueToString node.value}
      ''
    else if isRepeatNode node then
      lib.concatStrings (map (renderNode opts) node.value)
    else if isSectionNode node then ''
      ${node.name} {
      ${renderNodeList opts node.value}}
    '' else
      abort ''
        value is not of any known node type:
        ${toPrettyM node}
      '';

  # Converts a single value to a valid Hyprland config RHS
  valueToString = value:
    if value == null then
      ""
    else if lib.isBool value then
      lib.boolToString value
    else if lib.isInt value || lib.isFloat value then
      toString value
    else if lib.isString value then
      value
    else if lib.isList value then
      lib.concatMapStringsSep " " valueToString value
    else
      abort ''
        could not convert value of type '${
          builtins.typeOf value
        }' to config string:
        ${toPrettyM value}
      '';
in {
  inherit
  # Transforms
    toConfigString attrsToNodeList pruneEmptyNodesRecursive renderNodeList
    insertLineBreakNodesRecursive insertIndentNodesRecursive
    # Checks
    nodeType isNode isNodeType isStringNode isIndentNode isVariableNode
    isRepeatNode isSectionNode
    # Node Factories
    mkStringNode mkIndentNode mkVariableNode mkRepeatNode mkSectionNode
    # Utilities
    mapValue renderNode valueToString;
}
