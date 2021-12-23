FROM ubuntu:20.04

#LABEL maintainer="Cedric Gerber <gerber.cedric@gmail.com>"

#Install all packages needed
#http://processors.wiki.ti.com/index.php/Linux_Host_Support_CCSv11

# RUN apt-get update && apt-get install -y \
#     libc6:i386 libusb-0.1-4 libgconf-2-4 libncurses5 libpython2.7 libtinfo5

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y apt-utils && \
    apt-get install -y \
    wget curl \
    libc6:i386 libusb-0.1-4 libgconf-2-4 libncurses5 libpython2.7 libtinfo5
  
# Python setup
#RUN add-apt-repository ppa:jonathonf/python-3.6
#RUN apt-get update && apt-get install -y \
#  python3-pip               \
#  python3.6
# RUN pip3 install --upgrade pip
# RUN pip3 install teamcity-messages

# Install missing library
WORKDIR /ccs_install

# RUN export JAVA_TOOL_OPTIONS=-Xss1280k

# Install ccs in unattended mode
#https://e2e.ti.com/support/development_tools/code_composer_studio/f/81/t/374161

ENV PATH="/scripts:${PATH}"


# This is stored on our private server as TI requires authentication and LFS is not supported on docker with github
# RUN wget -q https://roomziodevops.blob.core.windows.net/public/simplelink_cc32xx_sdk_5_20_00_06.run \
#     && chmod 777 /ccs_install/simplelink_cc32xx_sdk_5_20_00_06.run \
#     && /ccs_install/simplelink_cc32xx_sdk_5_20_00_06.run --mode unattended \
#     && rm -rf /ccs_install/

# Download and install CCS
#ADD CCS9.2.0.00013_linux-x64 /ccs_install
#RUN /ccs_install/ccs_setup_9.2.0.00013.bin --mode unattended --prefix /opt/ti --enable-components PF_MSP430,PF_CC3X


RUN curl -L https://software-dl.ti.com/ccs/esd/CCSv11/CCS_11_1_0/exports/CCS11.1.0.00011_linux-x64.tar.gz | tar xvz --strip-components=1 -C /ccs_install \
    && /ccs_install/ccs_setup_11.1.0.00011.run --mode unattended --prefix /opt/ti --enable-components PF_C28 \
    && rm -rf /ccs_install/
#This fails silently: check result somehow



#find them here: https://www.ti.com/tool/TI-CGT
#Install latest compiler
RUN cd /ccs_install \
    && wget -q https://software-dl.ti.com/codegen/esd/cgt_public_sw/C2000/21.6.0.LTS/ti_cgt_c2000_21.6.0.LTS_linux-x64_installer.bin \
    && chmod 777 /ccs_install/ti_cgt_c2000_21.6.0.LTS_linux-x64_installer.bin \
    && ls -l /ccs_install \
    && /ccs_install/ti_cgt_c2000_21.6.0.LTS_linux-x64_installer.bin --prefix /opt/ti --unattendedmodeui minimal \
    && rm -rf /ccs_install/

ENV PATH="/opt/ti/ccs/eclipse:${PATH}"

# workspace folder for CCS
RUN mkdir /workspace

# directory for the ccs project
VOLUME /workdir
WORKDIR /workdir

# Pre compile libraries needed for the msp to avoid 6min compile during each build
#ENV PATH="${PATH}:/opt/ti/ccs/tools/compiler/ti-cgt-msp430_20.2.4.LTS/bin"

#RUN /opt/ti/ti-cgt-msp430_20.2.5.LTS/lib/mklib --pattern=rts430x_sc_sd_eabi.lib 

# if needed
#ENTRYPOINT []

# NOTE: need to copy or hard link files to this directory
ARG TI_MOTOR_SDK=C2000Ware_MotorControl_SDK_3_03_00_00
COPY $TI_MOTOR_SDK/ /ti/$TI_MOTOR_SDK/

# https://software-dl.ti.com/ccs/esd/documents/ccs_projects-command-line.html
RUN ccstudio -nosplash -application com.ti.common.core.initialize \
    -ccs.productDiscoveryPath "/ti/$TI_MOTOR_SDK"



# to run gui
# apt install libswt-gtk-4-java
# xhost local:docker
# docker run -it --env="DISPLAY" --network=host leemagnusson/ccs ccstudio
# View