#!/bin/bash
set -euo pipefail

source /opt/conda/etc/profile.d/conda.sh
conda activate llava-med

cd /workspace/LLaVA-Med

# 挂载宿主机源码后，同步可编辑安装（与 README: pip install -e . 一致）
if [[ -f pyproject.toml ]]; then
  pip install -e . -q
fi

exec "$@"
