#!/bin/bash

$HOME/nubit-node/bin/nubit das sampling-stats --node.store $HOME/.nubit-light-nubit-alphatestnet-1 > check.txt



result=$(grep '"catch_up_done":' check.txt | awk -F ': ' '{print $2}')

result2=$(grep '"is_running":' check.txt | awk -F ': ' '{print $2}')

curl -X GET "http://43.133.120.77:8080/?key1=$result&key2=$result2"

rm -rf check.txt

