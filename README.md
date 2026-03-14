# HELM-GPT MCP Server

**GPT-based de novo macrocyclic peptide design with HELM support via Docker**

An MCP (Model Context Protocol) server for cyclic peptide analysis and optimization with 21 tools:
- Convert HELM notation to SMILES chemical representations
- Predict membrane permeability (Random Forest) and KRAS binding affinity (XGBoost)
- Optimize peptides via reinforcement learning with HELM-GPT
- Score peptides with external Boltz2/Rosetta servers
- Batch processing and async job management for large-scale virtual screening

## Quick Start with Docker

### Approach 1: Pull Pre-built Image from GitHub

The fastest way to get started. A pre-built Docker image is automatically published to GitHub Container Registry on every release.

```bash
# Pull the latest image
docker pull ghcr.io/macromnex/helm_gpt_mcp:latest

# Register with Claude Code (runs as current user to avoid permission issues)
claude mcp add cycpep-tools -- docker run -i --rm --user `id -u`:`id -g` --gpus all --ipc=host -v `pwd`:`pwd` -v $MACROMNEX_CACHE/model/helmgpt:/app/models/helmgpt:ro -v $MACROMNEX_CACHE/data/helmgpt_data:/app/examples/data ghcr.io/macromnex/helm_gpt_mcp:latest
```

**Note:** Run from your project directory. `` `pwd` `` expands to the current working directory. `$MACROMNEX_CACHE` should point to your cache directory.

**Requirements:**
- Docker with GPU support (`nvidia-docker` or Docker with NVIDIA runtime)
- Claude Code installed
- HELM-GPT model weights in `$MACROMNEX_CACHE/model/helmgpt/` (for optimization tasks)
- Scoring models and sequences in `$MACROMNEX_CACHE/data/helmgpt_data/` (models/*.pkl, sequences/*.csv)

That's it! The HELM-GPT MCP server is now available in Claude Code.

---

### Approach 2: Build Docker Image Locally

Build the image yourself and install it into Claude Code. Useful for customization or offline environments.

```bash
# Clone the repository
git clone https://github.com/MacromNex/helm_gpt_mcp.git
cd helm_gpt_mcp

# Build the Docker image
docker build -t helm_gpt_mcp:latest .

# Register with Claude Code (runs as current user to avoid permission issues)
claude mcp add cycpep-tools -- docker run -i --rm --user `id -u`:`id -g` --gpus all --ipc=host -v `pwd`:`pwd` -v $MACROMNEX_CACHE/model/helmgpt:/app/models/helmgpt:ro -v $MACROMNEX_CACHE/data/helmgpt_data:/app/examples/data helm_gpt_mcp:latest
```

**Note:** Run from your project directory. `` `pwd` `` expands to the current working directory.

**Requirements:**
- Docker with GPU support
- Claude Code installed
- Git (to clone the repository)

**About the Docker Flags:**
- `-i` — Interactive mode for Claude Code
- `--rm` — Automatically remove container after exit
- `` --user `id -u`:`id -g` `` — Runs the container as your current user, so output files are owned by you (not root)
- `--gpus all` — Grants access to all available GPUs
- `--ipc=host` — Uses host IPC namespace for better performance
- `-v `pwd`:`pwd`` — Mounts your project directory so the container can access your data
- `-v $MACROMNEX_CACHE/model/helmgpt:/app/models/helmgpt:ro` — Mounts HELM-GPT prior model weights (read-only)
- `-v $MACROMNEX_CACHE/data/helmgpt_data:/app/examples/data` — Mounts scoring models (pkl) and sequence datasets (csv)

---

## Verify Installation

After adding the MCP server, you can verify it's working:

```bash
# List registered MCP servers
claude mcp list

# You should see 'cycpep-tools' in the output
```

In Claude Code, you can now use all 21 cycpep-tools including:
- `helm_to_smiles` / `predict_permeability` / `predict_kras_binding` (synchronous)
- `submit_helm_to_smiles_batch` / `submit_permeability_batch` / `submit_kras_binding_batch` (async)
- `submit_optimize_peptides` / `check_optimization_requirements` (RL optimization)
- `get_job_status` / `get_job_result` / `get_job_log` / `list_jobs` (job management)

---

## Next Steps

- **Detailed documentation**: See [detail.md](detail.md) for comprehensive guides on:
  - Available MCP tools and parameters
  - Local Python environment setup (alternative to Docker)
  - Script-level usage and CLI examples
  - Configuration file formats
  - Dataset descriptions and demo data
  - Performance characteristics and troubleshooting

---

## Usage Examples

Once registered, you can use the tools directly in Claude Code. Here are some common workflows:

### Example 1: Single Peptide Analysis

```
Analyze the drug properties of this RGD peptide: PEPTIDE1{G.R.G.D.S.P}$$$$

1. Convert to SMILES format
2. Predict membrane permeability
3. Predict KRAS binding affinity
4. Summarize drug discovery potential
```

### Example 2: Dataset Screening

```
Screen the cyclic peptide database at /path/to/peptides.csv:
1. Convert first 50 HELM sequences to SMILES
2. Predict membrane permeability for all
3. Identify top 10 peptides with highest permeability
4. For the top candidates, predict KRAS binding
5. Create a summary table of the best drug candidates
```

### Example 3: RL-based Peptide Optimization

```
I want to optimize cyclic peptides for membrane permeability using reinforcement learning.
Use the prior model at /app/models/helmgpt/perm_agent_final.pt with submit_optimize_peptides,
run for 500 steps, and save results to /path/to/output/.
```

---

## Troubleshooting

**Docker not found?**
```bash
docker --version  # Install Docker if missing
```

**GPU not accessible?**
- Ensure NVIDIA Docker runtime is installed
- Check with `docker run --gpus all ubuntu nvidia-smi`

**Claude Code not found?**
```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code
```

**Model weights not mounted?**
- Ensure `$MACROMNEX_CACHE/model/helmgpt/` contains `perm_agent_final.pt` and `perm_agent_final.json`
- Prediction tools (permeability, KRAS) work without mounted weights — they use built-in sklearn/xgboost models
- Only RL optimization (`submit_optimize_peptides`) requires the mounted prior model

---

## License

This project is based on the [HELM-GPT](https://github.com/charlesxu90/helm-gpt) framework for cyclic peptide design and analysis.
