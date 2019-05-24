#!/bin/bash

echo "PREPARING TEST DIRECTORIES 'test_source' AND 'test_backup'"

mkdir test_source
touch -t 201801010101 test_source/samefile1
touch -t 201801010101 test_source/samefile2
touch -t 201801010101 test_source/samefile3
touch -t 201901010101 test_source/newfile
touch -t 201901010101 test_source/newerfile

mkdir test_backup
touch -t 201801010101 test_backup/samefile1
touch -t 201801010101 test_backup/samefile2
touch -t 201801010101 test_backup/samefile3
touch -t 201801010101 test_backup/newerfile
touch -t 201801010101 test_backup/obsoletefile
