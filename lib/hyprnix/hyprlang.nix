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

  mkNodeType = type: path: name: value: {
    _node_type = type;
    inherit name value;
    path = path ++ [ name ];
  };
  mkStringNode = mkNodeType "string";
  mkIndentNode = mkNodeType "indent";
  mkVariableNode = mkNodeType "variable";
  mkRepeatNode = mkNodeType "repeatBlock";
  mkSectionNode = mkNodeType "configDocument";

  nodeType = builtins.getAttr "_node_type";
  mapValue = fn: node: node // { value = fn node.value; };

  # concatListsSep = sep: lib.foldl' (a: b: a ++ [sep] ++ b) [];

  attrsToNodeList = path: attrs:
    let
      variables = lib.pipe attrs [
        (lib.filterAttrs (_: v: !(lib.isAttrs v || lib.isList v)))
        (lib.mapAttrsToList (mkVariableNode path))
      ];
      repeats = lib.pipe attrs [
        (lib.filterAttrs (_: lib.isList))
        (lib.mapAttrsToList (name: values:
          mkRepeatNode path name (map (value:
            if lib.isAttrs value then
              mkSectionNode path name (attrsToNodeList (path ++ [ name ]) value)
            else
              mkVariableNode path name value) values)))
      ];
      sections = lib.pipe attrs [
        (lib.filterAttrs (_: lib.isAttrs))
        (lib.mapAttrsToList (name: value:
          mkSectionNode path name (attrsToNodeList (path ++ [ name ]) value)))
      ];
    in lib.concatLists [ variables repeats sections ];

  pruneEmptyNodesRecursive = lib.foldl' (nodes: next:
    let
      next' = if isRepeatNode next || isSectionNode next then
        mapValue pruneEmptyNodesRecursive next
      else
        next;
    in if next'.value == [ ] then nodes else nodes ++ [ next' ]) [ ];

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
