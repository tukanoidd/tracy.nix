{
  lib,
  fetchFromGitHub,
  fetchurl,
  fetchFromGitLab,
  runCommand,
}: let
  # List of all the dependencies that get fetched via CPM during the configure phase
  # This was obtained by repeatedly running `nix build` and looking for
  # messages like these in the logs:
  # CPM: Adding package zstd@1.5.7 (v1.5.7 to /build/source/cpm_source_cache/zstd/dfd2e0b6e613dcf44911302708e636a8aee527d2)
  #
  # If we pass git into nativeBuildDependencies and disable the no git patch, then the build logs also tell us
  # the repository that CPM tries to download the sources from
  cpmDeps = [
    {
      name = "zstd";
      src = fetchFromGitHub {
        owner = "facebook";
        repo = "zstd";
        rev = "v1.5.7";
        hash = "sha256-tNFWIT9ydfozB8dWcmTMuZLCQmQudTFJIkSr0aG7S44=";
      };
    }
    {
      name = "imgui";
      src = fetchFromGitHub {
        owner = "ocornut";
        repo = "imgui";
        rev = "v1.92.5-docking";
        hash = "sha256-/jVT7+874LCeSF/pdNVTFoSOfRisSqxCJnt5/SGCXPQ=";
      };
    }
    {
      name = "nfd";
      src = fetchFromGitHub {
        owner = "btzy";
        repo = "nativefiledialog-extended";
        rev = "v1.2.1";
        hash = "sha256-GwT42lMZAAKSJpUJE6MYOpSLKUD5o9nSe9lcsoeXgJY=";
      };
    }
    {
      name = "ppqsort";
      src = fetchFromGitHub {
        owner = "GabTux";
        repo = "PPQSort";
        rev = "v1.0.6";
        hash = "sha256-HgM+p2QGd9C8A8l/VaEB+cLFDrY2HU6mmXyTNh7xd0A=";
      };
    }
    {
      name = "capstone";
      src = fetchFromGitHub {
        owner = "capstone-engine";
        repo = "capstone";
        rev = "6.0.0-Alpha5";
        hash = "sha256-18PTj4hvBw8RTgzaFGeaDbBfkxmotxSoGtprIjcEuVg=";
      };
    }
    {
      name = "packageproject.cmake";
      # Transitive from PPQSort
      src = fetchFromGitHub {
        owner = "TheLartians";
        repo = "PackageProject.cmake";
        rev = "v1.11.1";
        hash = "sha256-E7WZSYDlss5bidbiWL1uX41Oh6JxBRtfhYsFU19kzIw=";
      };
    }
    {
      name = "wayland-protocols";
      src = fetchFromGitLab {
        owner = "wayland";
        repo = "wayland-protocols";
        rev = "1.37";
        domain = "gitlab.freedesktop.org";
        hash = "sha256-ryyv1RZqpwev1UoXRlV8P1ujJUz4m3sR89iEPaLYSZ4=";
      };
    }
    {
      name = "json";
      src = fetchFromGitHub {
        owner = "nlohmann";
        repo = "json";
        rev = "v3.12.0";
        hash = "sha256-cECvDOLxgX7Q9R3IE86Hj9JJUxraDQvhoyPDF03B2CY=";
      };
    }
    {
      name = "md4c";
      src = fetchFromGitHub {
        owner = "mity";
        repo = "md4c";
        rev = "release-0.5.2";
        hash = "sha256-2/wi7nJugR8X2J9FjXJF1UDnbsozGoO7iR295/KSJng=";
      };
    }
    {
      name = "base64";
      src = fetchFromGitHub {
        owner = "aklomp";
        repo = "base64";
        rev = "v0.5.2";
        hash = "sha256-dIaNfQ/znpAdg0/vhVNTfoaG7c8eFrdDTI0QDHcghXU=";
      };
    }
    {
      name = "tidy";
      src = fetchFromGitHub {
        owner = "htacg";
        repo = "tidy-html5";
        rev = "5.8.0";
        hash = "sha256-vzVWQodwzi3GvC9IcSQniYBsbkJV20iZanF33A0Gpe0=";
      };
    }
    {
      name = "usearch";
      src = fetchFromGitHub {
        owner = "unum-cloud";
        repo = "usearch";
        rev = "v2.21.3";
        hash = "sha256-euLJQeJK1rf4PCS+DMFo+/bnOBQdpnM3FIsC9DtL+wY=";
      };
    }
    {
      name = "pugixml";
      src = fetchFromGitHub {
        owner = "zeux";
        repo = "pugixml";
        rev = "v1.15";
        hash = "sha256-t/57lg32KgKPc7qRGQtO/GOwHRqoj78lllSaE/A8Z9Q=";
      };
    }
    {
      name = "libcurl";
      src = fetchFromGitHub {
        owner = "curl";
        repo = "curl";
        rev = "curl-8_17_0";
        hash = "sha256-fMiiX1vlLh3AqwARUgm+356pRTCu13Q3PDq1q9RDgQQ=";
      };
    }
  ];

  # Weird CPM Dep where ppqsort uses cpm to manage cpm itself
  cpmDep = fetchurl {
    url = "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.38.7/CPM.cmake";
    hash = "sha256-g+XrcbK7uLHyrTjxlQKHoFdiTjhcI49gh/lM38RK+cU=";
  };
  # Combine all the dependencies into the cpm source cache, that gets copied into the build directory
in
  runCommand "cpm-source-cache" {} (
    ''
      mkdir -p $out/cpm
      cp --no-preserve=mode -r ${cpmDep} $out/cpm/CPM_0.38.7.cmake
    ''
    + (lib.strings.concatMapStringsSep "\n" (dep: ''
        mkdir -p $out/${dep.name}/NIX_ORIGIN_HASH_STUB
        cp --no-preserve=mode -r ${dep.src}/. $out/${dep.name}/NIX_ORIGIN_HASH_STUB
      '')
      cpmDeps)
  )
