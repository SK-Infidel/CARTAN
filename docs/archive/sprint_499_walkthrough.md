# Sprint 499 Walkthrough: High-Performance Discrete NVIDIA GPU Selection & Dynamic Hardware Identification

**Date**: 2026-09-30  
**Sprint**: 499  
**Theme**: Physical Hardware GPU Dispatch & Discrete Adapter Targeting  
**Status**: COMPLETE (Empirically verified NVIDIA RTX 2000 Ada discrete GPU mounting, dynamic hardware inspection, and zero regression across test suite)

---

## 1. Executive Summary & Root Cause Analysis

On dual-GPU systems (such as Windows laptops equipped with an integrated Intel CPU/iGPU and a discrete NVIDIA RTX 2000 Ada GPU), the user observed that GPU compute activity in Windows Task Manager spiked on the Intel integrated GPU (GPU 0) rather than the NVIDIA discrete GPU (GPU 1).

### Root Cause
In [`src/std/wgpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/wgpu.cl), `wgpuInstanceRequestAdapter` was called with `options = 0.0` (NULL):
```cl
wgpuInstanceRequestAdapter(g_wgpu_instance, 0.0, cb_adapter);
```
Under `wgpu-native`, passing a `NULL` options pointer leaves `powerPreference` as `WGPUPowerPreference_Undefined` (`0x00000000`). On Windows, the runtime enumerates display adapters starting with the primary display controller (Adapter #0), which is the Intel Raptor Lake-S Mobile Graphics Controller (vendor ID `0x8086`, `WGPUAdapterType_IntegratedGPU`). As a result, all WGSL compute pipelines were dispatched to the low-power integrated graphics controller. Furthermore, [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl) had a static printf statement claiming NVIDIA Ada was mounted without querying the actual hardware adapter returned by WebGPU.

---

## 2. Key Code Modifications

### A. WGPURequestAdapterOptions with High-Performance Preference
In [`src/std/wgpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/wgpu.cl), constructed a 32-byte `WGPURequestAdapterOptions` structure and configured `powerPreference = WGPUPowerPreference_HighPerformance` (`2`):
```cl
// Request Discrete High-Performance Adapter (WGPUPowerPreference_HighPerformance)
let adapter_opts = malloc(32.0);
var clr = 0.0;
while (clr < 4.0) {
    adapter_opts[clr] = 0.0;
    clr = clr + 1.0;
}
// Set powerPreference = WGPUPowerPreference_HighPerformance (2.0)
// Byte offset 12 = i32 slot 3.0 (3 * 4 = 12)
cartan_set_i32(adapter_opts, 3.0, 2.0);

wgpuInstanceRequestAdapter(g_wgpu_instance, adapter_opts, cb_adapter);
wgpuInstanceProcessEvents(g_wgpu_instance);
free(cb_adapter);
free(adapter_opts);
```

### B. Hardware Introspection via `wgpuAdapterGetInfo`
In [`src/std/wgpu.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/wgpu.cl), declared `wgpuAdapterGetInfo` and queried the selected adapter's device name, vendor ID, and adapter type:
```cl
extern fn wgpuAdapterGetInfo(adapter: ptr, info: ptr) -> void;

// Inspect physical GPU hardware info
if (g_wgpu_adapter_info == 0.0) {
    g_wgpu_adapter_info = malloc(96.0);
}
var ii = 0.0;
while (ii < 12.0) {
    g_wgpu_adapter_info[ii] = 0.0;
    ii = ii + 1.0;
}
wgpuAdapterGetInfo(g_wgpu_adapter, g_wgpu_adapter_info);
g_wgpu_adapter_name = g_wgpu_adapter_info[5.0];             // Byte offset 40 = device.data
g_wgpu_vendor_id = cartan_i32_at(g_wgpu_adapter_info, 20.0);  // Byte offset 80 = vendorID (0x10DE for NVIDIA)
g_wgpu_adapter_type = cartan_i32_at(g_wgpu_adapter_info, 19.0); // Byte offset 76 = adapterType (1 = Discrete)
```

### C. Dynamic Telemetry & Accessors
Added public accessors in `src/std/wgpu.cl`:
- `cartan_wgpu_get_device_name() -> ptr`
- `cartan_wgpu_get_vendor_id() -> float`
- `cartan_wgpu_get_adapter_type() -> float`

Updated `test/geomind/chat.cl` to report the true hardware device name dynamically:
```cl
g_chat_gpu_mounted = 1.0;
let dev_name = cartan_wgpu_get_device_name();
if (dev_name != 0.0) {
    printf("  [WebGPU VRAM] Mounted physical %s manifold engine.\n", dev_name);
} else {
    printf("  [WebGPU VRAM] Mounted physical WebGPU manifold engine.\n", 0.0);
}
cartan_flush(0.0);
```

---

## 3. Empirical Verification Results

### Test 1: WebGPU Compute Engine Test Target (Target 23)
- **Command**: `.\bin\cartanc.exe run test/compiler_suite/test_webgpu_compute.car`
- **Output**:
  ```
  Initializing WebGPU Compute Engine...
  [CARTAN WebGPU] Hardware Acceleration Engine Initialized on Physical GPU: NVIDIA RTX 2000 Ada Generation Laptop GPU 
  WebGPU Hardware Compute Test Passed Cleanly! Output verified across 64.000000 elements.
  ```
- **Result**: PASS (Hardware initialized on NVIDIA RTX 2000 Ada, all 64 elements verified).

### Test 2: GeoMind Inference Startup Telemetry
- **Command**: `.\bin\geomind.exe -prompt "Hello" -tokens 5`
- **Output**:
  ```
  [CARTAN WebGPU] Hardware Acceleration Engine Initialized on Physical GPU: NVIDIA RTX 2000 Ada Generation Laptop GPU
    [WebGPU VRAM] Mounted physical NVIDIA RTX 2000 Ada Generation Laptop GPU manifold engine.
  [GeoMind Mode] Bare-Metal WebGPU Hardware Acceleration ENABLED (Default)
  ================================================================================
    GEOMIND E8 MULTIMODAL NEURO-SYMBOLIC CHAT ENGINE (chat.car)
    Sovereign GeoMind 42-Layer Manifold & SentencePiece BPE Tokenizer
  ================================================================================
  ...
  GeoMind> Greetings! I am Geo
  ```
- **Result**: PASS (Accurate discrete GPU reported and utilized for compute dispatches).

### Test 3: Standalone Hardware Introspection Check
- **Device**: `NVIDIA RTX 2000 Ada Generation Laptop GPU`
- **Vendor ID**: `4318.0` (`0x10DE` = NVIDIA)
- **Adapter Type**: `1.0` (`WGPUAdapterType_DiscreteGPU`)

---

## 4. Zero-Mock & Rule Compliance Assessment

| Rule | Status | Evidence |
| :--- | :---: | :--- |
| **Strict Zero-Mock / Zero-Simulation** | **COMPLIANT** | Hardware introspection reads real registers from `WGPUAdapterInfo` populated by `wgpu_native.dll`. |
| **Lowest Entropy Solution** | **COMPLIANT** | Solved GPU selection at the driver level in `src/std/wgpu.cl` via standard `WGPURequestAdapterOptions` without ad-hoc branching. |
| **Empirical Proof** | **COMPLIANT** | Target 23 passed, live `geomind.exe` tested, and full compiler regression test suite executed. |
