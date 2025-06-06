{ pkgs, haskellLib }:

with haskellLib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (pkgs) lib;
in

self: super: {

  # ghcjs does not use `llvmPackages` and exposes `null` attribute.
  llvmPackages =
    if self.ghc.llvmPackages != null then pkgs.lib.dontRecurseIntoAttrs self.ghc.llvmPackages else null;

  # Disable GHC 8.10.x core libraries.
  array = null;
  base = null;
  binary = null;
  bytestring = null;
  Cabal = null;
  containers = null;
  deepseq = null;
  directory = null;
  exceptions = null;
  filepath = null;
  ghc-boot = null;
  ghc-boot-th = null;
  ghc-compact = null;
  ghc-heap = null;
  ghc-prim = null;
  ghci = null;
  haskeline = null;
  hpc = null;
  integer-gmp = null;
  libiserv = null;
  mtl = null;
  parsec = null;
  pretty = null;
  process = null;
  rts = null;
  stm = null;
  template-haskell = null;
  # GHC only builds terminfo if it is a native compiler
  terminfo =
    if pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform then
      null
    else
      doDistribute self.terminfo_0_4_1_7;
  text = null;
  time = null;
  transformers = null;
  unix = null;
  # GHC only bundles the xhtml library if haddock is enabled, check if this is
  # still the case when updating: https://gitlab.haskell.org/ghc/ghc/-/blob/0198841877f6f04269d6050892b98b5c3807ce4c/ghc.mk#L463
  xhtml = if self.ghc.hasHaddock or true then null else doDistribute self.xhtml_3000_4_0_0;

  # Need the Cabal-syntax-3.6.0.0 fake package for Cabal < 3.8 to allow callPackage and the constraint solver to work
  Cabal-syntax = self.Cabal-syntax_3_6_0_0;
  # These core package only exist for GHC >= 9.4. The best we can do is feign
  # their existence to callPackages, but their is no shim for lower GHC versions.
  system-cxx-std-lib = null;

  # Becomes a core package in GHC >= 9.8
  semaphore-compat = doDistribute self.semaphore-compat_1_0_0;

  # only broken for >= 9.6
  calligraphy = doDistribute (unmarkBroken super.calligraphy);

  # Only required for ghc >= 9.2
  nothunks = super.nothunks.override {
    wherefrom-compat = null;
  };

  # Tests require nothunks < 0.3 (conflicting with Stackage) for GHC < 9.8
  aeson = dontCheck super.aeson;

  # For GHC < 9.4, some packages need data-array-byte as an extra dependency
  # For GHC < 9.2, os-string is not required.
  primitive = addBuildDepends [ self.data-array-byte ] super.primitive;
  hashable =
    addBuildDepends
      [
        self.data-array-byte
        self.base-orphans
      ]
      (
        super.hashable.override {
          os-string = null;
        }
      );
  hashable-time = doDistribute (unmarkBroken super.hashable-time);

  # Needs base-orphans for GHC < 9.8 / base < 4.19
  some = addBuildDepend self.base-orphans super.some;

  # Too strict lower bounds on base
  primitive-addr = doJailbreak super.primitive-addr;

  # Pick right versions for GHC-specific packages
  ghc-api-compat = doDistribute (unmarkBroken self.ghc-api-compat_8_10_7);

  # Needs to use ghc-lib due to incompatible GHC
  ghc-tags = doDistribute self.ghc-tags_1_5;

  # Jailbreak to fix the build.
  base-noprelude = doJailbreak super.base-noprelude;
  unliftio-core = doJailbreak super.unliftio-core;

  # Jailbreak to fix the build.
  brick = doJailbreak super.brick;
  exact-pi = doJailbreak super.exact-pi;
  serialise = doJailbreak super.serialise;
  setlocale = doJailbreak super.setlocale;
  shellmet = doJailbreak super.shellmet;
  shower = doJailbreak super.shower;

  # hnix 0.9.0 does not provide an executable for ghc < 8.10, so define completions here for now.
  hnix = self.generateOptparseApplicativeCompletions [ "hnix" ] (
    overrideCabal (drv: {
      # executable is allowed for ghc >= 8.10 and needs repline
      executableHaskellDepends = drv.executableToolDepends or [ ] ++ [ self.repline ];
    }) super.hnix
  );

  haskell-language-server = throw "haskell-language-server dropped support for ghc 8.10 in version 2.3.0.0 please use a newer ghc version or an older nixpkgs version";

  ghc-lib-parser = doDistribute self.ghc-lib-parser_9_2_8_20230729;
  ghc-lib-parser-ex = doDistribute self.ghc-lib-parser-ex_9_2_1_1;
  ghc-lib = doDistribute self.ghc-lib_9_2_8_20230729;

  path-io = doJailbreak super.path-io;

  hlint = self.hlint_3_4_1;

  mime-string = disableOptimization super.mime-string;

  # weeder 2.3.* no longer supports GHC 8.10
  weeder = doDistribute (doJailbreak self.weeder_2_2_0);
  # Unnecessarily strict upper bound on lens
  weeder_2_2_0 = doJailbreak (
    super.weeder_2_2_0.override {
      # weeder < 2.6 only supports algebraic-graphs < 0.7
      # We no longer have matching test deps for algebraic-graphs 0.6.1 in the set
      algebraic-graphs = dontCheck self.algebraic-graphs_0_6_1;
    }
  );

  # Uses haddock placement that isn't supported by the versions of haddock
  # bundled with GHC < 9.0.
  wai-extra = dontHaddock super.wai-extra;

  # tar > 0.6 requires os-string which can't be built with bytestring < 0.11
  tar = overrideCabal (drv: {
    jailbreak = true;
    buildDepends = drv.buildDepends or [ ] ++ [
      self.bytestring-handle
    ];
  }) self.tar_0_6_0_0;
  # text-metrics >= 0.3.3 requires GHC2021
  text-metrics = doDistribute (doJailbreak self.text-metrics_0_3_2);
  bytestring-handle = unmarkBroken (doDistribute super.bytestring-handle);

  # Doesn't build with 9.0, see https://github.com/yi-editor/yi/issues/1125
  yi-core = doDistribute (markUnbroken super.yi-core);

  # Temporarily disabled blaze-textual for GHC >= 9.0 causing hackage2nix ignoring it
  # https://github.com/paul-rouse/mysql-simple/blob/872604f87044ff6d1a240d9819a16c2bdf4ed8f5/Database/MySQL/Internal/Blaze.hs#L4-L10
  mysql-simple = addBuildDepends [
    self.blaze-textual
  ] super.mysql-simple;

  taffybar = markUnbroken (doDistribute super.taffybar);

  # https://github.com/fpco/inline-c/issues/127 (recommend to upgrade to Nixpkgs GHC >=9.0)
  inline-c-cpp = (if isDarwin then dontCheck else x: x) super.inline-c-cpp;

  # Depends on OneTuple for GHC < 9.0
  universe-base = addBuildDepends [ self.OneTuple ] super.universe-base;

  # Not possible to build in the main GHC 9.0 package set
  # https://github.com/awakesecurity/spectacle/issues/49
  spectacle = doDistribute (markUnbroken super.spectacle);

  # doctest-parallel dependency requires newer Cabal
  regex-tdfa = dontCheck super.regex-tdfa;

  # Unnecessarily strict lower bound on base
  # https://github.com/mrkkrp/megaparsec/pull/485#issuecomment-1250051823
  megaparsec = doJailbreak super.megaparsec;

  retrie = dontCheck self.retrie_1_1_0_0;

  # Later versions only support GHC >= 9.2
  ghc-exactprint = self.ghc-exactprint_0_6_4;

  apply-refact = self.apply-refact_0_9_3_0;

  # Needs OneTuple for ghc < 9.2
  binary-orphans = addBuildDepends [ self.OneTuple ] super.binary-orphans;

  # 0.4.6.0 only supports >= 9.0
  ghc-source-gen = doDistribute self.ghc-source-gen_0_4_5_0;

  # No instance for (Show B.Builder) arising from a use of ‘print’
  http-types = dontCheck super.http-types;

  # Packages which need compat library for GHC < 9.6
  inherit (lib.mapAttrs (_: addBuildDepends [ self.foldable1-classes-compat ]) super)
    indexed-traversable
    these
    ;
  base-compat-batteries = addBuildDepends [
    self.foldable1-classes-compat
    self.OneTuple
  ] super.base-compat-batteries;

  # OneTuple needs hashable (instead of ghc-prim) and foldable1-classes-compat for GHC < 9
  OneTuple =
    addBuildDepends
      [
        self.foldable1-classes-compat
        self.base-orphans
      ]
      (
        super.OneTuple.override {
          ghc-prim = self.hashable;
        }
      );
}
