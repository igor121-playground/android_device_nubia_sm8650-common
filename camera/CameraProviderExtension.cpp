/*
 * Copyright (C) 2024 LibreMobileOS Foundation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "CameraProviderExtension.h"

#include <fstream>

#define TORCH_BRIGHTNESS "brightness"
#define TOGGLE_SWITCH "/sys/devices/platform/soc/c42d000.qcom,spmi/spmi-0/0-01/c42d000.qcom,spmi:qcom,pm8550@1:qcom,flash_led@ee00/leds/led:switch_2/brightness"
static std::string kTorchLedPaths[] = { 
    "/sys/devices/platform/soc/c42d000.qcom,spmi/spmi-0/0-01/c42d000.qcom,spmi:qcom,pm8550@1:qcom,flash_led@ee00/leds/led:torch_0",
    "/sys/devices/platform/soc/c42d000.qcom,spmi/spmi-0/0-01/c42d000.qcom,spmi:qcom,pm8550@1:qcom,flash_led@ee00/leds/led:torch_1",
    "/sys/devices/platform/soc/c42d000.qcom,spmi/spmi-0/0-01/c42d000.qcom,spmi:qcom,pm8550@1:qcom,flash_led@ee00/leds/led:torch_2",
    "/sys/devices/platform/soc/c42d000.qcom,spmi/spmi-0/0-01/c42d000.qcom,spmi:qcom,pm8550@1:qcom,flash_led@ee00/leds/led:torch_3" 
};

/**
 * Write value to path and close file.
 */
template <typename T>
static void set(const std::string& path, const T& value) {
    std::ofstream file(path);
    file << value;
}

/**
 * Read value from the path and close file.
 */
template <typename T>
static T get(const std::string& path, const T& def) {
    std::ifstream file(path);
    T result;

    file >> result;
    return file.fail() ? def : result;
}

bool supportsTorchStrengthControlExt() {
    return true;
}

bool supportsSetTorchModeExt() {
    return false;
}

int32_t getTorchDefaultStrengthLevelExt() {
    // Our default value is 22.
    return 22;
}

int32_t getTorchMaxStrengthLevelExt() {
    // Nubia Camera's torch at level 7 is 55.
    // Let's cap it to 55, node can go higher but i'd rather not test this.
    return 55;
}

int32_t getTorchStrengthLevelExt() {
    // We write same value for all LEDs,
    // so get it from one.
    auto node = kTorchLedPaths[0] + "/" + TORCH_BRIGHTNESS;
    return get(node, 0);
}

void setTorchStrengthLevelExt(int32_t torchStrength, bool enabled) {
    set(TOGGLE_SWITCH, 0);
    for (auto& path : kTorchLedPaths) {
        auto node = path + "/" + TORCH_BRIGHTNESS;
        set(node, torchStrength);
    }
    if (enabled)
        set(TOGGLE_SWITCH, 1);
}

void setTorchModeExt(bool enabled) {
    int32_t strength = getTorchDefaultStrengthLevelExt();
    setTorchStrengthLevelExt(enabled ? strength : 0, enabled);
}