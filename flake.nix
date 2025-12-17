{
  description = "Qubes SDP - Software Development Platform for Qubes OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Development shell with all dependencies
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core tools
            bash
            coreutils
            findutils
            gnugrep
            gnused
            gawk

            # Build tools
            gnumake
            just

            # Testing tools
            shellcheck
            shfmt

            # Documentation tools
            python3
            pandoc

            # Git and utilities
            git
            wget
            curl
          ];

          shellHook = ''
            echo "Qubes SDP Development Environment"
            echo "=================================="
            echo ""
            echo "Available commands:"
            echo "  just --list       - Show all just recipes"
            echo "  just test         - Run all tests"
            echo "  just lint         - Lint shell scripts"
            echo "  just ci           - Run CI checks"
            echo ""
            echo "NOTE: This environment is for development/testing only."
            echo "Actual Qubes setup must be run in dom0 on Qubes OS."
          '';
        };

        # Package definition (for installation)
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "qubes-sdp";
          version = "1.0.0";

          src = self;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/{bin,share/qubes-sdp,etc/qubes-sdp}

            # Install scripts
            cp qubes-setup.sh $out/bin/qubes-setup
            cp qubes-setup-advanced.sh $out/bin/qubes-setup-advanced
            chmod +x $out/bin/*

            # Install tools
            cp -r tools/* $out/bin/
            chmod +x $out/bin/*.sh

            # Install configuration examples
            cp -r examples $out/etc/qubes-sdp/
            cp qubes-config.conf $out/etc/qubes-sdp/qubes-config.conf.example

            # Install documentation
            cp -r wiki $out/share/qubes-sdp/
            cp -r docs $out/share/qubes-sdp/ || true
            cp README.md QUICKSTART.md SECURITY.md $out/share/qubes-sdp/

            # Install Salt states
            cp -r qubes-salt $out/share/qubes-sdp/

            # Install Makefile
            cp Makefile.qubes $out/share/qubes-sdp/
          '';

          meta = with pkgs.lib; {
            description = "Automated Qubes OS configuration system";
            longDescription = ''
              Qubes SDP automates the creation and configuration of a secure
              Qubes OS environment optimized for various workflows including
              journalism, software development, research, and security testing.

              Features:
              - One-command setup for complete qube topology
              - Multiple deployment methods (bash, Salt Stack, interactive)
              - Topology presets for common workflows
              - Comprehensive security features (air-gapped vault, firewalls)
              - Complete documentation and tooling
            '';
            homepage = "https://github.com/hyperpolymath/qubes-sdp";
            license = with licenses; [ mit ]; # Dual MIT + Palimpsest v0.8
            maintainers = [ ];
            platforms = platforms.linux;
            mainProgram = "qubes-setup";
          };
        };

        # Checks (run during 'nix flake check')
        checks = {
          # Syntax check all shell scripts
          syntax-check = pkgs.stdenv.mkDerivation {
            name = "qubes-sdp-syntax-check";
            src = self;
            buildInputs = [ pkgs.bash ];
            doCheck = true;
            checkPhase = ''
              find . -name "*.sh" -type f -exec bash -n {} \;
              touch $out
            '';
          };

          # Run shellcheck if available
          shellcheck = pkgs.stdenv.mkDerivation {
            name = "qubes-sdp-shellcheck";
            src = self;
            buildInputs = [ pkgs.shellcheck ];
            doCheck = true;
            checkPhase = ''
              find . -name "*.sh" -type f -exec shellcheck {} +
              touch $out
            '';
          };

          # Verify required files exist
          files-check = pkgs.stdenv.mkDerivation {
            name = "qubes-sdp-files-check";
            src = self;
            buildInputs = [ pkgs.bash ];
            doCheck = true;
            checkPhase = ''
              # Check required files
              test -f README.md || (echo "Missing README.md"; exit 1)
              test -f LICENSE.txt || (echo "Missing LICENSE.txt"; exit 1)
              test -f SECURITY.md || (echo "Missing SECURITY.md"; exit 1)
              test -f CODE_OF_CONDUCT.md || (echo "Missing CODE_OF_CONDUCT.md"; exit 1)
              test -f CONTRIBUTING.md || (echo "Missing CONTRIBUTING.md"; exit 1)
              test -f MAINTAINERS.md || (echo "Missing MAINTAINERS.md"; exit 1)
              test -f CHANGELOG.md || (echo "Missing CHANGELOG.md"; exit 1)

              # Check .well-known
              test -f .well-known/security.txt || (echo "Missing security.txt"; exit 1)
              test -f .well-known/ai.txt || (echo "Missing ai.txt"; exit 1)
              test -f .well-known/humans.txt || (echo "Missing humans.txt"; exit 1)

              # Check scripts
              test -x qubes-setup.sh || (echo "qubes-setup.sh not executable"; exit 1)
              test -x qubes-setup-advanced.sh || (echo "qubes-setup-advanced.sh not executable"; exit 1)

              touch $out
            '';
          };
        };

        # Formatter (for 'nix fmt')
        formatter = pkgs.nixpkgs-fmt;

        # Apps (for 'nix run')
        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/qubes-setup";
          };

          setup-advanced = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/qubes-setup-advanced";
          };

          status = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/qubes-status.sh";
          };

          dashboard = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/qubes-dashboard.sh";
          };
        };
      }
    );
}
