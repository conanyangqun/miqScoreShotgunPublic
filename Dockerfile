FROM ubuntu:jammy

MAINTAINER yangqun
LABEL version="0.0.2"

WORKDIR /

RUN apt-get update && \
    apt install -y build-essential \
        cmake \
        curl \
        libncurses5-dev \
        libbz2-dev \
        liblzma-dev \
        zlib1g-dev \
        python3 \
        python3-pip \
        zip \
        git \
    && apt-get clean

RUN mkdir -p /biosoft/bin

# samtools
RUN mkdir -p /biosrc \
    && curl -L  "https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2" -o "samtools-1.17.tar.bz2" \
    && tar xvf "samtools-1.17.tar.bz2" \
    && cd "samtools-1.17" \
    && ./configure --prefix=/biosoft \
    && make \
    && make install \
    && cd /biosoft \
    && rm -r /biosrc

ENV PATH "/biosoft/bin:$PATH"

# minimap2.
RUN mkdir /biosrc \
    && cd /biosrc \
    && curl -L "https://github.com/lh3/minimap2/releases/download/v2.26/minimap2-2.26_x64-linux.tar.bz2" \
        -o minimap2-2.26_x64-linux.tar.bz2 \
    && tar xvf minimap2-2.26_x64-linux.tar.bz2 \
    && mv minimap2-2.26_x64-linux /biosoft \
    && cd / \
    && rm -r /biosrc

ENV PATH "/biosoft/minimap2-2.26_x64-linux/:$PATH"

# bwa.
RUN mkdir /biosrc \
    && cd /biosrc \
    && git clone https://github.com/lh3/bwa.git \
    && cd bwa \
    && make \
    && cd ../ \
    && cp -r bwa /biosoft \
    && cd /biosoft \
    && rm -r /biosrc

ENV PATH "/biosoft/bwa:$PATH"

# set up scripts.
RUN mkdir -p /biosrc/referenceBuild/reference \
    && mkdir /biosoft/miqScoreShotgun

COPY ./reference /biosrc/referenceBuild/reference

COPY ./requirements.txt /biosrc/referenceBuild

# doing expensive and unlikely to change build processes here to speed up testing builds
RUN cd /biosrc/referenceBuild \
    && pip3 install -r requirements.txt \
    && cd reference \
    && echo "Indexing standard genome" \
    && bwa index zrCommunityStandard.fa

# doing cheaper and likely to change build steps now
COPY . /biosoft/miqScoreShotgun

RUN cd /biosoft/miqScoreShotgun \
    && rm -rf reference \
    && mv /biosrc/referenceBuild/reference . 、
    && rm -rf /biosrc

CMD ["python3", "/biosoft/miqScoreShotgun/analyzeStandardReads.py"]
