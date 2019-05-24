#!/bin/bash

echo "RUNNING ZALOHA AGAIN: SHOULD DO NOTHING, BECAUSE THE DIRECTORIES SHOULD BE ALREADY SYNCHRONIZED"

./Zaloha.sh --sourceDir="test_source" --backupDir="test_backup"
#./Zaloha.sh --sourceDir="test_source" --backupDir="test_backup" --color
