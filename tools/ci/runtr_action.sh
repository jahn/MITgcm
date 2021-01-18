#!/bin/bash
#
# Test report running script for Travis CI 
# - called from .travis.yml script: section with environment variables 
#   possibly set.
#   If they are not set then defaults are configured here.
# MITGCM_EXP   - MITgcm test to run
# MITGCM_TROPT - Test report options
#

if [ -z "${MITGCM_TROPT}" ]; then
 export MITGCM_TROPT='-devel -of=../tools/build_options/linux_amd64_gfortran'
fi
if [ -z "${MITGCM_INPUT_DIR_PAT}" ]; then
 export MITGCM_INPUT_DIR_PAT='/input.*'
fi

cd verification
./testreport -t ${MITGCM_EXP} ${MITGCM_TROPT} | 
    tee ${MITGCM_EXP}/testreport_out.txt
python verification_parser.py                  \
    -filename ${MITGCM_EXP}/testreport_out.txt \
    -threshold ${MITGCM_PRECS}                 \
    -input_dir_pat ${MITGCM_INPUT_DIR_PAT}
