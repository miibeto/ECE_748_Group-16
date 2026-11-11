#!/bin/bash

make clean
make p3_build
make p3_cli_run_test TEST_NAME=test_top
# make merge_coverage
# make view_coverage
# make report_coverage