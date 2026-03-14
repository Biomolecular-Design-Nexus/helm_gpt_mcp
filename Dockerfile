FROM condaforge/miniforge3:latest

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# Install RDKit via conda (the only dep that needs conda)
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

# Copy MCP server source
COPY --chmod=755 src/ src/
COPY --chmod=755 configs/ configs/
COPY --chmod=755 scripts/ scripts/

# Create writable directories for jobs/results and mount points
# - /app/models/helmgpt: mount HELM-GPT prior model weights ($MACROMNEX_CACHE/model/helmgpt)
# - /app/examples/data: mount scoring models and sequences if needed
RUN mkdir -p /app/jobs /app/results /app/models/helmgpt \
             /app/examples/data/models /app/examples/data/sequences && \
    chmod 777 /app /app/jobs /app/results /app/models/helmgpt \
              /app/examples/data/models /app/examples/data/sequences

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

ENTRYPOINT []
CMD ["python", "src/server.py"]
