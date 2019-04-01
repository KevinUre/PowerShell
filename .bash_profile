
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion # this loads bash_completion

bind -f ~/.inputrc

alias dir='ls -Ap'
# PS1='\w\e[0;33m$(__git_ps1 "(%s)")\e[m\$ '
# export GIT_PS1_SHOWDIRTYSTATE=false
# export GIT_PS1_SHOWUNTRACKEDFILES=false
# if [[ "${#dirsarray[@]}"" > "1"]]; then
#			nextdir=`dirs +1 | perl -pe "s/\/Users\/kevinure/~/g" | perl -pe "s/(?<=\/)(.).*?(?=\/)/$1/g"`
#			echo -n "[`echo $nextdir`]"
#		fi
# temp=`dirs +1 | perl -pe 's/(?<=\/)(.).*?(?=\/)/$1/g'`
# $(
# 	if $showdirstack; then
# 		dirsarray=(`dirs | perl -pe "s#(?:(?<=\s)|(?<=^))(.*?)(?:(?=\s~)|(?=\s\/)|(?=$))#$1\n#g" | awk "{$1=$1};1")
# 	fi
# )\
rotatedirs() {
	if $showdirstack; then
 		dirsarray=(`dirs | perl -pe 's#(?:(?<=\s)|(?<=^))(.*?)(?:(?=\s~)|(?=\s\/)|(?=$))#$1\n#g' | awk "{$1=$1};1" | perl -pe 's#\s#\\\\\s#g'`)
 	fi
	if [[ "${#dirsarray[@]}" > "1"]]; then
		stackheight=${#dirsarray[@]}
		for ((i=1;i<=$stackheight;i++)); 
		do 
			popd
		done
		pushd "${dirsarray[0]}"
		for ((i=$stackheight;i>1;i--)); 
		do 
			pushd "${dirsarray[$($i-1)]}"
		done
	fi

}

export showdirstack=true
PS1='\
$(
	if dirs +1 &> /dev/null ; then
		temp=`dirs +1 | perl -pe "s/(?<=\/)(?<letter>.).*?(?=\/)/$+{letter}/g"`
		echo -n "\[\e[0;90m\][$temp]\[\e[m\]"
	fi
)\
$(
	if [[ "$(pwd)" == "$HOME" ]]; then
		echo -n "\[\e[0;93m\]$(echo "~")\[\e[m\]"
	else
		parentdir=$(dirname "`pwd`")
		parentdir=${parentdir/$HOME/\~}
		echo -n "$parentdir"
		if [[ "$parentdir" != "/" ]]; then
			echo -n "/"
		fi
		echo -n "\[\e[0;93m\]$(echo ${PWD##*/})\[\e[m\]"
	fi	
)\
$(
	statuserror="$(git status 2>&1 > /dev/null)"
	if [[ "$statuserror" == "" ]]; then
		echo -n "\[\e[0;36m\]($(__git_ps1 "%s")\[\e[m\]"

		status=$(git status --porcelain)

		newfilesunstaged=$(echo "$status" | awk "/^\?\? / {print $2}" | wc -l ;)
	
		existingmodified=$(echo "$status" | awk "/^.M / {print $2}" | wc -l ;) 
		existingdeleted=$(echo "$status" | awk "/^.D / {print $2}" | wc -l ;)
		modified=$((existingmodified + existingdeleted))

		existingstaged=$(echo "$status" | awk "/^M./ {print $2}" | wc -l ;)
		newfilesstaged=$(echo "$status" | awk "/^A./ {print $2}" | wc -l ;)
		deletesstaged=$(echo "$status" | awk "/^D./ {print $2}" | wc -l ;)
		staged=$((newfilesstaged + existingstaged + deletesstaged))

		mergeconflicts=$(echo "$status" | awk "/^UU / {print $2}" | wc -l ;)

		remoteoriginifgreaterthanzero=$(git remote -v | awk "/^origin/ {print $2}" | wc -l ;)
		if ((remoteoriginifgreaterthanzero > 0)); then
			branchname=$(git rev-parse --abbrev-ref HEAD)
			rp="$branchname[[:blank:]]*[0-9a-zA-Z]*..origin"
			awkc="/$rp/"
			trackedremotelyifgreaterthanzero=$(git branch -vv | awk $awkc | wc -l ;)
			if ((trackedremotelyifgreaterthanzero > 0)); then
				changearray=($(git rev-list --left-right --count origin/$branchname...$branchname))
				originchanges=${changearray[0]}
				localchanges=${changearray[1]}
				
				if ((originchanges > 0)); then
					echo -n " \[\e[1;91m\]↓\[\e[0;91m\]$(echo $originchanges)\[\e[m\]"
				fi 
				if ((localchanges > 0)); then
					echo -n " \[\e[1;32m\]↑\[\e[0;32m\]$(echo $localchanges)\[\e[m\]"
				fi 
			fi
		fi
		
		if ((mergeconflicts > 0)); then
			echo -n " \[\e[1;41;97m\]!$(echo $mergeconflicts)\[\e[m\]"
		fi
		if ((newfilesunstaged > 0)); then
			echo -n " \[\e[0;31m\]+$(echo $newfilesunstaged)\[\e[m\]"
		fi
		if ((modified > 0)); then
			echo -n " \[\e[0;33m\]~$(echo $modified)\[\e[m\]"
		fi
		if ((staged > 0)); then
			echo -n " \[\e[1;32m\]✓\[\e[0;32m\]$(echo $staged)\[\e[m\]"
		fi

		echo -n "\[\e[0;36m\])\[\e[m\]"
		
		# git fetch --all 2>&1 > /dev/null &
	fi
)\
\$ '

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"

search() {
	grep --exclude-dir={node_modules,dist,coverage} --color=auto -Rnis "$1" *
}

nuke() {
	rm -rf "$1"
}



export LOCAL_ATTUNITY_DIRECTORY="/Users/kevinure/Projects/Attunity/"
export REST_API_LOCAL_DB_PASSWORD="Ed6780ba*"
