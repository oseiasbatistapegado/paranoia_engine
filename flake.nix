{
  description = "Paranoia Engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          zig
          zls

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
