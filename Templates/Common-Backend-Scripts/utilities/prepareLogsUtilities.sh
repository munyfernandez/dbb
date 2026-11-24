#!/bin/env bash
#===================================================================================
# NAME: prepareLogsUtilities.sh
#
# DESCRIPTION: Gathers DBB build log files into a single tarfile and echoes the
#              filename. This file is sourced by the wrapper scripts (e.g. zBuilder.sh)
#              and by the standalone prepareLogs.sh. It only defines the function
#              runPrepareLogs and never calls exit.
#
# REQUIRES (provided by the calling script and pipelineBackend.config):
#
#    PGM, SYS, USER       - Calling script name and environment info
#    Workspace            - Workspace of the build
#    getLogDir()          - Function from pipelineBackend.config
#    getWorkDirectory()   - Function from pipelineBackend.config
#
# FUNCTIONS:
#
#    runPrepareLogs       - Creates the tar file next to the logs directory.
#                           Returns 0 on success, 8 on error.
#
# NOTE(S):
#
#   1. The caller is responsible for transferring the tar file to a remote runner.
#===================================================================================

runPrepareLogs() {
    # Local variables keep the caller's variables (e.g. rc and outDir in zBuilder.sh) untouched
    local rc=0
    local ERRMSG=""
    local outDir=""            # Computed output directory to store build protocols
    local baseDir=""
    local CMD=""
    local startDir="$PWD"      # Restore the caller's working directory when done

    #
    # Validate Options
    if [ -z "${Workspace}" ]; then
        rc=8
        ERRMSG=$PGM": [ERROR] Unique Workspace parameter (-w) is required. rc="$rc
        echo $ERRMSG
    else

        # Compute the outDir parameter
        outDir=$(getLogDir)

        if [ ! -d "$outDir" ]; then
            rc=8
            ERRMSG=$PGM": [ERROR] The logs directory '$outDir' was not found. Skipping creation of tar file. rc="$rc
            echo $ERRMSG
        fi

        if [ ! -d "$(getWorkDirectory)" ]; then
            rc=8
            ERRMSG=$PGM": [ERROR] Workspace Directory ($(getWorkDirectory)) was not found. rc="$rc
            echo $ERRMSG
        fi
    fi

    # Print info
    # Ready to go  TLD: Suggest in the section to echo as much as possible
    if [ $rc -eq 0 ]; then
        echo $PGM": [INFO] **************************************************************"
        echo $PGM": [INFO] ** Started - Prepare logs on HOST/USER: ${SYS}/${USER}"
        echo $PGM": [INFO] **          Workspace:" $(getWorkDirectory)
        echo $PGM": [INFO] **             LogDir:" ${outDir}
        echo $PGM": [INFO] **************************************************************"
    fi

    # Start in working directory containing build directory
    if [ $rc -eq 0 ]; then

        cd $outDir

        # Get build directory name
        # Assumes only one item prefixed with "build" (i.e. the run's build directory) in the working directory)
        # DBEHM: Remember, that the build directory name is optional for zAppBuild

        # BuildDir=$(ls -d build*)

        # Create tar file name based on logs directory name

        baseDir=$(basename $PWD)
        cd ..

        echo $PGM": [INFO] List directory contents"
        CMD="ls -RlTr $baseDir"
        echo $PGM": [INFO] ${CMD}"
        ${CMD}
        rc=$?
    fi

    if [ $rc -eq 0 ]; then

        # Package files via tar so they can be downloaded in pipeline orchestrator's next steps
        echo $PGM": [INFO] Create tar file"
        CMD="tar -cf $baseDir.tar $baseDir"
        echo $PGM": [INFO] ${CMD}"
        ${CMD}
        rc=$?
    fi

    if [ $rc -eq 0 ]; then
        # Pass BuildLogFileName to pipeline orchestrator
        echo $PGM": [INFO] Logs successfully stored at $PWD/$baseDir.tar"
    else
        ERRMSG=$PGM": [ERROR] Error during Prepare Logs. Check Console for details. rc="$rc
        echo $ERRMSG
        rc=8
    fi

    cd "$startDir"
    return $rc
}
