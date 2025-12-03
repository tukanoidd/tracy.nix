{
  description = "Trace Profiler";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        packages.default = with pkgs; let
          cpmSourceCache = import ./cpm-dependencies.nix {
            inherit
              lib
              fetchFromGitHub
              fetchurl
              fetchFromGitLab
              runCommand
              ;
          };
        in
          pkgs.stdenv.mkDerivation rec {
            pname = "tracy";
            version = "0.13.0";

            src = fetchFromGitHub {
              owner = "wolfpld";
              repo = "tracy";
              rev = "v${version}";
              hash = "sha256-voHql8ETnrUMef14LYduKI+0LpdnCFsvpt8B6M/ZNmc=";
            };

            patches = [
              ./cpm-no-hash.patch
              ./no-git.patch
            ];

            postUnpack = ''
              # Copy the CPM source cache to a directory where cpm expects it
              mkdir -p $sourceRoot/cpm_source_cache
              cp -r --no-preserve=mode ${cpmSourceCache}/. $sourceRoot/cpm_source_cache

              # Manually apply the patches, that would have been applied to the downloaded source
              # We need to do that here, because in the cpmSourceCache we don't know about these patches yet
              patch -d $sourceRoot/cpm_source_cache/imgui/NIX_ORIGIN_HASH_STUB/ -p1 < $sourceRoot/cmake/imgui-emscripten.patch
              patch -d $sourceRoot/cpm_source_cache/imgui/NIX_ORIGIN_HASH_STUB/ -p1 < $sourceRoot/cmake/imgui-loader.patch
              patch -d $sourceRoot/cpm_source_cache/ppqsort/NIX_ORIGIN_HASH_STUB/ -p1 < $sourceRoot/cmake/ppqsort-nodebug.patch
            '';

            nativeBuildInputs = [
              cmake
              ninja
              pkg-config
              wayland-scanner
              libglvnd
              libxkbcommon
              wayland
              gtk3

              tbb_2022
            ];

            cmakeFlags = [
              "-DDOWNLOAD_CAPSTONE=off"
              "-DTRACY_STATIC=off"
              "-DCPM_SOURCE_CACHE=/build/source/cpm_source_cache"
              "-DGTK_FILESELECTION=ON"
            ];

            env.NIX_CFLAGS_COMPILE = "-ltbb";

            dontUseCmakeBuildDir = true;

            postConfigure = ''
              cmake -B capture/build -S capture $cmakeFlags
              cmake -B csvexport/build -S csvexport $cmakeFlags
              cmake -B import/build -S import $cmakeFlags
              cmake -B profiler/build -S profiler $cmakeFlags
              cmake -B update/build -S update $cmakeFlags
            '';

            postBuild = ''
              ninja -C capture/build
              ninja -C csvexport/build
              ninja -C import/build
              ninja -C profiler/build
              ninja -C update/build
            '';

            postInstall = ''
              install -D -m 0555 capture/build/tracy-capture -t $out/bin
              install -D -m 0555 csvexport/build/tracy-csvexport $out/bin
              install -D -m 0555 import/build/{tracy-import-chrome,tracy-import-fuchsia} -t $out/bin
              install -D -m 0555 profiler/build/tracy-profiler $out/bin/tracy
              install -D -m 0555 update/build/tracy-update -t $out/bin

              substituteInPlace extra/desktop/tracy.desktop \
                --replace-fail Exec=/usr/bin/tracy Exec=tracy

              install -D -m 0444 extra/desktop/application-tracy.xml $out/share/mime/packages/application-tracy.xml
              install -D -m 0444 extra/desktop/tracy.desktop $out/share/applications/tracy.desktop
              install -D -m 0444 icon/application-tracy.svg $out/share/icons/hicolor/scalable/apps/application-tracy.svg
              install -D -m 0444 icon/icon.png $out/share/icons/hicolor/256x256/apps/tracy.png
              install -D -m 0444 icon/icon.svg $out/share/icons/hicolor/scalable/apps/tracy.svg
            '';

            meta = with lib; {
              description = "Real time, nanosecond resolution, remote telemetry frame profiler for games and other applications";
              homepage = "https://github.com/wolfpld/tracy";
              license = licenses.bsd3;
              mainProgram = "tracy";
              maintainers = [
                "tukanoid"
              ];
              platforms = platforms.linux;
            };
          };
      };
    };
}
