# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("//rules:cross_platform.bzl", "dual_cc_library", "dual_inputs")
load("//rules:linker.bzl", "ld_library")
load("//rules/opentitan:defs.bzl", "OPENTITAN_CPU")
load(
    "//rules/opentitan:defs.bzl",
    "EARLGREY_TEST_ENVS",
    "fpga_params",
    "opentitan_test",
    "verilator_params",
)

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "doc_files",
    srcs = glob([
        "**/*.md",
        "**/*.svg",
    ]),
)

cc_library(
    name = "coverage_none",
    srcs = ["coverage_none.c"],
    hdrs = ["coverage.h"],
)

cc_library(
    name = "coverage_llvm",
    srcs = [
        "coverage_llvm.c",
    ],
    hdrs = ["coverage.h"],
    linkopts = ["-lgcc"],
    deps = [
        "//sw/device/lib/base:crc32",
        "//sw/device/lib/base:memory",
        "//sw/device/lib/runtime:log",
        "//sw/device/lib/runtime:print",
        "//third_party/llvm_compiler_rt",
    ],
)

alias(
    name = "coverage",
    actual = select({
        "//sw/device:measure_coverage_on_target": ":coverage_llvm",
        "//conditions:default": ":coverage_none",
    }),
    visibility = ["//visibility:private"],
)

cc_library(
    name = "status",
    srcs = ["status.c"],
    hdrs = ["status.h"],
    target_compatible_with = [OPENTITAN_CPU],
    deps = [
        "//sw/device/lib/arch:device",
        "//sw/device/lib/base:mmio",
        "//sw/device/lib/runtime:hart",
        "//sw/device/lib/runtime:log",
    ],
)

cc_library(
    name = "status_headers",
    hdrs = ["status.h"],
)

cc_library(
    name = "check",
    hdrs = ["check.h"],
    target_compatible_with = [OPENTITAN_CPU],
    deps = [
        ":status",
        "//sw/device/lib/base:macros",
        "//sw/device/lib/base:mmio",
        "//sw/device/lib/base:status",
        "//sw/device/lib/dif:base",
        "//sw/device/lib/runtime:hart",
        "//sw/device/lib/runtime:log",
    ],
)

ld_library(
    name = "ottf_ld_common",
    includes = ["ottf_common.ld"],
    deps = [
        "//sw/device:info_sections",
        "//sw/device/silicon_creator/lib/base:static_critical_sections",
    ],
)

ld_library(
    name = "ottf_ld_top_config",
    includes = ["ottf_ld_top_config.ld"],
    deps = [
        "//hw/top:top_ld",
    ],
)

ld_library(
    name = "ottf_ld_silicon_creator_slot_a",
    script = "ottf_silicon_creator_a.ld",
    deps = [
        ":ottf_ld_common",
        ":ottf_ld_top_config",
        "//hw/top:top_ld",
    ],
)

ld_library(
    name = "ottf_ld_silicon_creator_slot_b",
    script = "ottf_silicon_creator_b.ld",
    deps = [
        ":ottf_ld_common",
        ":ottf_ld_top_config",
        "//hw/top:top_ld",
    ],
)

ld_library(
    name = "ottf_ld_silicon_creator_slot_virtual",
    script = "ottf_silicon_creator_virtual.ld",
    deps = [
        ":ottf_ld_common",
        ":ottf_ld_top_config",
        "//hw/top:top_ld",
    ],
)

ld_library(
    name = "ottf_ld_silicon_owner_slot_a",
    script = "ottf_silicon_owner_a.ld",
    deps = [
        ":ottf_ld_common",
        ":ottf_ld_top_config",
        "//hw/top:top_ld",
    ],
)

ld_library(
    name = "ottf_ld_silicon_owner_slot_b",
    script = "ottf_silicon_owner_b.ld",
    deps = [
        ":ottf_ld_common",
        ":ottf_ld_top_config",
        "//hw/top:top_ld",
    ],
)

ld_library(
    name = "ottf_ld_silicon_owner_slot_virtual",
    script = "ottf_silicon_owner_virtual.ld",
    deps = [
        ":ottf_ld_common",
        ":ottf_ld_top_config",
        "//hw/top:top_ld",
    ],
)

