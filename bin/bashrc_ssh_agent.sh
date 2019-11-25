# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# User specific aliases and functions

case $- in
*i*)    # interactive shell
	if [[ -f ~/.ssh-agt-cfg ]]
	then
        	pid=`grep PID ~/.ssh-agt-cfg | tr -d '"'| cut -f 2 -d '='`
        	# check if SSH_AGENT_PID from config file point to an existing agent process
        	ps -p $pid > /dev/null
        	if [[ $? -ne 0 ]]               # dead config found
        	then
                	# need to launch new ssh-agent instance and save the config
                	eval $(ssh-agent -s)
                	ssh-add ~/.ssh/id_ecdsa
                	ssh-add ~/.ssh/id_rsa
                	echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK > ~/.ssh-agt-cfg
                	echo SSH_AGENT_PID=$SSH_AGENT_PID >> ~/.ssh-agt-cfg
        	else
                	source ~/.ssh-agt-cfg
                	export SSH_AUTH_SOCK
                	export SSH_AGENT_PID
                	ssh-add -l
        	fi
	else
        	# need to launch new ssh-agent instance and save the config
       		eval $(ssh-agent -s)
        	ssh-add ~/.ssh/id_ecdsa
        	ssh-add ~/.ssh/id_rsa
        	echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK > ~/.ssh-agt-cfg
        	echo SSH_AGENT_PID=$SSH_AGENT_PID >> ~/.ssh-agt-cfg
	fi
;;
*)      # non-interactive shell
	return
;;
esac
