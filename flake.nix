{
  description = "Paranoia Engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls-overlay.url = "github:zigtools/zls?ref=0.16.0";
  };

  outputs = { self, nixpkgs, zig-overlay, zls-overlay }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      zig-pkg = zig-overlay.packages.${system}."0.16.0";
      zls-pkg = zls-overlay.packages.${system}.zls.overrideAttrs (old: {
        doCheck = false;
      });

    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          zig-pkg
          zls-pkg

          sdl3

          vulkan-loader
          vulkan-validation-layers
          vulkan-tools
          vulkan-headers

          shaderc
          glslang

          pkg-config
          gdb
          lldb
        ];

        shellHook = ''
          export VK_LAYER_PATH=${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d
          export LD_LIBRARY_PATH=${pkgs.vulkan-loader}/lib:$LD_LIBRARY_PATH

          export VULKAN_REGISTRY=${pkgs.vulkan-headers}/share/vulkan/registry/vk.xml

          zig version
          zls version
        '';
      };
    };
}
