#!/bin/bash
# 修复 x11 源 404 问题

rm -f $PREFIX/etc/apt/sources.list.d/x11.list
pkg update
