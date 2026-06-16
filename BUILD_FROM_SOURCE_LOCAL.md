# Building and installing Parselmouth locally

This document separates four different workflows. Do not treat them as one
long installation procedure.

The central distinction is this: installing Parselmouth is not the same thing
as manually compiling and locating the native `.so` file. For normal use,
install from PyPI. For local work on this fork, build and install the package
with `pip`. Manual `.so` inspection belongs to debugging and historical
experiments, not to the recommended installation path.

## Quick decision guide

| Goal | Recommended workflow |
|---|---|
| Use Parselmouth as a normal Python package | Install from PyPI |
| Test this fork locally | Local source build with pip |
| Debug CMake/native build internals | CMake development build |
| Understand Enrique's previous `.so` experiment | Historical manual `.so` experiment |

## 1. Normal user installation

Use this path if you only want to use Parselmouth as a Python package.

```bash
python -m pip install praat-parselmouth
```

The installable package name is `praat-parselmouth`. The importable Python
module name is `parselmouth`.

Validate the installation with:

```bash
python - <<'PY'
import parselmouth
print("parselmouth file:", parselmouth.__file__)
print("Parselmouth version:", parselmouth.VERSION)
print("Praat version:", parselmouth.PRAAT_VERSION)
PY
```

This path does not require cloning the repository, running CMake, initializing
submodules, or manually generating any `.so` file.

## 2. Local source build from this fork

Use this path when working from Enrique's fork and installing the package
locally from source. This is the recommended source-build workflow.

The build should install Parselmouth into the active Python environment. Do not
move the compiled `.so` manually.

### 2.1 Fork remotes

This checkout is configured as a fork of the original Parselmouth repository:

```text
origin   = git@github.com:EnriqueDiazO/Parselmouth.git
upstream = https://github.com/YannickJadoul/Parselmouth.git
```

In this setup:

- `origin` is Enrique's fork.
- `upstream` is the original Parselmouth repository.
- Push fork work to `origin`.
- Do not push to `upstream`.

Check remotes with:

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

If another fork uses `main` instead of `master`, replace `master` with `main`.

### 2.2 System requirements

Recommended Ubuntu packages:

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

For Python packaging, the source build uses Python `>=3.9`, NumPy,
setuptools, scikit-build, CMake, a C/C++ compiler, Python headers, git, and
complete required source directories.

### 2.3 Python environment

Create and activate a local virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
```

### 2.4 Submodules

Prefer cloning with submodules:

```bash
git clone --recursive git@github.com:<your-user>/Parselmouth.git
cd Parselmouth
git remote add upstream https://github.com/YannickJadoul/Parselmouth.git
```

A GitHub ZIP downloaded from a fork may not include full submodule contents.
For source builds, prefer `git clone --recursive` over downloading a ZIP.

If the repository is already cloned, initialize or refresh submodules:

```bash
git submodule update --init --recursive
```

Verify the required source directories:

```bash
test -f extern/fmt/CMakeLists.txt && echo "fmt OK" || echo "fmt missing"
test -f pybind11/CMakeLists.txt && echo "pybind11 OK" || echo "pybind11 missing"
test -f praat/CMakeLists.txt && echo "Praat OK" || echo "Praat missing"
```

In this checkout, `extern/fmt` is declared as a Git submodule. The `pybind11`
and `praat` directories are also required source directories for the build.

### 2.5 Build and install with pip

From the repository root, with `.venv` activated:

```bash
python -m pip install -v .
```

This is the recommended local source installation command. It lets `pip`,
setuptools, scikit-build, and CMake build the native extension and install it
into the active Python environment.

The helper script runs this path without installing system packages:

```bash
chmod +x scripts/local_build_ubuntu.sh
./scripts/local_build_ubuntu.sh
```

### 2.6 Verify the local installation

Use `PYTHONNOUSERSITE=1` so the check cannot accidentally pass by importing an
older package from `~/.local`:

```bash
PYTHONNOUSERSITE=1 python - <<'PY'
import sys
import parselmouth

print("Python:", sys.executable)
print("parselmouth file:", parselmouth.__file__)
print("Parselmouth version:", parselmouth.VERSION)
print("Praat version:", parselmouth.PRAAT_VERSION)
PY
```

In Enrique's local test, the source build installed Parselmouth into:

```text
.venv/lib/python3.10/site-packages/parselmouth.cpython-310-x86_64-linux-gnu.so

Parselmouth: 0.5.0.dev0
Praat: 6.4.16
```

That result is a valid local installation because the imported module came
from `.venv`, not from `~/.local`.

## 3. Development build with CMake

Use this when developing or debugging the native build, not as the normal user
installation path.

Install test dependencies in the active environment:

```bash
source .venv/bin/activate
python -m pip install -r tests/requirements.txt
```

Configure a Debug build:

```bash
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Debug \
  -DPython_EXECUTABLE="$(which python)"
