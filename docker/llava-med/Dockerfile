# CUDA 11.8：与 LLaVA-Med pyproject 中 bitsandbytes==0.41.0 兼容
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    git \
    vim \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh && \
    ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> ~/.bashrc

# 与 README Install 一致：python 3.10 + pip install -e .
RUN conda create -n llava-med python=3.10 -y

# 安装路径与 compose 挂载点一致，避免 editable install 指向已删除目录
WORKDIR /workspace/LLaVA-Med

RUN git clone --depth 1 https://github.com/microsoft/LLaVA-Med.git . && \
    /bin/bash -c "source $CONDA_DIR/etc/profile.d/conda.sh && \
    conda activate llava-med && \
    pip install --upgrade pip && \
    pip install torch==2.1.2 torchvision==0.16.2 --index-url https://download.pytorch.org/whl/cu118 && \
    pip install -e ."

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
