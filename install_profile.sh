#!/bin/bash

if [[ -n "$1" ]] ; then
	PROFILEDIR=$1
else
	PROFILEDIR=$HOME/git/shell_profile
fi

test -d $PROFILEDIR || (echo "Provide the location behind this script." && exit 1)

# Making sure ~/git exists
test -d $HOME/git/ || mkdir $HOME/git

SUB=user
if [[ $(id -u) == 0 ]]; then
	SUB=root
fi

#### Bash environment ####
echo "Creating symlinks for BASH (alias, profile, bashrc)"
if [ ! -L $HOME/.shell_aliases ]; then
	ln -sf $PROFILEDIR/$SUB/shell_aliases $HOME/.shell_aliases 
fi
if [ ! -L $HOME/.bash_profile ]; then
	ln -sf $PROFILEDIR/$SUB/bash_profile $HOME/.bash_profile 
fi
if [ ! -L $HOME/.bashrc ]; then
	ln -sf $PROFILEDIR/$SUB/bashrc $HOME/.bashrc 
fi
# Cleanup old symlink
#if [ -L $HOME/.bash_aliases ]; then
#	rm $HOME/.bash_aliases 
#fi

#### VIM environment ####
echo "Creating the VIM environment"
test -L $HOME/.vim && rm $HOME/.vim
test -d $HOME/.vim || mkdir $HOME/.vim
if [ ! -d $HOME/.vim/ftdetect ]; then rm $HOME/.vim/ftdetect; mkdir $HOME/.vim/ftdetect; fi
if [ ! -d $HOME/.vim/syntax ]; then rm $HOME/.vim/syntax; mkdir $HOME/.vim/syntax; fi
ln -sf $PROFILEDIR/vimrc $HOME/.vimrc
# VIM bundle
if [ ! -d $HOME/.vim/bundle ] ; then
	git clone https://github.com/gmarik/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
fi

### User specific
if [[ ! $(id -u) == 0 ]]; then
	### Openhab-vim
	if [ ! -d $HOME/git/openhab-vim ] ; then
		git clone git@github.com:bambam82/openhab-vim.git $HOME/git/openhab-vim
	fi
	if [ ! -L $HOME/.vim/syntax/openhab.vim ]; then
		ln -sf $HOME/git/openhab-vim/syntax/openhab.vim $HOME/.vim/syntax/openhab.vim
	fi
	if [ ! -L $HOME/.vim/ftdetect/openhab.vim ]; then
		ln -sf $HOME/git/openhab-vim/ftdetect/openhab.vim $HOME/.vim/ftdetect/openhab.vim
	fi

	### Python environment
	if [ ! -e $HOME/.pypirc ] ; then 
		echo -e "\nIn case you wish to create the ~/.pypirc config file for pypi, provide a username and then a password. If the username is empty, nothing is generated."
		echo "Username:"
		read USERNAME
		if [ -n "$USERNAME" ] ; then
			echo "Password:"
			read -s -r PASSWORD
		fi
		if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ] ; then
			cat > $HOME/.pypirc << EOF
[distutils]
index-servers=pypi

[pypi]
repository = https://pypi.python.org/pypi
username = $USERNAME
password = $PASSWORD
EOF
		chmod 600 $HOME/.pypirc
		fi
	fi
fi

### root specific
if [[ $(id -u) == 0 ]]; then
	FILE="$PROFILEDIR/etc/udev/rules.d/99-yubikeys.rules"
	test -f $FILE && ln -sf $FILE /etc/udev/rules.d/99-yubikeys.rules
	FILE="$PROFILEDIR/etc/udev/rules.d/51-android.rules"
	test -f $FILE && ln -sf $FILE /etc/udev/rules.d/51-android.rules
	#
	echo "Creating symlink for sudoers"
	if [ -d /etc/sudoers.d ]; then
		ln $PROFILEDIR/etc/sudoers.d/global_sudo /etc/sudoers.d/globalsudo
		chmod 440 /etc/sudoers.d/globalsudo
	fi
	#
	# Aptitude
	if [ ! -d $HOME/.aptitude ]; then
			mkdir $HOME/.aptitude
	fi
	FILE="$PROFILEDIR/$SUB/aptitude-config"
	test -f $FILE && ln -sf $FILE $HOME/.aptitude/config
fi

#### Other environment ####
echo "Creating symlinks for screenrc, email forward"
ln -sf $PROFILEDIR/screenrc $HOME/.screenrc

if [ ! -e $HOME/.forward ] ; then 
	echo "Do you want to create a .forward file. If so type your email, else enter"
	read EMAIL
	if [ -n "$EMAIL" ] ; then 
		if [ -L $HOME/.forward ]; then 
			rm $HOME/.forward
		fi
		echo $EMAIL > $HOME/.forward 
	fi
fi

echo "Creating zsh environment"
if [ ! -d $HOME/git/oh-my-zsh-custom ] ; then
	git clone git@github.com:bambam82/oh-my-zsh-custom.git $HOME/git/oh-my-zsh-custom
fi
if [ ! -L $HOME/.zshrc ]; then
	ln -sf $PROFILEDIR/$SUB/zshrc $HOME/.zshrc 
fi
if [ -d $HOME/.oh-my-zsh ] && [ ! -L $HOME/.oh-my-zsh/custom ] ; then
	DIR="$HOME/git/oh-my-zsh-custom"
	for x in $(ls -1 $DIR); do
		# Variable path due to VM's
		#ln -sf ../../git/oh-my-zsh-custom/$x $HOME/.oh-my-zsh/custom/
		ln -sf $DIR/$x $HOME/.oh-my-zsh/custom/
	done
fi
# Add an git pull to crontab if it doesn't exist yet
# if [[ -z $(crontab -l | grep "oh-my-zsh" | grep "git pull") ]] ; then 
#	 line="@reboot cd $HOME/.oh-my-zsh ; git pull > /dev/null 2>&1"
#	 line2="0 6 1 * * cd $HOME/.oh-my-zsh ; git pull > /dev/null 2>&1"
#	 (crontab -l; echo "$line" ; echo "$line2") | crontab -
# fi

echo "Downloading other directories"
echo "	Network scripts"
if [ ! -d $HOME/git/network_scripts ] ; then
	git clone git@github.com:bambam82/network_scripts.git $HOME/git/network_scripts
fi

echo "Git settings"
git config --global user.name "`whoami`@`hostname`"
test -n $EMAIL && git config --global user.email $EMAIL
git config --global core.editor vim
git config --global push.default simple
git config --global core.excludesfile .gitignore
git config --global branch.autosetuprebase always
git config --global core.whitespace warn
git config --global core.autocrlf input
git config --global core.filemode true

echo ""
echo "you might want to add the following line to your crontab."
echo "	only if no password is required"
echo "0 5 * * *	git pull $PROFILEDIR > /dev/null 2>&1"
