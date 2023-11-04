@echo off
:: RDP connection without password prompt ------------
:: %1 = hostname
:: %2 = port
:: %3 = username
:: %4 = password
:: ---------------------------------------------------
cmdkey /add:"%~1" /user:"%~3" /pass:"%~4"
start /wait mstsc /v:"%~1:%~2"
cmdkey /delete:"%~1"
exit