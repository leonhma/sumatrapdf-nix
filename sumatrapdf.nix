{ stdenv
, lib
, mkWindowsApp
, wine
, fetchurl
, makeDesktopItem
, makeDesktopIcon   # This comes with erosanix. It's a handy way to generate desktop icons.
, copyDesktopItems
, copyDesktopIcons  # This comes with erosanix. It's a handy way to generate desktop icons.
, unzip }:
mkWindowsApp rec {
  inherit wine;

  pname = "sumatrapdf";
  version = "3.3.3";

  src = fetchurl {
    url = "https://kjkpubsf.sfo2.digitaloceanspaces.com/software/sumatrapdf/rel/SumatraPDF-${version}-64.zip";
    sha256 = "1b9l2hjngllzb478gvhp3dzn8hpxp9yj3q1wnq59d9356bi33md4";
  };

  # In most cases, you'll either be using an .exe or .zip as the src.
  # Even in the case of a .zip, you probably want to unpack with the launcher script.
  dontUnpack = true;   

  # You need to set the WINEARCH, which can be either "win32" or "win64".
  # Note that the wine package you choose must be compatible with the Wine architecture.
  wineArch = "win64";

  nativeBuildInputs = [ unzip copyDesktopItems copyDesktopIcons ];

  # This code will become part of the launcher script.
  # It will execute if the application needs to be installed,
  # which would happen either if the needed app layer doesn't exist,
  # or for some reason the needed Windows layer is missing, which would
  # invalidate the app layer.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  winAppInstall = ''
    d="$WINEPREFIX/drive_c/${pname}"
    mkdir -p "$d"
    unzip ${src} -d "$d"
  '';

  # This code will become part of the launcher script.
  # It will execute after winAppInstall (if needed)
  # to run the application.
  # WINEPREFIX, WINEARCH, AND WINEDLLOVERRIDES are set
  # and wine, winetricks, and cabextract are in the environment.
  # Command line arguments are in $ARGS, not $@
  # You need to set up symlinks for any files/directories that need to be persisted.
  # To figure out what needs to be persisted, take at look at $(dirname $WINEPREFIX)/upper
  winAppRun = ''
    config_dir="$HOME/.config/sumatrapdf"
    cache_dir="$HOME/.cache/sumatrapdf"

    mkdir -p "$config_dir" "$cache_dir"
    touch "$config_dir/SumatraPDF-settings.txt"
    ln -s "$config_dir/SumatraPDF-settings.txt" "$WINEPREFIX/drive_c/${pname}/SumatraPDF-settings.txt"
    ln -s "$cache_dir" "$WINEPREFIX/drive_c/${pname}/${pname}cache"

    wine "$WINEPREFIX/drive_c/${pname}/SumatraPDF-${version}-64.exe" "$ARGS"
  '';

  # This is a normal mkDerivation installPhase, with some caveats.
  # The launcher script will be installed at $out/bin/.launcher
  # DO NOT DELETE OR RENAME the launcher. Instead, link to it as shown.
  installPhase = ''
    runHook preInstall

    ln -s $out/bin/.launcher $out/bin/${pname}

    runHook postInstall
  '';

  desktopItems = let
    mimeType = builtins.concatStringsSep ";" [ "application/pdf"
                 "application/epub+zip"
                 "application/x-mobipocket-ebook"
                 "application/vnd.amazon.mobi8-ebook"
                 "application/x-zip-compressed-fb2"
                 "application/x-cbt"
                 "application/x-cb7"
                 "application/x-7z-compressed"
                 "application/vnd.rar"
                 "application/x-tar"
                 "application/zip"
                 "image/vnd.djvu"
                 "image/vnd.djvu+multipage"
                 "application/vnd.ms-xpsdocument"
                 "application/oxps"
                 "image/jpeg"
                 "image/png"
                 "image/gif"
                 "image/webp"
                 "image/tiff"
                 "image/tiff-multipage"
                 "image/x-tga"
                 "image/bmp"
                 "image/x-dib" ];
  in [
    (makeDesktopItem {
      inherit mimeType;

      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Sumatra PDF";
      genericName = "Document Viewer";
      categories = "Office;Viewer;";
    })
  ];

  desktopIcon = makeDesktopIcon {
    name = "sumatrapdf";

    src = fetchurl {
      url = "https://github.com/sumatrapdfreader/${pname}/raw/${version}rel/gfx/SumatraPDF-256x256x32.png";
      sha256 = "1l7d95digqbpgg42lrv9740n4k3wn482m7dcwxm6z6n5kidhfp4b";
    };
  };

  meta = with lib; {
    description = "A free PDF, eBook (ePub, Mobi), XPS, DjVu, CHM, Comic Book (CBZ and CBR) viewer for Windows.";
    homepage = "https://www.sumatrapdfreader.org/free-pdf-reader";
    license = licenses.gpl3;
    maintainers = with maintainers; [ emmanuelrosa ];
    platforms = [ "x86_64-linux" ];
  };
}

