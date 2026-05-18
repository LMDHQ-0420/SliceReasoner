# 使用 CUDA 12.4 基础镜像（MedSAM2 官方推荐）
FROM nvcr.io/nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

# 安装系统依赖（包括 ffmpeg，MedSAM2 可能需要）
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    git \
    vim \
    curl \
    ffmpeg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------- 安装 Miniconda ----------
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh && \
    ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> ~/.bashrc

# ---------- 创建 MedSAM2 的 conda 环境 ----------
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

RUN conda create -n medsam2 python=3.12 -y

# PyTorch + MedSAM2 常用依赖（构建期不 clone GitHub，避免网络超时）
RUN /bin/bash -c "source $CONDA_DIR/etc/profile.d/conda.sh && conda activate medsam2 && \
    pip install torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cu124 && \
    pip install --upgrade pip && \
    pip install \
      hydra-core iopath pillow SimpleITK tqdm scikit-image pandas opencv-python \
      matplotlib tensorboard pycocotools submitit fvcore \
      gradio==3.38.0 ffmpeg-python moviepy \
      requests numpy"

# sam2 源码在容器启动时由 entrypoint 对挂载的 third_party/MedSAM2 做 pip install -e
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate medsam2" >> /root/.bashrc

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash", "-c", "tail -f /dev/null"]
