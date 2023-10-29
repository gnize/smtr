{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    poetry2nix = {
      url = "github:nix-community/poetry2nix?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    frag = {
      url = "path:/home/matt/src/gnize/frag";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gnize = {
      url = "path:/home/matt/src/gnize/gnize";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    frag-py = {
      url = "path:/home/matt/src/gnize/frag-py";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gnize-py = {
      url = "path:/home/matt/src/gnize/gnize-py";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, pre-commit-hooks, frag, gnize }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication mkPoetryEnv;
        python = pkgs.python311;
        pythonEnv = pkgs.poetry2nix.mkPoetryEnv {
          pyproject = ./pyproject.toml;
          poetrylock = ./poetry.lock;
        };

        pre-commit = pre-commit-hooks.lib.${system};
        pre-commit-checks = pre-commit.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            black.enable = true;
            ruff.enable = true;
          };
        };
        pre-commit-shell-hook = pre-commit-checks.shellHook;

        frag-pkg = frag.packages.${system}.default;
        gnize-pkg = gnize.packages.${system}.default;

      in
      {
        checks = pre-commit-checks;

        packages = {
          myapp = mkPoetryApplication { projectDir = self; };
          default = self.packages.${system}.myapp;
        };

        devShells.default = pkgs.mkShell rec {
          shellHook = ''
            ${pre-commit-shell-hook}
            echo hi
          '';
          packages = [
            pkgs.poetry
            pythonEnv
            frag-pkg
            gnize-pkg
          ];
        };
      });
}
