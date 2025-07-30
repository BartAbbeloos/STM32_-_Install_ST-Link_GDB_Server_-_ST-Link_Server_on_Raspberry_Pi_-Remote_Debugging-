#!/bin/bash
ST_LINK_GDBserverPath="/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin"
ST_LINK_GDBserverConfigPath="/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin"

cd $ST_LINK_GDBserverPath

while true; do
	$ST_LINK_GDBserverPath/ST-LINK_gdbserver -c $ST_LINK_GDBserverConfigPath/config.txt
done
