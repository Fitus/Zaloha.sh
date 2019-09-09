#!/bin/bash

echo "DISPLAYING STATISTICS FROM THE RUN OF ZALOHA"
echo
echo "Objects compared .................. $(awk 'END { print NR }' test_backup/.Zaloha_metadata/370_union_s_diff.csv)"
echo "Removals from 'test_backup' ....... $(awk 'END { print NR }' test_backup/.Zaloha_metadata/510_exec1.csv)"
echo "Copies to 'test_backup' ........... $(awk 'END { print NR }' test_backup/.Zaloha_metadata/520_exec2.csv)"
echo "Objects in synchronized state ..... $(awk 'END { print NR }' test_backup/.Zaloha_metadata/505_target.csv)"
