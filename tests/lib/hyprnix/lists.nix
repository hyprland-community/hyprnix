{ lib }:
lib.bird.mkTestSuite {
  elemsMatch = let inherit (lib.hyprnix.lists) elemsMatch;
  in [
    {
      name = "no match if list is longer than pattern";
      expr = elemsMatch [ "a" "b" ] [ "a" "b" "c" ];
      expect = false;
    }
    {
      name = "no match if pattern is longer than list";
      expr = elemsMatch [ "a" "b" "c" ] [ "a" "b" ];
      expect = false;
    }
    {
      name = "matches if identical strings";
      expr = elemsMatch [ "foo" "bar" "baz" ] [ "foo" "bar" "baz" ];
      expect = true;
    }
    {
      name = "matches if middle regex matches";
      expr = lib.all (elemsMatch [ "foo" ".*" "baz" ]) [
        [ "foo" "bar" "baz" ]
        [ "foo" "rab" "baz" ]
      ];
      expect = true;
    }
  ];
}
