# SliceReasoner

医学影像切片推理项目，基于 **LLaVA-Med**（多模态对话）与 **MedSAM2**（分割），通过 Docker Compose 一键编排。

## 前置要求

- Linux + [Docker](https://docs.docker.com/engine/install/) / Docker Compose v2
- NVIDIA GPU + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- 能访问 `nvcr.io`（CUDA 基础镜像）与 Hugging Face（或镜像 `HF_ENDPOINT`）

### Docker 镜像加速（可选）

若 `docker.io/nvidia/cuda` 经 DaoCloud 等加速器返回 `401`，请编辑 `/etc/docker/daemon.json` 去掉失效的 `registry-mirrors`，或把 Dockerfile 中的基础镜像改为 `nvcr.io/nvidia/cuda:...`（当前已采用）。

### 准备第三方代码

```bash
git clone https://github.com/microsoft/LLaVA-Med.git third_party/LLaVA-Med
git clone https://github.com/bowang-lab/MedSAM2.git third_party/MedSAM2
```

## 模型权重

默认从 Hugging Face 下载 `microsoft/llava-med-v1.5-mistral-7b`（约 12GB，缓存到 `~/.cache/huggingface`）。

### 使用本地权重（推荐，若已有 zip）

```bash
cd /path/to/SliceReasoner
mkdir -p models
unzip -q llava-med-v1.5-mistral-7b.zip -d models/
# 确认存在 models/llava-med-v1.5-mistral-7b/config.json
```

编辑 `docker-compose.yml` 中 `llava-worker` 的 `environment` 与 `volumes`，取消注释本地挂载行，并设置：

```yaml
LLAVA_MODEL_PATH=/models/llava-med-v1.5-mistral-7b
```

## 构建与启动

```bash
cd /path/to/SliceReasoner

# 可选：指定 worker 使用的 GPU
export LLAVA_CUDA_DEVICES=0

# 构建镜像（首次较慢，约 30–60 分钟）
docker compose build

# 后台启动：controller + worker + main
docker compose up -d

# 查看状态
docker compose ps
```

## 验证 LLaVA-Med 服务

### 1. 查看 worker 是否在加载模型

```bash
docker logs -f llava-worker
```

成功时可见 `Loading checkpoint shards...`、`Uvicorn running on ...` 等日志。首次从 Hub 下载权重需较长时间。

### 2. 查询已注册模型

```bash
docker exec llava-controller curl -sf -X POST http://localhost:10000/list_models
```

返回 JSON 中应包含 `llava-med-v1.5-mistral-7b`。

### 3. 发送测试消息

```bash
docker exec -it llava-worker bash -lc \
  'python -m llava.serve.test_message \
    --model-name llava-med-v1.5-mistral-7b \
    --controller http://llava-controller:10000'
```

也可进入交互 shell（已默认激活 `llava-med` conda 环境）：

```bash
docker exec -it llava-worker bash
python -m llava.serve.test_message \
  --model-name llava-med-v1.5-mistral-7b \
  --controller http://llava-controller:10000
```

### 4. 确认权重已缓存（Hub 下载方式）

```bash
du -sh ~/.cache/huggingface/hub/models--microsoft--llava-med-v1.5-mistral-7b
```

体积约 12GB+ 表示下载基本完成。

## 使用 MedSAM2（main 容器）

`main` 容器启动时会通过 `entrypoint.sh` 对挂载的 `third_party/MedSAM2` 执行 `pip install -e .`，无需手动安装 `sam2`。

构建 `main` 镜像**不会**从 GitHub clone MedSAM2（避免构建时 SSL 超时）；`sam2` 在容器启动时由 entrypoint 对宿主机 `third_party/MedSAM2` 执行 `pip install -e` 安装。请确保宿主机已有该目录：

```bash
git clone https://github.com/bowang-lab/MedSAM2.git third_party/MedSAM2
```

重建并重启：

```bash
docker compose build main
docker compose up -d main --force-recreate
```

首次启动 main 时 entrypoint 会安装 MedSAM2，可能需 1–3 分钟，可用 `docker logs main` 查看进度。

### 测试 MedSAM2 是否可用

**步骤 1：环境与 sam2 模块**

```bash
docker exec main bash -c \
  'source /opt/conda/etc/profile.d/conda.sh && conda activate medsam2 && \
   python -c "
import torch
import sam2
print(\"PyTorch:\", torch.__version__)
print(\"CUDA:\", torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"\")
print(\"sam2:\", sam2.__file__)
"'
```

**步骤 2：下载 checkpoint（首次）**

```bash
docker exec main bash -c \
  'source /opt/conda/etc/profile.d/conda.sh && conda activate medsam2 && \
   cd /workspace/third_party/MedSAM2 && bash download.sh'
```

或仅下载推荐权重 `MedSAM2_latest.pt`（体积大，需等待）。

**步骤 3：加载模型到 GPU**

```bash
docker exec main bash -c \
  'source /opt/conda/etc/profile.d/conda.sh && conda activate medsam2 && \
   cd /workspace/third_party/MedSAM2 && \
   python -c "
from sam2.build_sam import build_sam2_video_predictor_npz
build_sam2_video_predictor_npz(
    config_file=\"sam2/configs/sam2.1_hiera_t512.yaml\",
    ckpt_path=\"checkpoints/MedSAM2_latest.pt\",
    device=\"cuda\",
)
print(\"MedSAM2 模型加载成功\")
"'
```

**步骤 4：查看推理脚本帮助（有数据后再跑完整推理）**

```bash
docker exec main bash -c \
  'source /opt/conda/etc/profile.d/conda.sh && conda activate medsam2 && \
   cd /workspace/third_party/MedSAM2 && python medsam2_infer_3D_CT.py --help'
```

交互式进入容器：

```bash
docker exec -it main bash
# 已默认 conda activate medsam2
cd /workspace/third_party/MedSAM2
```

## 常用命令

```bash
# 停止所有服务
docker compose down

# 仅重建并重启 LLaVA 相关服务
docker compose build llava-controller
docker compose up -d llava-controller llava-worker

# 查看各服务日志
docker compose logs -f llava-controller
docker compose logs -f llava-worker
docker compose logs -f main
```

## 服务说明

| 容器 | 镜像 | 作用 |
|------|------|------|
| `llava-controller` | `slicereasoner/llava-med:latest` | 调度器，端口 10000 |
| `llava-worker` | 同上 | 加载模型并提供推理，端口 40000 |
| `main` | `slicereasoner-main` | MedSAM2 开发环境，挂载项目根目录 |

## 常见问题

**`ModuleNotFoundError: No module named 'PIL'`**  
`docker exec` 未进入 `llava-med` 环境。请使用上文带 `bash -lc` 的命令，或先 `conda activate llava-med`。镜像重建后 `.bashrc` 会自动激活该环境。

**权重未下载**  
检查 `docker logs llava-worker`；确认 `~/.cache/huggingface` 中有对应模型目录，或改用本地 `models/` 挂载。

**worker 加载 `opt-350m` 或出现 `--host: command not found`**  
`docker-compose.yml` 中 worker 的 `command` 多行引号被拆断，参数未传入。请使用当前仓库中的数组写法后执行 `docker compose up -d llava-worker --force-recreate`。

**构建失败 `CondaToSNonInteractiveError`**  
新版 conda 需接受 ToS，Dockerfile 中已包含 `conda tos accept`。

**修改依赖后**  
需重新构建 LLaVA 镜像：`docker compose build llava-controller && docker compose up -d`。

**`ModuleNotFoundError: No module named 'sam2'`（main 容器）**  
构建镜像时曾 `pip install -e` 后删除 `/tmp/MedSAM2`，导致包失效。请 `docker compose build main && docker compose up -d main --force-recreate`；或临时执行：`pip install -e /workspace/third_party/MedSAM2[dev]`（在 `medsam2` 环境中）。
