# Building Parselmouth / Praat from source locally

This guide documents how to install, build, and verify this Parselmouth fork
from source. It is intended for local development and reproducible source
builds, not for committing build artifacts.

## 1. Normal installation from PyPI

For normal usage, install the published Python package from PyPI:

```bash
python -m pip install praat-parselmouth
```

The installable package name is `praat-parselmouth`. The importable Python
module name is `parselmouth`.

Validate the installed package with:

```bash
python - <<'PY'
import parselmouth
print("parselmouth file:", parselmouth.__file__)
print("Parselmouth version:", parselmouth.VERSION)
print("Praat version:", parselmouth.PRAAT_VERSION)
PY
```

Use a source build only when you need to test local code, work from a fork, or
debug the C/C++ integration with Praat.

## 2. Source-build overview

Parselmouth is a Python extension module built from C/C++ sources. A source
build combines several layers:

- Python packaging with `pip`, `setuptools`, and `scikit-build`.
- Native configuration and compilation with CMake.
- The embedded Praat source tree.
- The pybind11 binding layer that exposes Praat functionality to Python.
- Required source dependencies such as `extern/fmt`.

The most common local build command is:

```bash
python -m pip install -v .
```

From the repository root, this asks `pip` to build the package declared by
`pyproject.toml`. The build backend invokes `scikit-build`, and `scikit-build`
drives CMake.

## 3. Working from a fork

This checkout is configured as a fork of the original Parselmouth repository:

```text
origin   = git@github.com:EnriqueDiazO/Parselmouth.git
upstream = https://github.com/YannickJadoul/Parselmouth.git
```

In this setup:

- `origin` is the personal fork.
- `upstream` is the original Parselmouth repository.
- Push local fork work to `origin`.
- Do not push to `upstream`.
- Keep required source directories and submodules complete in the fork.

Check the configured remotes with:

```bash
git remote -v
```

To update the fork from the original repository:

```bash
git fetch upstream
git switch master
git merge upstream/master
git submodule update --init --recursive
```

If another fork uses `main` instead of `master`, replace `master` with `main`
in the commands above.

## 4. Requirements

For local builds, use:

- Python `>=3.9`.
- NumPy.
- setuptools.
- scikit-build.
- CMake.
- A C/C++ compiler.
- Python headers.
- git.
- Complete required source directories and submodules.
- pytest for tests.

The repository already includes `pybind11`, so it is normally not necessary to
install `pybind11` with `pip` to compile Parselmouth.

## 5. Recommended Ubuntu setup

Install the main system packages:

```bash
sudo apt update
sudo apt install -y \
  git \
  build-essential \
  cmake \
  python3-dev \
  python3-venv \
  unzip
```

Optional build helpers:

```bash
sudo apt install -y ccache ninja-build
```

Legacy or diagnostic packages:

```bash
sudo apt install -y libasound2-dev libx11-dev libfftw3-dev
```

Do not treat those legacy packages as primary requirements. Install them only
if a local build complains about missing audio, X11, or FFTW headers. Yannick
indicated that `libfftw3-dev` was probably not necessary, and recent versions
should be independent of X11.

## 6. Creating a Python environment

Using `venv`:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
```

Optional `pyenv` workflow:

```bash
pyenv install 3.10.14
pyenv virtualenv 3.10.14 parselmouth-dev-3.10
pyenv activate parselmouth-dev-3.10
python -m pip install --upgrade pip setuptools wheel
```

Install test requirements when you plan to run the test suite:

```bash
python -m pip install -r tests/requirements.txt
```

## 7. Getting the source code

### Original repository

```bash
git clone --recursive https://github.com/YannickJadoul/Parselmouth.git
cd Parselmouth
```

### Fork

```bash
git clone --recursive git@github.com:<your-user>/Parselmouth.git
cd Parselmouth
git remote add upstream https://github.com/YannickJadoul/Parselmouth.git
```

A GitHub ZIP downloaded from a fork may not include full submodule contents.
For source builds, prefer `git clone --recursive` over downloading a ZIP.

## 8. Submodules

Initialize and update submodules after cloning, after switching branches, and
after merging changes from `upstream`:

```bash
git submodule update --init --recursive
git submodule status
```

In this checkout, `extern/fmt` is declared as a Git submodule. The `pybind11`
and `praat` directories are also required source directories for the build, so
verify all three before building:

```bash
test -f extern/fmt/CMakeLists.txt && echo "fmt OK" || echo "fmt missing"
test -f pybind11/CMakeLists.txt && echo "pybind11 OK" || echo "pybind11 missing"
test -f praat/CMakeLists.txt && echo "Praat OK" || echo "Praat missing"
```

If any required directory is missing or incomplete, run:

```bash
git submodule update --init --recursive
```

If a directory is still missing after that, reclone with `--recursive` or check
that the fork contains the expected source tree.

## 9. Installing from source with pip

From the repository root, with the desired Python environment activated:

```bash
python -m pip install --upgrade pip setuptools wheel
python -m pip install -v .
```

Then validate the installed extension:

```bash
python - <<'PY'
import parselmouth
print(parselmouth.__file__)
print(parselmouth.VERSION)
print(parselmouth.PRAAT_VERSION)
PY
```

Do not move the compiled `.so` manually as the normal installation method. Let
`pip` install the extension into the active Python environment. Manually
inspecting or copying the extension should be treated only as advanced
diagnostics.

An optional helper script is available for Ubuntu-style local builds:

```bash
chmod +x scripts/local_build_ubuntu.sh
./scripts/local_build_ubuntu.sh
```

The script does not install system packages. It checks the repository root,
checks the required source directories, creates `.venv` if needed, builds with
`pip`, and validates `import parselmouth`.

## 10. Building and testing with CMake

Use `pip` when you want a normal Python package installation:

```bash
python -m pip install -v .
```

Use CMake directly when you want a development or debug build and access to
CMake targets:

```bash
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Debug \
  -DPython_EXECUTABLE="$(which python)"

