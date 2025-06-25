{ lib }:
lib.bird.mkTestSuite {
  orderOfPath = let inherit (lib.hyprnix.ordering) orderOfPath;
  in [
    {
      name = "trivial ordering";
      expr = let patterns = [ [ "a" ] [ "b" ] [ "c" ] ];
      in map (path: orderOfPath path patterns) [ [ "c" ] [ "b" ] [ "a" ] ];
      expect = [ 2 1 0 ];
    }
    {
      name = "ordering by specificity";
      expr = let patterns = [ [ "a" ".*" ] [ "a" "c" ] ];
      in map (path: orderOfPath path patterns) [
        [ "a" "c" ]
        [ "a" "b" ]
        [ "a" "a" ]
      ];
      expect = [ 1 0 0 ];
    }
  ];
}