# TODO(#12905): Use a slightly hollowed out version of the silicon_creator
# manifest_def implementation when building the test_framework for the english
# breakfast top level.
cc_library(
    name = "english_breakfast_test_framework_manifest_def",
    srcs = [
        "//sw/device/silicon_creator/lib:english_breakfast_test_framework_manifest_def_srcs",
    ],
    # This should be built only for english breakfast and skipped if using wildcards.
    tags = ["manual"],
    deps = [
        "//sw/device/lib/testing/test_rom:english_breakfast_test_rom_manifest",
    ],
    # The manifest section should be populated anytime this is added as a
    # dependency, even if the manifest is not referenced by software.
    alwayslink = True,
)

alias(
    name = "test_framework_manifest_def",
    actual = select({
        "//sw/device:is_english_breakfast": ":english_breakfast_test_framework_manifest_def",
        "//conditions:default": "//sw/device/silicon_creator/lib:manifest_def",
    }),
)

cc_library(
    name = "ottf_isrs",
    srcs = [
        "ottf_isrs.S",
        "ottf_isrs.c",
        "ottf_macros.h",
    ],
    hdrs = [
        "ottf_isrs.h",
    ],
    target_compatible_with = [OPENTITAN_CPU],
    deps = [
        ":check",
        "//hw/top:dt",
        "//sw/device/lib/base:csr",
        "//sw/device/lib/base:macros",
        "//sw/device/lib/dif:rv_plic",
        "//sw/device/lib/runtime:hart",
        "//sw/device/lib/runtime:ibex",
        "//sw/device/lib/runtime:log",
    ],
)

# This target provides start files without providing the full OTTF, and can be
# used to bootstrap post-ROM execution without pulling in the full OTTF. This is
# useful for programs in `sw/device/examples/` and `sw/device/sca/` that do not
# make use of the full OTTF. This target is also suitable for preparing ROM_EXT
# and BLO images since it reserves space at the start of main SRAM for the
# `.static_critical` section that holds boot measurements and sec_mmio context.
#
# The binary target must provide a `noreturn void _ottf_main(void)` function
# that this library will call.
cc_library(
    name = "ottf_start",
    srcs = [
        "ottf_macros.h",
        "ottf_start.S",
    ],
    target_compatible_with = [OPENTITAN_CPU],
    deps = [
        ":check",
        ":ottf_isrs",
        ":test_framework_manifest_def",
        "//hw/top:top_lib",
        "//sw/device/lib/base:csr",
        "//sw/device/lib/base:macros",
        "//sw/device/lib/crt",
        "//sw/device/lib/dif:rstmgr",
        "//sw/device/lib/dif:rv_plic",
        "//sw/device/lib/runtime:hart",
        "//sw/device/lib/runtime:ibex",
        "//sw/device/lib/runtime:log",
        "//sw/device/silicon_creator/lib/base:static_critical",
    ],
)

cc_library(
    name = "ottf_test_config",
    hdrs = [
        "ottf_test_config.h",
    ],
)

cc_library(
    name = "ottf_utils",
    hdrs = ["ottf_utils.h"],
    target_compatible_with = [OPENTITAN_CPU],
    deps = [
        "//sw/device/lib/base:macros",
        "//sw/device/lib/base:status",
        "//sw/device/lib/testing/test_framework:ujson_ottf",
        "//sw/device/lib/testing/test_framework:ujson_ottf_commands",
    ],
)

cc_library(
    name = "ottf_main",
    srcs = ["ottf_main.c"],
    hdrs = ["ottf_main.h"],
    target_compatible_with = [OPENTITAN_CPU],
    deps = [
        ":check",
        ":coverage",
        ":freertos_port",
        ":ottf_console",
        ":ottf_start",
        ":ottf_test_config",
        ":status",
        "//sw/device/lib/arch:device",
        "//sw/device/lib/base:macros",
        "//sw/device/lib/base:mmio",
        "//sw/device/lib/base:status",
        "//sw/device/lib/dif:rv_core_ibex",
        "//sw/device/lib/dif:uart",
        "//sw/device/lib/runtime:hart",
        "//sw/device/lib/runtime:log",
        "//sw/device/lib/testing:rand_testutils",
        "//third_party/freertos",
        "@manufacturer_test_hooks//:test_hooks",
    ],
    # `:ottf` depends on `:ottf_start`, but `:ottf_start` gets its main function
    # from `:ottf`. Thus we need to include all of the objects in `:ottf`
    # unconditionally so that the linker can find the symbol later.
    alwayslink = True,
)