```

Build the extension and run the CMake `pytest` target:

```bash
cmake --build build --target pytest -j "$(nproc)"
```

This produces a development build under `build/` and uses the compiled
extension when running tests. It is useful for CMake targets, native debugging,
and test iteration. It is separate from the normal user installation path and
from the recommended source installation with `pip`.

In Enrique's local test:

```text
cmake configuration succeeded.
cmake --build build --target pytest -j "$(nproc)" succeeded.
pytest result: 69 passed in 1.25s.
```

## 4. Historical manual `.so` experiment

The previous `Parselv2.zip` experiment was useful because it confirmed that
Enrique could compile Parselmouth locally and produce a native Python extension
file (`.so`) from the repository's embedded Praat source tree.

However, this was not a general mechanism for compiling Parselmouth against an
arbitrary external Praat version. At that stage, the build used the Praat
version already included in the Parselmouth repository.

Manual movement of the `.so` file should be treated as historical debugging,
not as the recommended installation method. The recommended source-build path
is:

```bash
python -m pip install -v .
```

Observed `.so` locations during local source and CMake builds included:

```text
_skbuild/linux-x86_64-3.10/cmake-build/src/parselmouth.cpython-310-x86_64-linux-gnu.so
_skbuild/linux-x86_64-3.10/cmake-install/src/parselmouth.cpython-310-x86_64-linux-gnu.so
_skbuild/linux-x86_64-3.10/setuptools/lib.linux-x86_64-cpython-310/parselmouth.cpython-310-x86_64-linux-gnu.so
build/src/parselmouth.cpython-310-x86_64-linux-gnu.so
.venv/lib/python3.10/site-packages/parselmouth.cpython-310-x86_64-linux-gnu.so
```

These paths are useful for diagnosis and verification. They do not imply that
the user should manually copy the extension module as the installation method.

Local build outputs such as `_skbuild/`, `build/`, `.so` files, `.egg-info`
metadata, and `.venv/` are artifacts. They should not be committed to the
repository.

## 5. Cleaning generated files

Remove generated build artifacts from the repository root:

```bash
rm -rf build _skbuild dist *.egg-info src/*.egg-info .pytest_cache
```

This keeps `.venv` by default. To remove the local Python environment too:

```bash
rm -rf .venv
```

Only run these commands from the repository root. Do not remove source
directories such as `extern/`, `pybind11/`, `praat/`, `src/`, or `tests/`.

## 6. Troubleshooting

Troubleshooting belongs here, not in the main workflow. Use these notes when a
specific symptom appears.

### `extern/fmt` missing

```bash
git submodule update --init --recursive
```

Then verify:

```bash
test -f extern/fmt/CMakeLists.txt && echo "fmt OK" || echo "fmt missing"
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

Usually `pip` installs build requirements from `pyproject.toml` automatically.
If you are debugging packaging manually, install scikit-build in the active
environment:

```bash
python -m pip install "scikit-build>=0.13"
```

### `No module named parselmouth`

Check that the expected Python and pip are active:

```bash
which python
python -m pip --version
python -m pip show praat-parselmouth
```

If the package is missing, build and install it from the repository root:

```bash
python -m pip install -v .
```

### Import points to `~/.local`

If `parselmouth.__file__` points to a user-site installation under `~/.local`,
the check is not validating this repository's local build. Disable user-site
packages while testing:

```bash
PYTHONNOUSERSITE=1 python - <<'PY'
import parselmouth
print(parselmouth.__file__)
PY
```

The path should point to `.venv`, `_skbuild`, `build`, or another intentional
local build/install location, not to `~/.local`.

### Build fails after previous attempts

Clean generated files and build again:

```bash
rm -rf build _skbuild dist *.egg-info src/*.egg-info .pytest_cache
python -m pip install -v .
```

## 7. Technical interpretation

Parselmouth does not primarily call Praat through `subprocess`. It embeds Praat
as C/C++ code and exposes that code to Python with pybind11. That is why local
source builds require a compiler, CMake, Python headers, NumPy, scikit-build,
and complete required source directories.

The repository already includes `pybind11`, so it is normally not necessary to
install `pybind11` with `pip` to compile Parselmouth.

This architecture gives Parselmouth efficient access to Praat algorithms and
internal structures, but it makes compilation and distribution more complex
than for a pure Python package.

The earlier manual `.so` work confirmed that the repository can produce the
native extension from its embedded Praat tree. It did not solve the separate
problem of building Parselmouth against any arbitrary external Praat version.
