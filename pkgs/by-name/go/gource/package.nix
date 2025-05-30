{
  lib,
  stdenv,
  fetchurl,
  SDL2,
  ftgl,
  pkg-config,
  libpng,
  libjpeg,
  pcre2,
  SDL2_image,
  freetype,
  glew,
  libGLU,
  libGL,
  libX11,
  boost,
  glm,
  tinyxml,
}:

stdenv.mkDerivation rec {
  pname = "gource";
  version = "0.55";

  src = fetchurl {
    url = "https://github.com/acaudwell/Gource/releases/download/${pname}-${version}/${pname}-${version}.tar.gz";
    hash = "sha256-yCOSEtKLB1CNnkd2GZdoAmgWKPwl6z4E9mcRdwE8AUI=";
  };

  postPatch = ''
    # remove bundled library
    rm -r src/tinyxml
  '';

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    glew
    SDL2
    ftgl
    libpng
    libjpeg
    pcre2
    SDL2_image
    libGLU
    libGL
    libX11
    boost
    glm
    freetype
    tinyxml
  ];

  configureFlags = [
    "--with-boost-libdir=${boost.out}/lib"
    "--with-tinyxml"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://gource.io/";
    description = "Software version control visualization tool";
    license = licenses.gpl3Plus;
    longDescription = ''
      Software projects are displayed by Gource as an animated tree with
      the root directory of the project at its centre. Directories
      appear as branches with files as leaves. Developers can be seen
      working on the tree at the times they contributed to the project.

      Currently Gource includes built-in log generation support for Git,
      Mercurial and Bazaar and SVN. Gource can also parse logs produced
      by several third party tools for CVS repositories.
    '';
    platforms = platforms.unix;
    maintainers = with maintainers; [ pSub ];
    mainProgram = "gource";
  };
}
