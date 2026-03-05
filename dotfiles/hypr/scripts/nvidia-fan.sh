#!/usr/bin/env bash

# Set NVIDIA fan speed to 40% (Wayland/XWayland)
xhost si:localuser:root
sudo nvidia-settings -a "*:1[gpu:0]/GPUFanControlState=1" -a "*:1[fan-0]/GPUTargetFanSpeed=40"
xhost -si:localuser:root
