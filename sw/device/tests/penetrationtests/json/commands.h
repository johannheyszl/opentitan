// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_TESTS_PENETRATIONTESTS_JSON_COMMANDS_H_
#define OPENTITAN_SW_DEVICE_TESTS_PENETRATIONTESTS_JSON_COMMANDS_H_
#include "sw/device/lib/ujson/ujson_derive.h"
#ifdef __cplusplus
extern "C" {
#endif

// clang-format off

#define COMMAND(_, value) \
    value(_, AesSca) \
    value(_, AlertInfo) \
    value(_, CryptoFi) \
    value(_, CryptoLibFiAsym) \
    value(_, CryptoLibFiSym) \
    value(_, CryptoLibScaSym) \
    value(_, CryptoLibScaAsym) \
    value(_, EdnSca) \
    value(_, ExtClkScaFi) \
    value(_, HmacSca) \
    value(_, IbexFi) \
    value(_, IbexSca) \
    value(_, KmacSca) \
    value(_, LCCtrlFi) \
    value(_, OtbnFi) \
    value(_, OtbnSca) \
    value(_, OtpFi) \
    value(_, PrngSca) \
    value(_, RngFi) \
    value(_, RomFi) \
    value(_, Sha3Sca) \
    value(_, TriggerSca)
UJSON_SERDE_ENUM(PenetrationtestCommand, penetrationtest_cmd_t, COMMAND);

#define PENTEST_NUM_ENC(field, string) \
    field(num_enc, uint32_t)
UJSON_SERDE_STRUCT(PenetrationtestCommandNumEnc, penetrationtest_num_enc_t, PENTEST_NUM_ENC);

// clang-format on

#ifdef __cplusplus
}
#endif
#endif  // OPENTITAN_SW_DEVICE_TESTS_PENETRATIONTESTS_JSON_COMMANDS_H_
