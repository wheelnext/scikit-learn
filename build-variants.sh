#!/bin/sh

set -ex

# TODO: move this logic to the plugin?
case ${OPENMP} in
	gnu)
		LABEL=gomp
		;;
	intel)
		LABEL=iomp5
		;;
	llvm)
		LABEL=libomp
		# copied from build_wheels.sh
		# OpenMP is not present on macOS by default
		if [[ $(uname) == "Darwin" ]]; then
			# Make sure to use a libomp version binary compatible with the oldest
			# supported version of the macos SDK as libomp will be vendored into the
			# scikit-learn wheels for macos.

			if [[ "$CIBW_BUILD" == *-macosx_arm64 ]]; then
				if [[ $(uname -m) == "x86_64" ]]; then
					# arm64 builds must cross compile because the CI instance is x86
					# This turns off the computation of the test program in
					# sklearn/_build_utils/pre_build_helpers.py
					export PYTHON_CROSSENV=1
				fi
				# SciPy requires 12.0 on arm to prevent kernel panics
				# https://github.com/scipy/scipy/issues/14688
				# We use the same deployment target to match SciPy.
				export MACOSX_DEPLOYMENT_TARGET=12.0
				OPENMP_URL="https://anaconda.org/conda-forge/llvm-openmp/11.1.0/download/osx-arm64/llvm-openmp-11.1.0-hf3c4609_1.tar.bz2"
			else
				export MACOSX_DEPLOYMENT_TARGET=10.9
				OPENMP_URL="https://anaconda.org/conda-forge/llvm-openmp/11.1.0/download/osx-64/llvm-openmp-11.1.0-hda6cdc1_1.tar.bz2"
			fi

			conda create -n build $OPENMP_URL
			PREFIX="$HOME/miniconda3/envs/build"

			export CC=/usr/bin/clang
			export CXX=/usr/bin/clang++
			export CPPFLAGS="$CPPFLAGS -Xpreprocessor -fopenmp"
			export CFLAGS="$CFLAGS -I$PREFIX/include"
			export CXXFLAGS="$CXXFLAGS -I$PREFIX/include"
			export LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib -L$PREFIX/lib -lomp"
		fi
		;;
	iomp)
		pip install intel-openmp
		export CPPFLAGS="${CPPFLAGS} $(pkg-config --cflags openmp)"
		# huge hack: upstream has libs at different levels
		export LDFLAGS="${LDFLAGS} $(pkg-config --libs openmp) -Wl,-rpath,\$ORIGIN/../../.. -Wl,-rpath,\$ORIGIN/../../../.. -Wl,-rpath,\$ORIGIN/../../../../.."
		;;
esac

if [ -n "${X8664}" ]; then
	LABEL=x8664v${X8664}_${LABEL}
	set -- "${@}" "-Cvariant=x86_64::level::${X8664}"
fi

set -- "${@}" "-Cvariant=openmp::provider::${OPENMP}" "-Cvariant-label=${LABEL}"

pip install build auditwheel delocate
python -m build -w "${@}"
mkdir wheelhouse

# tag updating needs to be updated for variants
set -- dist/*.whl
old_name=${1#*/}
# strip variant label to avoid issues with auditwheel
mv "${1}" "${1%-*}.whl"

if grep -q Ubuntu /etc/os-release; then
	auditwheel repair --exclude 'libiomp*' dist/*.whl
	mv wheelhouse/*.whl "wheelhouse/${old_name}"
else
	delocate-wheel -w wheelhouse dist/*.whl
	mv wheelhouse/*.whl "wheelhouse/${old_name}"
fi
