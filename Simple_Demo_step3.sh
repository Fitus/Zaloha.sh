#!/bin/bash

echo "DISPLAYING STATISTICS FROM THE RUN OF ZALOHA (OPTIONAL)"

echo "Objects removed from 'test_backup' ..... $(awk 'END { print NR }' test_backup/.Zaloha_metadata/510_exec1.csv)"
echo "Objects copied to 'test_backup' ........ $(awk 'END { print NR }' test_backup/.Zaloha_metadata/520_exec2.csv)"
echo "Objects in restore scripts ............. $(awk 'END { print NR }' test_backup/.Zaloha_metadata/505_target.csv)"
