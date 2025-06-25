{ lib }:
lib.bird.mkTestSuite {
  orderOfPath = let inherit (lib.hyprnix.ordering) orderOfPath;
  in [ # #
    {
      name = "trivial ordering";
      expr = let patterns = [ [ "a" ] [ "b" ] [ "c" ] ];
      in map (path: orderOfPath path patterns) [ [ "c" ] [ "b" ] [ "a" ] ];
      expect = [ 2 1 0 ];
    }
  ];
}
