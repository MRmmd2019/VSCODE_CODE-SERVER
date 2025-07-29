#!/data/data/com.termux/files/usr/bin/bash

## ────────🎨 ANSI Colors ──────── ##
RED="$(printf '\033[31m')"    GREEN="$(printf '\033[32m')"   ORANGE="$(printf '\033[33m')"
BLUE="$(printf '\033[34m')"   MAGENTA="$(printf '\033[35m')" CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"  BLACK="$(printf '\033[30m')"

## ────────🔁 Reset Terminal ──────── ##
reset_color() {
  printf '\033[37m'
}

## ────────🛑 Exit Handlers ──────── ##
exit_on_signal_SIGINT() {
  printf "${RED}\n[!] Script Interrupted\n\n"; reset_color; exit 0;
}

exit_on_signal_SIGTERM() {
  printf "${RED}\n[!] Script Terminated\n\n"; reset_color; exit 0;
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## ────────📦 Base Setup ──────── ##
_pkgs=(curl fsmon git openssl-tool startup-notification termux-api vim make wget zsh librsvg nodejs yarn build-essential bash-completion binutils pkg-config python nodejs-lts gnupg ndk-sysroot)

setup_base() {
  echo -e "${RED}\n[*] Installing Visual Studio Code..."
  echo -e "${CYAN}\n[*] Updating Termux Base..."; reset_color
  pkg autoclean && pkg update && pkg upgrade -y

  echo -e "${CYAN}\n[*] Enabling Repositories..."; reset_color
  for repo in x11-repo unstable-repo game-repo science-repo tur-repo; do
    pkg install -y "$repo"
  done

  echo -e "${CYAN}\n[*] Final Repo Update..."; reset_color
  pkg update && pkg upgrade -y

  echo -e "${CYAN}\n[*] Installing Required Packages..."; reset_color
  for pkg in "${_pkgs[@]}"; do
    pkg install -y "$pkg"
    _check=$(pkg list-installed "$pkg" 2>/dev/null | tail -n 1 | cut -d/ -f1)
    if [[ "$_check" == "$pkg" ]]; then
      echo -e "${GREEN}[✔] $pkg installed"; reset_color
    else
      echo -e "${RED}[✘] Failed to install $pkg"; pkg upgrade -y; exit 1
    fi
  done
}

## ────────🐚 ZSH Setup ──────── ##
install_zsh() {
  echo -e "${ORANGE}\n[*] Installing ZSH..."; reset_color
  if [[ -f $PREFIX/bin/zsh ]]; then
    echo -e "${GREEN}[✔] ZSH already installed"; reset_color
  else
    pkg install -y zsh && echo -e "${GREEN}[✔] ZSH installed" || { echo -e "${RED}[✘] Failed to install ZSH"; exit 1; }
  fi
}

## ────────⚙️ OMZ & Config ──────── ##
setup_omz() {
  echo -e "${GREEN}\n[*] Setting up Oh-My-Zsh and Termux..."; reset_color

  # Backup configs
  for item in .oh-my-zsh .termux .zshrc; do
    [[ -e "$HOME/$item" ]] && mv -u "$HOME/$item" "$HOME/${item}.old"
  done

  git clone https://github.com/robbyrussell/oh-my-zsh.git --depth 1 $HOME/.oh-my-zsh
  cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template $HOME/.zshrc

  # ZSH Config
  sed -i 's/ZSH_THEME=.*/ZSH_THEME="agnoster"/g' $HOME/.zshrc
  echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.zshrc

  # Create theme file
  mkdir -p $HOME/.oh-my-zsh/custom/themes/
  cat > $HOME/.oh-my-zsh/custom/themes/aditya.zsh-theme << 'EOF'
# Aditya Theme - Minimal Git Prompt
PROMPT='%{$fg_bold[green]%}➜ %{$fg[cyan]%}%c %{$reset_color%}$(git_prompt_info)'
EOF

  echo 'ZSH_THEME="aditya"' >> $HOME/.zshrc

  # Useful aliases
  cat >> $HOME/.zshrc << EOF

# Aliases
alias l='ls -lh'
alias ll='ls -lah'
alias :q='exit'
alias p='pwd'
EOF

  # Termux extra keys
  mkdir -p "$HOME/.termux"
  cat > "$HOME/.termux/termux.properties" << EOF
extra-keys = [
 ['ESC','|','/','~','HOME','UP','END'],
 ['CTRL','TAB','=','-','LEFT','DOWN','RIGHT']
]
EOF

  chsh -s zsh
  termux-reload-settings
}

## ────────🧩 Install ADB ──────── ##
install_adb() {
  echo -e "${GREEN}\n[*] Installing ADB..."; reset_color
  curl -sL https://github.com/MasterDevX/Termux-ADB/raw/master/InstallTools.sh -o InstallTools.sh
  bash InstallTools.sh && rm InstallTools.sh
}

## ────────📦 VSC Repository ──────── ##
install_vsc_repo() {
  echo -e "${GREEN}\n[*] Adding VSC Repository..."; reset_color

  wget https://packages.microsoft.com/keys/microsoft.asc -q
  apt-key add microsoft.asc
  gpg --dearmor microsoft.asc > packages.microsoft.gpg
  cp -f packages.microsoft.gpg $PREFIX/etc/apt/trusted.gpg.d/
  rm microsoft.asc packages.microsoft.gpg

  wget https://its-pointless.github.io/setup-pointless-repo.sh -q
  chmod +x setup-pointless-repo.sh && bash setup-pointless-repo.sh && rm setup-pointless-repo.sh
}

## ────────🧠 VSC Configuration ──────── ##
configure_vsc() {
  echo -e "${GREEN}\n[*] Installing code-server..."; reset_color
  pkg install -y code-server

  echo -e "${CYAN}\n[*] Applying config..."; reset_color
  wget -q https://raw.githubusercontent.com/afonsoft/termux-vsc/main/config.yaml
  mkdir -p ~/.config/code-server/
  cp config.yaml ~/.config/code-server/config.yaml
}

## ────────💻 DotNet & Mono ──────── ##
setup_net() {
  echo -e "${GREEN}[*] Setting up .NET & Mono..."; reset_color
  pkg install -y mono
  wget -q https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh
  chmod +x dotnet-install.sh
  ./dotnet-install.sh -c LTS
  ./dotnet-install.sh -c STS
  echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
  echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> ~/.bashrc
}

## ────────✅ Finalization ──────── ##
setup_finaly() {
  echo -e "${ORANGE}\n[*] Setup Complete!"
  echo -e "${GREEN}[✔] Default Port: ${RED}8091"
  echo -e "${GREEN}[✔] Default Password: ${RED}123qwe"
  echo -e "${GREEN}Run ${RED}code-server${GREEN} to start VSCode"
  reset_color
}

## ────────🚀 Main Function ──────── ##
install_vsc() {
  clear
  setup_base
  install_zsh
  setup_omz
  install_vsc_repo
  setup_net
  install_adb
  configure_vsc
  setup_finaly
}

## Execute Main
install_vsc
