# build
# 多阶构建
FROM golang:1.14.7-alpine3.12 AS build
MAINTAINER westzhao
# 下载运维/编译工具
WORKDIR /go/src/${owner:-github.com/8710925}/reporter
# ADD . .
# RUN go install -v github.com/8710925/reporter/cmd/grafana-reporter

RUN apk --no-progress --purge --no-cache add --upgrade git && \
# 编译grafana-reporter
    git clone https://${owner:-github.com/8710925}/reporter . \
    && go install -v github.com/8710925/reporter/cmd/grafana-reporter


# create grafana reporter image
FROM alpine:3.12
COPY --from=build /go/src/${owner:-github.com/8710925}/reporter/util/texlive.profile /
COPY --from=build /go/src/${owner:-github.com/8710925}/reporter/util/SIMKAI.ttf /usr/share/fonts/west/

RUN apk --no-progress --purge --no-cache add --upgrade  wget \
    curl \
    fontconfig \
    unzip \
    perl-switch && \
    wget -qO- \
    "https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
    && mv ~/.TinyTeX /opt/TinyTeX \
    && /opt/TinyTeX/bin/*/tlmgr path add \
    && tlmgr path add \
    && chown -R root:adm /opt/TinyTeX \
    && chmod -R g+w /opt/TinyTeX \
    && chmod -R g+wx /opt/TinyTeX/bin \
    && tlmgr update --self --repository http://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet \
    && tlmgr install epstopdf-pkg ctex  everyshi everysel  \
    # Cleanup
    && apk del --purge -qq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /go/src/${owner:-github.com/8710925}/reporter/util/xecjk/* /opt/TinyTeX/texmf-dist/tex/xelatex/xecjk/
COPY --from=build /go/src/${owner:-github.com/8710925}/reporter/util/euenc/* /opt/TinyTeX/texmf-dist/tex/latex/euenc/

RUN fmtutil-sys  --all \
    && texhash \
    && mktexlsr \


COPY --from=build /go/bin/grafana-reporter /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/grafana-reporter","-ip","jmeter-grafana:3000" ]