cc_library(
    name = "ujson_ottf",
    srcs = ["ujson_ottf.c"],
    hdrs = ["ujson_ottf.h"],
    deps = [
        ":ottf_console",
        "//sw/device/lib/base:status",
        "//sw/device/lib/dif:uart",
        "//sw/device/lib/runtime:print",
        "//sw/device/lib/testing/json:ottf",
        "//sw/device/lib/ujson",
    ],
)

cc_library(
    name = "ujson_ottf_commands",
    srcs = ["ujson_ottf_commands.c"],
    hdrs = ["ujson_ottf_commands.h"],
    deps = [
        ":ujson_ottf",
        "//sw/device/lib/base:status",
        "//sw/device/lib/testing/json:command",
        "//sw/device/lib/testing/json:mem",
        "//sw/device/lib/ujson",
    ],
)

dual_cc_library(
    name = "ottf_console",
    srcs = dual_inputs(
        device = ["ottf_console.c"],
    ),
    hdrs = ["ottf_console.h"],
    deps = dual_inputs(
        device = [
            ":check",
            ":ottf_isrs",
            ":ottf_test_config",
            "//sw/device/lib/base:mmio",
            "//sw/device/lib/runtime:print",
            "//sw/device/lib/dif:rv_plic",
            "//sw/device/lib/dif:gpio",
            "//sw/device/lib/dif:pinmux",
            "//sw/device/lib/runtime:ibex",
            "//sw/device/lib/runtime:irq",
            "//sw/device/lib/testing:spi_device_testutils",
            "//hw/top:top_lib",
        ],
        shared = [
            "//sw/device/lib/base:status",
            "//sw/device/lib/dif:uart",
            "//sw/device/lib/dif:spi_device",
        ],
    ),
)

_FLOW_CONTROL_MESSAGE = (
    "Mary had a little lamb, its fleece was white as snow. " +
    "Everywhere that Mary went the lamb was sure to go."
)

opentitan_test(
    name = "ottf_flow_control_functest",
    srcs = ["ottf_flow_control_functest.c"],
    exec_env = dicts.add(
        EARLGREY_TEST_ENVS,
        {
            "//hw/top_earlgrey:fpga_cw310_test_rom": None,
        },
    ),
    fpga = fpga_params(
        flow_control_message = _FLOW_CONTROL_MESSAGE,
        test_cmd = """
            --exec="transport init"
            --exec="fpga load-bitstream {bitstream}"
            --exec="bootstrap --clear-uart=true {firmware}"
            --exec="console --non-interactive --exit-success=WAIT --exit-failure=PASS|FAIL --flow-control"
            console
            --flow-control
            --send="{flow_control_message}\n"
            --exit-success="RESULT:{flow_control_message}"
            --exit-failure="PASS|FAIL"
        """,
    ),
    verilator = verilator_params(
        flow_control_message = _FLOW_CONTROL_MESSAGE,
        test_cmd = """
            --exec "console --non-interactive --exit-success=WAIT --exit-failure=PASS|FAIL --flow-control"
            console
            --flow-control
            --send="{flow_control_message}\n"
            --exit-success="{flow_control_message}"
            --exit-failure="PASS|FAIL"
        """,
    ),
    deps = [
        ":check",
        ":ottf_console",
        ":ottf_main",
        ":ujson_ottf",
        "//sw/device/lib/base:status",
        "//sw/device/lib/runtime:print",
        "//sw/device/lib/ujson",
    ],
)

cc_library(
    name = "freertos_config",
    hdrs = ["FreeRTOSConfig.h"],
    # FreeRTOS sources don't follow our project's include-path standard,
    # and just include via the bare filename.
    includes = ["."],
)

cc_library(
    name = "freertos_port",
    srcs = [
        "freertos_hooks.c",
        "freertos_port.S",
        "freertos_port.c",
    ],
    deps = [
        ":check",
        ":freertos_config",
        ":ottf_start",
        "//hw/top:dt",
        "//sw/device/lib/dif:rv_timer",
        "//sw/device/lib/dif:uart",
        "//sw/device/lib/runtime:hart",
        "//sw/device/lib/runtime:irq",
        "//sw/device/lib/runtime:log",
        "//third_party/freertos",
    ],
    # This library provides FreeRTOS hooks that are required for FreeRTOS to link,
    # but FreeRTOS (currently) does not depend on this target. Therefore, we need
    # to include all of the symbols from this object in the link so that they are
    # found during linking.
    alwayslink = True,
)
