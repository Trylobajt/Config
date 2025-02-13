#!/bin/bash

Red='\033[0;31m'
Green='\033[0;32m'
LingtBlue='\033[1;34m'
NoColor='\033[0m'

BASEDIR=$(dirname "$0")

# test if zstd is not installed
if [ ! -x /usr/bin/zstd ]; then
    echo "installing zstd"

    # Package name
    zstd_package=zstd-1.5.6-1-x86_64
	
	# Download zstd
    url="https://mirror.msys2.org/msys/x86_64/$zstd_package.pkg.tar.zst"
    echo -e "$Green" "downloading $url" "$NoColor"  
    curl -L $url -o ~/Downloads/$zstd_package.pkg.tar.zst;

    # convert zstd package to xz format
	echo -e "$Green" "convert tar.zst -> tar.xz" "$NoColor"  
    $BASEDIR/zstd.exe -d ~/Downloads/$zstd_package.pkg.tar.zst --stdout | xz -z > ~/Downloads/$zstd_package.pkg.tar.xz
    rm ~/Downloads/$zstd_package.pkg.tar.zst

    # install zstd
    cd /
	echo -e "$Green" "unpack" "$NoColor"  
    tar x --xz -vf ~/Downloads/$zstd_package.pkg.tar.xz
    rm ~/Downloads/$zstd_package.pkg.tar.xz

    # test if installation was successful
    if [ ! -x /usr/bin/zstd ]; then
        echo "zstd installation failed"
        exit 1
    fi
fi

pacman_packages="pacman-6.1.0-10-x86_64 pacman-mirrors-20241217-1-any msys2-keyring-1~20241007-1-any"
other_packages="gettext-0.22.4-1-x86_64 gawk-5.3.1-1-x86_64"

url="https://raw.githubusercontent.com/msys2/MSYS2-packages/master/pacman/pacman.conf"
echo -e "$Green" "downloading $url" "$NoColor"  
curl -L $url -o /etc/pacman.conf
for f in $pacman_packages $other_packages; do
  url="https://mirror.msys2.org/msys/x86_64/$f.pkg.tar.zst"
  echo -e "$Green" "downloading $url" "$NoColor"    
  curl -L $url -o ~/Downloads/$f.pkg.tar.zst;
done
  
# install pacman
echo "Install Pacman"
cd /
for f in $pacman_packages $other_packages; do
  echo -e "$LingtBlue----------------------------------------------------$NoColor"
  echo -e "$LingtBlue Extracting: $f $NoColor"
  echo -e "$LingtBlue----------------------------------------------------$NoColor"
  tar x --zstd -f ~/Downloads/$f.pkg.tar.zst || exit 2;
  rm ~/Downloads/$f.pkg.tar.zst  
done

echo "Initialize pacman database"

mkdir -p /var/lib/pacman || exit 3
pacman-key --init || exit 4
pacman-key --populate msys2 || exit 5
pacman -Syu --overwrite \* || exit 6

URL=https://github.com/git-for-windows/git-sdk-64/raw/main
# count number of lines
lines=$(wc -l /etc/package-versions.txt | cut -d' ' -f1)
line=1
#cat /etc/package-versions.txt | sed 's/ /=/g' | pacman -S -
cat /etc/package-versions.txt | while read p v; do
  d=/var/lib/pacman/local/$p-$v;
  echo -e "$Green($line/$lines)$LingtBlue $d $NoColor";
  mkdir -p $d;
  #test if files not exist
  if [ ! -f $d/desc ] || [ ! -f $d/files ] || [ ! -f $d/install ] || [ ! -f $d/mtree ];
  then
    echo -ne "downloading..."
    curl -sSL --parallel --parallel-immediate --parallel-max 5 \
      "$URL$d/desc" -o $d/desc \
      "$URL$d/files" -o $d/files \
      "$URL$d/install" -o $d/install \
      "$URL$d/mtree" -o $d/mtree || exit 7;
	echo -ne "\r"
  fi

#  for f in desc files install mtree; do
#    echo -e " $Red->$NoColor $URL$d/$f"
#    curl -sSL "$URL$d/$f" -o $d/$f;
#  done;
  line=$((line+1))
done

pacman-key --refresh-keys || exit 8
pacman -S --overwrite \* zstd pacman pacman-mirrors msys2-keyring gettext gawk

pacman -S zsh \
          $MINGW_PACKAGE_PREFIX-fzf \
          mc unrar zip p7zip libssh2 \
          rsync \
          procps-ng \
          man \
          $MINGW_PACKAGE_PREFIX-python-tldr
          # htop

tldr --print-completion zsh | tee /usr/share/zsh/site-functions/_tldr



# tmux
# https://github.com/microsoft/terminal/issues/5132#issuecomment-1012855493
# https://dev.to/andrenbrandao/terminal-setup-with-zsh-tmux-dracula-theme-48lm
# script -c tmux /dev/null
pacman -S tmux util-linux

# OhMyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
pacman -S mingw-w64-x86_64-fzf

# install omz plugins
# add plugins=(... zsh-autosuggestions zsh-syntax-highlighting) in .zshrc
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-autocomplete
git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
# Add it to FPATH in your .zshrc by adding the following line before source "$ZSH/oh-my-zsh.sh":
# fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src


# reinstall all packages
# pacman -S $(pacman -Qnq | grep -vE "mingw-w64-x86_64-git-lfs|perl-TermReadKey")
