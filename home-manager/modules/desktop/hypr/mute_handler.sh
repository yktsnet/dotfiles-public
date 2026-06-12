#!/usr/bin/env bash

TYPE=$1

if [ "$TYPE" = "audio" ]; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
        brightnessctl -d platform::mute set 1
    else
        brightnessctl -d platform::mute set 0
    fi
elif [ "$TYPE" = "mic" ]; then
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "MUTED"; then
        brightnessctl -d platform::micmute set 1
    else
        brightnessctl -d platform::micmute set 0
    fi
fi
