#!/bin/sh

set -e

exec >/dev/null 2>&1

die() {
    exit 1
}

[ "$(id -u)" -eq 0 ] || die

CLEANUP_DIR="/tmp/void-fonts-setup"
trap 'rm -rf "$CLEANUP_DIR"' EXIT INT TERM

git_clone_or_pull() {
    repo="$1"
    dest="$2"
    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull --ff-only || die
    else
        git clone "$repo" "$dest" || die
    fi
}

download_verified() {
    url="$1"
    dest="$2"
    min_size="$3"
    curl -fsSL -o "$dest" "$url" || die
    actual_size=$(stat -c%s "$dest" || stat -f%z "$dest")
    [ "$actual_size" -ge "$min_size" ] || die
}

sudo xbps-install -Syy || die
sudo xbps-install -y \
    glibc libgcc libstdc++ libgcc-devel libstdc++-devel \
    ddcutil ddcutil-devel brightnessctl NetworkManager lm_sensors \
    aubio aubio-devel pipewire pipewire-devel \
    libqalculate libqalculate-devel power-profiles-daemon \
    nerd-fonts curl unzip wget git base-devel python3 \
    qt6-base qt6-base-devel qt6-declarative qt6-declarative-devel \
    qt6-imageformats qt6-shadertools qt6-wayland \
    swappy fish bash cmake meson ninja \
    libx11-devel libxrandr-devel libxinerama-devel libxcursor-devel \
    quickshell \
    libnotify grim sassc wl-clipboard slurp gpu-screen-recorder glib glib-devel cliphist fuzzel \
    python3-build python3-installer python3-hatch python3-hatch-vcs || die

mkdir -p "$CLEANUP_DIR" || die
cd "$CLEANUP_DIR" || die

git_clone_or_pull https://github.com/soramanew/m3shapes.git qt6-m3shapes
cd qt6-m3shapes || die
rm -rf build
mkdir build || die
cd build || die

cmake .. -G Ninja -DCMAKE_INSTALL_PREFIX=/usr || die
ninja || die
sudo ninja install || die
cd "$CLEANUP_DIR" || die

download_verified "https://github.com/google/fonts/raw/main/ofl/rubik/Rubik-VariableFont_wght.ttf" Rubik-VariableFont_wght.ttf 50000
download_verified "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" MaterialSymbolsRounded.ttf 50000

sudo mkdir -p /usr/share/fonts/TTF/Rubik || die
sudo mkdir -p /usr/share/fonts/TTF/MaterialSymbols || die
sudo cp Rubik-VariableFont_wght.ttf /usr/share/fonts/TTF/Rubik/ || die
sudo cp MaterialSymbolsRounded.ttf /usr/share/fonts/TTF/MaterialSymbols/ || die
sudo chmod 644 /usr/share/fonts/TTF/Rubik/*.ttf /usr/share/fonts/TTF/MaterialSymbols/*.ttf || die

sudo fc-cache -f || die

rm -rf "$CLEANUP_DIR"

mkdir -p ~/.local/pkgs/caelestia || die
cd ~/.local/pkgs/caelestia || die

git_clone_or_pull https://github.com/caelestia-dots/cli.git caelestia-cli
cd caelestia-cli || die
rm -rf dist build *.egg-info
python3 -m build --wheel || die
sudo python3 -m installer dist/*.whl || die

sudo mkdir -p /usr/share/fish/vendor_completions.d || die
sudo cp completions/caelestia.fish /usr/share/fish/vendor_completions.d/caelestia.fish || die

cd ~/.local/pkgs/caelestia || die

git_clone_or_pull https://github.com/caelestia-dots/shell.git caelestia-shell
cd caelestia-shell || die
rm -rf build
cmake -B build -G Ninja || die
cmake --build build || die
sudo cmake --install build || die

exit 0
