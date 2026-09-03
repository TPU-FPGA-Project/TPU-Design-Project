# Contribution Guidelines

## 👥 Branching & Workspaces
- **Official Students:** Do not push to `main`. Create a feature branch matching your task: `feature/your-name-tpu-module`. Submit a Pull Request (PR) for review.
- **Unnoficial Students:** You do not have write permissions to this repository. Please **Fork** this repository, apply your changes, and submit a cross-repository Pull Request back to our `main` branch.

## 📁 Directory Map & File Placement

To keep the workspace clean, place your files strictly into their designated directories. Never save loose hardware design files or documentation in the root folder.

| Directory | Content to Place Here | What NOT to Place Here |
| :--- | :--- | :--- |
| **`/rtl`** | Custom Verilog (`.v`) and SystemVerilog (`.sv`) core hardware modules. | Simulation testbenches, generated IP bitstreams. |
| **`/sim`** | Verification testbenches, test fixtures, and simulation models. | Production RTL code files. |
| **`/software`** | Python scripts, weight quantization utilities, C firmware/drivers, compilers. | Hardware files or general data sheets. |
| **`/doc`** | Status presentations (`.pptx`), PDFs, data sheets, architectural specs, images. | Code or build tool outputs. |
| **`/.github`** | GitHub actions workflows, issue or bug report markdown templates. | Project source materials. |


## 💾 Saving Your Vivado Progress
Before committing code changes, you must regenerate the project script so others can see your workspace setup. In the Vivado Tcl Console, run:
`write_project_tcl -force recreate_prj.tcl`
Then, commit only your changed `.v` / `.sv` files and the updated `recreate_prj.tcl`.
## 🗂️ Systematic Naming Conventions

To keep our workspace organized and ensure automated Vivado tool scripts compile without path formatting errors, all contributors must strictly follow these file and folder naming rules.

### 🚫 Global Restrictions
- **No Spaces:** Use underscores `_` or hyphens `-` to separate words. Never use spaces.
- **Lowercase Priority:** Stick to lowercase for directory structures and hardware code files.
- **No Special Characters:** Avoid symbols like `#`, `@`, `$`, `%`, `(`, `)`.

---

### 📂 Directory-Specific Naming Rules

#### 1. Hardware Source Files (`/rtl`)
All Verilog and SystemVerilog files must be entirely **lowercase** using **snake_case**. They must explicitly feature the prefix of the TPU sub-component they belong to.
- **Syntax:** `[submodule]_[description].v` or `.sv`
- **Examples:**
  - `systolic_array_element.sv`
  - `matrix_mul_ctrl.v`
  - `activation_relu.sv`

#### 2. Simulation & Testbenches (`/sim`)
Testbench files must mirror the exact name of the RTL file they are verifying, suffixed with `_tb`.
- **Syntax:** `[target_file_name]_tb.sv`
- **Examples:**
  - `systolic_array_element_tb.sv`
  - `activation_relu_tb.sv`

#### 3. Software, Drivers & Compilers (`/software`)
Scripts and runtime drivers must match the standard convention of the target language. Use **snake_case** for Python scripts/C utilities and **PascalCase** for object-oriented languages.
- **Examples:**
  - `tpu_runtime_driver.c`
  - `weight_quantizer.py`

#### 4. Shared Reference Documents & Presentations (`/doc`)
Presentations and architectural reference sheets must use **kebab-case** (hyphens instead of underscores). To keep documents sorted chronologically and clear in scope, use a version tag or date format at the beginning of the filename.
- **Syntax:** `[yyyy_mm]_[topic_name]-[version].[extension]`
- **Examples:**
  - `2026_09_tpu-architecture-spec-v1.2.pdf`
  - `2026_10_fpga-resource-utilization-report.pptx`
  - `hardware-onboarding-guide.md`
## 🔀 Git Commit & Pull Request Conventions

We use a structured naming convention for commits and Pull Requests (PRs) to maintain a highly professional project history. 

### ✉️ 1. Commit Message Structure
Every commit must use the **Conventional Commits** format. It includes a short prefix detailing the type of change, a scope in parentheses indicating the affected folder, and a clear description.

- **Format:** `type(scope): short description in lowercase`
- **Allowed Types:**
  - `feat`: A new feature (e.g., adding a new RTL module).
  - `fix`: A bug fix (e.g., fixing an RTL compilation error or simulation bug).
  - `docs`: Documentation changes only (e.g., updates to README or adding PPTs).
  - `sim`: Adding or improving verification testbenches.
  - `infra`: Repository configuration or build tool adjustments.

- **Examples:**
  - `feat(rtl): implement matrix multiplier accumulator`
  - `fix(sim): resolve boundary condition reset error in accumulator_tb`
  - `docs(doc): upload q4 status presentation slides`

---

### 🚀 2. Pull Request (PR) Naming Rules
When creating a PR to merge your feature branch into the `main` branch, name the PR title using a similar, highly visible structure.

- **Format:** `[Scope] Brief Title Describing the Goal`
- **Examples:**
  - `[RTL] Add ReLU Activation Layer Module`
  - `[SIM] Implement Top-Level TPU Verification Testbench`
  - `[DOC] Add Xilinx Vivado Resource Utilization Report`
  - `[SW] Update Weight Quantization Python Scripts`

---

### 👥 3. The PR Review Process
Before any PR can be merged into the `main` branch, it must fulfill these requirements:
1. **Pass Verification:** The code must compile without errors in Xilinx Vivado.
2. **Peer Review:** At least one official student must review the code, verify the naming conventions are followed, and explicitly hit **Approve**.
3. **No Project Files:** Ensure no temporary Vivado junk files (`.xpr`, `.runs/`, `.jou`, etc.) are included in the file changes.
