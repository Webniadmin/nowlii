@echo off
REM Clean Flutter Logs - BufferQueueProducer spam বাদে
echo Starting clean log viewer...
echo Device: RMX3930
echo Filtering out spam logs...
echo ---

adb logcat | findstr /V "BufferQueueProducer OpenGLRenderer chatty EGL libEGL"
