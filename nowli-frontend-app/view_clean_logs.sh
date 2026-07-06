#!/bin/bash

# Clean Flutter Logs - BufferQueueProducer spam বাদে
echo "🔍 Starting clean log viewer..."
echo "📱 Device: RMX3930"
echo "🚫 Filtering out: BufferQueueProducer, OpenGLRenderer, chatty, EGL"
echo "---"

adb logcat | grep -v -E "BufferQueueProducer|OpenGLRenderer|chatty|EGL|libEGL"
