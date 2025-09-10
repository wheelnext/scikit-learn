project(
  'scikit-learn',
  'c', 'cpp', 'cython',
  version: run_command('sklearn/_build_utils/version.py', check: true).stdout().strip(),
  license: 'BSD-3',
  meson_version: '>= 1.1.0',
  default_options: [
    'c_std=c11',
    'cpp_std=c++14',
  ],
)

aarch64_variant = ''
openmp_variant = ''
x86_64_variant = ''

foreach variant_meta : get_option('variant')
  split_meta = variant_meta.split('::')
  if split_meta.length() != 3
    error('Invalid variant key: ' + variant_meta)
  endif
  if split_meta[0].strip() == 'openmp' and split_meta[1].strip() == 'provider'
    openmp_variant = split_meta[2].strip()
  elif split_meta[0].strip() == 'x86_64' and split_meta[1].strip() == 'level'
    if host_machine.cpu_family() != 'x86_64'
      error('Variant valid only on x86_64: ' + variant_meta)
    endif
    x86_64_variant = split_meta[2].strip()
  elif split_meta[0].strip() == 'aarch64' and split_meta[1].strip() == 'version'
    if host_machine.cpu_family() != 'aarch64'
      error('Variant valid only on aarch64: ' + variant_meta)
    endif
    aarch64_variant = split_meta[2].strip()
  else
    error('Unsupported variant key: ' + variant_meta)
  endif
endforeach

cc = meson.get_compiler('c')
cpp = meson.get_compiler('cpp')
cython = meson.get_compiler('cython')

# Check compiler is recent enough (see "Toolchain Roadmap" for details)
if cc.get_id() == 'gcc'
  if not cc.version().version_compare('>=8.0')
    error('scikit-learn requires GCC >= 8.0')
  endif
elif cc.get_id() == 'msvc'
  if not cc.version().version_compare('>=19.20')
    error('scikit-learn requires at least vc142 (default with Visual Studio 2019) ' + \
          'when building with MSVC')
  endif
endif

_global_c_args = cc.get_supported_arguments(
  '-Wno-unused-but-set-variable',
  '-Wno-unused-function',
  '-Wno-conversion',
  '-Wno-misleading-indentation',
)
add_project_arguments(_global_c_args, language : 'c')

# We need -lm for all C code (assuming it uses math functions, which is safe to
# assume for scikit-learn). For C++ it isn't needed, because libstdc++/libc++ is
# guaranteed to depend on it.
m_dep = cc.find_library('m', required : false)
if m_dep.found()
  add_project_link_arguments('-lm', language : 'c')
endif

tempita = find_program('sklearn/_build_utils/tempita.py')

py = import('python').find_installation(pure: false)

if x86_64_variant != '' or aarch64_variant != ''
  if x86_64_variant != ''
    variant_arch = 'x86_64'
    variant_value = x86_64_variant
  else
    variant_arch = 'aarch64'
    variant_value = aarch64_variant
  endif

  lang_mapping = {
    'c': 'c',
    'cpp': 'c++',
  }
  foreach meson_lang, plugin_lang : lang_mapping
    cpu_flags = run_command(
      py, 'get_cpu_flags.py',
      '--arch', variant_arch,
      '--language', plugin_lang,
      '--compiler-name', cc.get_id(),
      '--compiler-version', cc.version(),
      '--variant', variant_value,
      capture: true,
      check: true,
    ).stdout().split()
    add_project_arguments(cpu_flags, language: [meson_lang])
  endforeach
endif

# Copy all the .py files to the install dir, rather than using
# py.install_sources and needing to list them explicitly one by one
install_subdir('sklearn', install_dir: py.get_install_dir())

subdir('sklearn')
