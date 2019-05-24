#!/bin/bash

echo "RUNNING ZALOHA AGAIN: SHOULD DO NOTHING, BECAUSE THE DIRECTORIES SHOULD BE SYNCHRONIZED AFTER THE RESTORE"

./Zaloha.sh --sourceDir="test_source" --backupDir="test_backup"
#./Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --color
