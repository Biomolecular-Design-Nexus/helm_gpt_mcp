FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime AS builder

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget && \
    rm -rf /var/lib/apt/lists/*

# Install RDKit via conda
RUN conda install -y -c conda-forge rdkit && conda clean -afy

# Core Python dependencies
RUN pip install --no-cache-dir \
    fastmcp loguru click pandas numpy tqdm \
    scikit-learn scipy

# Clone HELM-GPT repo (model code only, no weights)
RUN mkdir -p repo && \
    for attempt in 1 2 3; do \
      echo "Clone attempt $attempt/3"; \
      git clone --depth 1 https://github.com/charlesxu90/helm-gpt.git repo/helm-gpt && break; \
      if [ $attempt -lt 3 ]; then sleep 5; fi; \
    done

# ---------- Runtime ----------
FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# Copy conda environment (includes RDKit and all pip packages)
COPY --from=builder /opt/conda /opt/conda
COPY --from=builder /app/repo /app/repo

WORKDIR /app

# Copy MCP server source
COPY --chmod=755 src/ src/
COPY --chmod=755 configs/ configs/
COPY --chmod=755 scripts/ scripts/
COPY --chmod=755 examples/data/models/regression_rf.pkl examples/data/models/regression_rf.pkl
COPY --chmod=755 examples/data/models/kras_xgboost_reg.pkl examples/data/models/kras_xgboost_reg.pkl
COPY --chmod=755 examples/data/sequences/ examples/data/sequences/

# Create writable directories for jobs/results and model mount point
RUN mkdir -p /app/jobs /app/results /app/models/helmgpt && \
    chmod 777 /app /app/jobs /app/results /app/models/helmgpt

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

ENV NVIDIA_CUDA_END_OF_LIFE=0
ENTRYPOINT []
CMD ["python", "src/server.py"]
