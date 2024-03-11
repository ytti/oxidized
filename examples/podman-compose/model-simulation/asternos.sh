# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Display a MOTD
cat << EOF
This is the welcome message of this device
it is muliline
End of the MOTD
EOF

function show() {
  if [ "$*" == "version" ]; then
    echo "Version 1.2.3"
  elif [ "$*" == "runningconfiguration all" ]; then
          cat << EOF
! begin of the configuration
! this is the running config
!
I have no idea how a configuration in asternos looks like ;-)
!
! End of the Configuration
EOF
  else
    echo "command 'show $*' not implemented"
  fi
}

PS1="asternos$"

