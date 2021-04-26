#! /bin/zsh

#########################################################
#                                                       #
#    Simple zsh script for setting up and starting      #
#            basic enumeration for a CTF.               #
#                                                       #
#   Script will create folders for basic scans, then    #
#     start a new tmux session with the given name,     #
#         and start nmap and other basic scans.         #
#                                                       #
#              Written by Ari Weinberg                  #
#########################################################


if [ $# -lt 2 ] || [ $# -gt 3 ]
then
    echo "Invalid number of args!"
    echo "Usage: ctf_setup.sh NameOfCTF IPAddress [SudoPassword]"
    exit 1
fi

CTFNAME=$1
IP=$2
SUDOPASSWORD=$3

# Set up directory for ctf and create default folders and files
echo "Directory name is: $CTFNAME"
mkdir $CTFNAME
cd $CTFNAME
echo "Notes for $CTFNAME" > Notes.txt
mkdir Nmap
mkdir GoBuster
mkdir Nikto

# Create Tmux session
tmux new -d -s $CTFNAME -n Info
tmux setenv -t "$CTFNAME" IP $IP #Set IP variable for this tmxu session
tmux send-keys -t "$CTFNAME:Info" "export IP=$IP" ENTER "clear" ENTER #Export IP for initial Tmux window

#Run initial Nmap scan
tmux new-window -t "$CTFNAME" -n "Nmap"
tmux send-keys -t "$CTFNAME:Nmap" "sudo nmap -sC -sV -sS -O -T4 -oN Nmap/initial.txt $IP" ENTER "$SUDOPASSWORD" ENTER

#Spin up a webserver on 8080
tmux new-window -t "$CTFNAME" -n "webserver"
tmux send-keys -t "$CTFNAME:=webserver" "python3 -m http.server" ENTER

# Test to see if a webserver is running on port 80
# If yes, run dirb and nikto
curl -I --connect-timeout 3 $IP:80 > /dev/null 2>&1
if [ $? -eq 0 ] 
then
    tmux new-window -t "$CTFNAME" -n "GoBuster"
    tmux send-keys -t "$CTFNAME:GoBuster" "gobuster dir -w /usr/share/wordlists/dirb/common.txt -u http://$IP -t 50 | tee GoBuster/initial.txt" ENTER

    tmux new-window -t "$CTFNAME" -n "Nikto"
    tmux send-keys -t "$CTFNAME:Nikto" "nikto -host http://$IP | tee Nikto/initial.txt" ENTER
fi




#attach to tmux session
tmux attach -t $CTFNAME

