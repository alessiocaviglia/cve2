#!/bin/tcsh

# prepare a working directory
set TIME_STAMP   = `date +"%Y%m%d_%H%M"`
pushd ../../; setenv FLOW_ROOT `pwd`; popd
set BUILD_DIR=$FLOW_ROOT/build/innovus_${TIME_STAMP}

mkdir -p $BUILD_DIR
mkdir -p $BUILD_DIR/artefacts
mkdir -p $BUILD_DIR/artefacts/db
mkdir -p $BUILD_DIR/artefacts/export
mkdir -p $BUILD_DIR/artefacts/metrics

ln -sf $FLOW_ROOT/implementation/pnr/scripts $BUILD_DIR/scripts
ln -sf $FLOW_ROOT/implementation/pnr/inputs $BUILD_DIR/inputs
ln -sf $BUILD_DIR $FLOW_ROOT/build/innovus_latest

set MAX_CPUS = 4
set CPUS = `nproc`

if ( $CPUS > $MAX_CPUS ) then
    set CPUS = $MAX_CPUS
endif

echo $1
# enter the build dir
pushd $BUILD_DIR

/bin/nice -n 5 innovus -common_ui -execute "set FLOW_ROOT $FLOW_ROOT; source setup.tcl; set_multi_cpu_usage -local_cpu $CPUS"

popd
