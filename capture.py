import os
import subprocess

subprocess.run("adb shell screencap -p /sdcard/screen.png", shell=True)
subprocess.run("adb pull /sdcard/screen.png screen.png", shell=True)
