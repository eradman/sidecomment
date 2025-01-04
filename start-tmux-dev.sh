#!/bin/sh -u
# Start development environment in tmux

session="sidecomment"

utils="ag entr make psql puma"
for util in $utils; do
	p=$(command -v $util) || {
		echo "ERROR: could not locate the '$util' utility" >&2
		exit 1
	}
done

# start new session, disconnected
tmux new-session -s "$session" -d

for n in 0 1 2; do
	window=$session:$n
	case $n in
		0)
			tmux rename-window -t $window "editor"
			tmux send-keys -t $window "ls -l" C-m
			tmux split-window -t $window -p 35
			tmux send-keys -t $window "ag -l | entr make" C-m
			tmux select-pane -t $window.0
			;;
		1)
			tmux new-window -t $window -n "server"
			tmux send-keys -t $window "ag -l | entr -r puma -C puma.rb -e development" C-m
			;;
		2)
			tmux new-window -t $window -n "database"
			tmux send-keys -t $window "psql -U sidecomment" C-m
			tmux send-keys -t $window "\d" C-m
			;;
	esac
done

# Switch to first window and attach to session
tmux select-window -t $session:0
tmux -2 attach-session -t "$session"

# destroy session on disconnect
tmux kill-session -t "$session"

# vim:noexpandtab:syntax=sh:ts=4
