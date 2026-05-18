#!/bin/bash
set -euo pipefail

source /opt/conda/etc/profile.d/conda.sh
conda activate medsam2

MEDSAM2_DIR=/workspace/third_party/MedSAM2
if [[ -f "${MEDSAM2_DIR}/setup.py" ]]; then
  echo "[entrypoint] Installing MedSAM2 from ${MEDSAM2_DIR} ..."
  pip install -e "${MEDSAM2_DIR}[dev]" -q
else
  echo "[entrypoint] WARN: ${MEDSAM2_DIR} not found. Host: git clone https://github.com/bowang-lab/MedSAM2.git third_party/MedSAM2"
fi

exec "$@"
