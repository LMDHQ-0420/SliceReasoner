# 使用 CUDA 12.4 基础镜像（MedSAM2 官方推荐）
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

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
# 环境名：medsam2，Python 3.12
RUN conda create -n medsam2 python=3.12 -y

# 激活环境并安装 PyTorch 2.5.1 (CUDA 12.4)
RUN /bin/bash -c "source $CONDA_DIR/etc/profile.d/conda.sh && conda activate medsam2 && \
    pip install torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cu124 && \
    pip install --upgrade pip"

# 预先安装 MedSAM2 项目的依赖（包括可编辑安装）
# 这样后续挂载的代码可以直接使用 MedSAM2 模块
WORKDIR /tmp
RUN git clone https://github.com/bowang-lab/MedSAM2.git && \
    cd MedSAM2 && \
    /bin/bash -c "source $CONDA_DIR/etc/profile.d/conda.sh && conda activate medsam2 && \
    pip install -e \".[dev]\" && \
    pip install gradio==3.38.0 numpy==1.26.3 ffmpeg-python moviepy"

# 清理临时文件
RUN rm -rf /tmp/MedSAM2

# ---------- 安装主项目所需的额外 Python 包 ----------
# 你的主项目可能需要 requests、pandas、opencv 等，在这里统一安装
RUN /bin/bash -c "source $CONDA_DIR/etc/profile.d/conda.sh && conda activate medsam2 && \
    pip install requests pandas numpy opencv-python scikit-image matplotlib tqdm"

# 设置工作目录为挂载的整个项目根目录
WORKDIR /workspace

# 默认保持容器运行，方便进入交互式开发
# 你也可以在 docker-compose 中覆盖 command 直接运行某个脚本
CMD ["/bin/bash", "-c", "tail -f /dev/null"]