cmake --build build --target pytest -j "$(nproc)"
```

The first command configures a Debug build in `build/`. The second command
builds the extension and runs the CMake `pytest` target. The test target sets
`PYTHONPATH` to the compiled extension directory before running pytest.

If pytest is not installed in the active environment, install the test
requirements first:

```bash
python -m pip install -r tests/requirements.txt
```

## 11. Finding the compiled extension

Search for compiled extension files with:

```bash
find . -name "parselmouth*.so" -o -name "parselmouth*.pyd"
```

Typical locations include:

```text
src/parselmouth*.so
_skbuild/*/cmake-build/src/parselmouth*.so
_skbuild/*/cmake-install/src/parselmouth*.so
build/src/parselmouth*.so
```

Linux uses `.so` extension modules. Windows uses `.pyd` extension modules.

## 12. Verifying the installation

Use this smoke test in the same Python environment that performed the build:

```bash
python - <<'PY'
import parselmouth
import numpy as np

print("Module:", parselmouth)
print("File:", parselmouth.__file__)
print("Parselmouth:", parselmouth.VERSION)
print("Praat:", parselmouth.PRAAT_VERSION)

snd = parselmouth.Sound(np.zeros(16000), sampling_frequency=16000)
print("Sound duration:", snd.duration)
PY
```

The reported file should point to the active environment or to the expected
local build output. If it points to a different Python installation, check
`which python` and `python -m pip --version`.

## 13. Cleaning build artifacts

From the repository root only, remove local build artifacts with:

```bash
rm -rf build _skbuild dist *.egg-info src/*.egg-info
```

Run this command only from the root of the Parselmouth repository. Do not remove
source directories such as `extern/`, `pybind11/`, `praat/`, `src/`, or `tests/`.

## 14. Common errors

### `extern/fmt` missing

```bash
git submodule update --init --recursive
```

### `cmake: command not found`

```bash
sudo apt install cmake
```

### `Python.h: No such file or directory`

```bash
sudo apt install python3-dev
```

### `No module named skbuild`

```bash
python -m pip install "scikit-build>=0.13"
```

### `No module named parselmouth`

Verify the active Python environment:

```bash
which python
python -m pip --version
python -m pip show praat-parselmouth
```

If the package is missing, install it again from the repository root:

```bash
python -m pip install -v .
```

### Build fails after previous attempts

```bash
rm -rf build _skbuild dist *.egg-info src/*.egg-info
python -m pip install -v .
```

## 15. Notes from the previous Parselv2 experiment

`Parselv2.zip` is evidence of a previous successful local build experiment.
Treat it as historical evidence, not as source code that should be committed.

The compressed virtual environment `parsel2-env/` from that experiment is not
portable. Virtual environments contain absolute paths, interpreter-specific
files, installed binaries, and machine-local assumptions.

Build outputs such as `_skbuild/`, `build/`, `.so` files, `*.egg-info`
metadata, and virtual environments should not be committed to this repository.
The reliable workflow is to rebuild cleanly on each machine from the
repository, the required source directories, the Python environment, and the
documented build commands.

## 16. Technical interpretation

Parselmouth does not primarily call Praat through `subprocess`. It embeds Praat
as C/C++ code and exposes that code to Python with pybind11. That is why a
source build requires a compiler, CMake, Python headers, NumPy, scikit-build,
and complete required source directories.

This architecture gives Parselmouth efficient access to Praat algorithms and
internal structures, but it makes compilation and distribution more complex
than for a pure Python package.
