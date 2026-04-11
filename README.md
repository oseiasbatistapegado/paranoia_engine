# 🌑 Paranoia Engine

**A high-performance, data-oriented 2.5D game engine built with Zig and Vulkan.**

Paranoia Engine is a technical endeavor to push the limits of low-spec hardware. Developed primarily on a **Samsung Chromebook 4 (Intel Celeron N4020)** running **NixOS**, the engine's philosophy is simple: *If it runs smooth here, it will fly anywhere.*

## 🚀 Technical Highlights

* **Data-Oriented Design (DOD):** Engineered for cache locality. Entities share immutable configurations, reducing memory pressure and maximizing L1/L2 cache efficiency on limited CPUs.
* **Vulkan-Powered Instancing:** Handles thousands of entities through a single draw call using GPU instancing, minimizing CPU-to-GPU overhead.
* **Hardware-Conscious Math:** Hand-optimized matrix operations using `zmath`. Perspective and Y-sorting are handled via a low-cost depth-buffer calculation tailored for integrated GPUs.
* **Reproducible Environment:** Built with **Nix Flakes**, ensuring a consistent and predictable development environment across any machine.

## 🛠 Tech Stack

* **Language:** Zig 0.15.2+ (Master branch)
* **Graphics API:** Vulkan 1.2
* **Windowing & Input:** SDL3
* **Math:** zmath (SIMD-optimized)
* **Assets:** zstbi (image loading)
* **OS/Environment:** NixOS / Wayland

## 🏗 Architecture

The engine is divided into three main layers to maintain a clean separation of concerns:

1.  **Core:** Low-level Vulkan abstractions, window management, and secret handling (agenix).
2.  **Engine:** Physics (3-axis), Entity management, and Data-Driven animation systems.
3.  **Renderer:** 2D/2.5D batching, shader management, and asset loading.

## 🚦 Getting Started

### Prerequisites
* [Nix](https://nixos.org/download.html) with Flakes enabled.
* Vulkan-compatible drivers.

### Build & Run
```bash
# Enter the development shell
nix develop

# Build and run in Debug mode
zig build run

# Build and run with optimizations (Recommended for performance testing)
zig build run -Doptimize=ReleaseSafe
```
---
*Developed by Oséias Batista Pegado*
Software Engineer | Low-level enthusiast | Building on the edge of performance.
