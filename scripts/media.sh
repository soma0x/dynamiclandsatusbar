#!/usr/bin/env bash

playerctl metadata --format '{{title}}' 2>/dev/null
playerctl metadata --format '{{artist}}' 2>/dev/null
playerctl status 2>/dev/null
playerctl metadata --format '{{mpris:artUrl}}' 2>/dev/null
