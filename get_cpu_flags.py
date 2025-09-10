#!/usr/bin/env python3

import argparse


def main() -> None:
    argp = argparse.ArgumentParser()
    argp.add_argument("--arch", required=True, choices=["aarch64", "x86_64"])
    argp.add_argument("--language", required=True)
    argp.add_argument("--compiler-name", required=True)
    argp.add_argument("--compiler-version", required=True)
    argp.add_argument("--variant", required=True)

    args = argp.parse_args()

    if args.arch == "aarch64":
        from provider_variant_aarch64.plugin import AArch64Plugin
        plugin = AArch64Plugin()
    elif args.arch == "x86_64":
        from provider_variant_x86_64.plugin import X8664Plugin
        plugin = X8664Plugin()

    vprops = [
        argparse.Namespace(
            namespace=args.arch,
            feature="level" if args.arch == "x86_64" else "version",
            value=args.variant,
        )
    ]
    print(
        " ".join(
            plugin.get_compiler_flags(
                args.language, args.compiler_name, args.compiler_version, vprops
            )
        )
    )


if __name__ == "__main__":
    main()
