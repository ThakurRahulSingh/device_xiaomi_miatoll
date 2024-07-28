#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2020, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#	 * Redistributions of source code must retain the above copyright
#	   notice, this list of conditions and the following disclaimer.
#	 * Redistributions in binary form must reproduce the above copyright
#	   notice, this list of conditions and the following disclaimer in the
#	   documentation and/or other materials provided with the distribution.
#	 * Neither the name of The Linux Foundation nor
#	   the names of its contributors may be used to endorse or promote
#	   products derived from this software without specific prior written
#	   permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Changes from Qualcomm Innovation Center are provided under the following license:
# Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#

function configure_memory_parameters() {
	# Set Memory parameters.

	# Set allocstall_threshold to 0 for all targets.
	echo 0 > /sys/module/vmpressure/parameters/allocstall_threshold

	# Disable wsf for all targets beacause we are using efk.
	# wsf Range : 1..1000 So set to bare minimum value 1.
	echo 1 > /proc/sys/vm/watermark_scale_factor
}

# Set swappiness based the device's RAM size
    RamStr=$(cat /proc/meminfo | grep MemTotal)
    RamMB=$((${RamStr:16:8} / 1024))

    if [ $RamMB -le 4096 ]; then
        echo 150 > /proc/sys/vm/swappiness
    elif [ $RamMB -le 6144 ]; then
        echo 100 > /proc/sys/vm/swappiness
    else
        echo 60 > /proc/sys/vm/swappiness
    fi

# Setting b.L scheduler parameters
echo 25 > /proc/sys/kernel/sched_downmigrate_boosted
echo 25 > /proc/sys/kernel/sched_upmigrate_boosted
echo 95 > /proc/sys/kernel/sched_upmigrate
echo 85 > /proc/sys/kernel/sched_downmigrate

# Enable EAS
echo 1 > /proc/sys/kernel/sched_energy_aware

# configure governor settings for little cluster
echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 500 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us
echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
echo 1248000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
echo 576000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

# configure governor settings for big cluster
echo "schedutil" > /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor
echo 500 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/up_rate_limit_us
echo 20000 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/down_rate_limit_us
echo 1267200 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_freq
echo 652800 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq

# sched_load_boost as -6 is equivalent to target load as 85. It is per cpu tunable.
echo -6 >  /sys/devices/system/cpu/cpu6/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu7/sched_load_boost
echo 85 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_load

# Enable bus-dcvs
for device in /sys/devices/platform/soc
do
	for cpubw in $device/*cpu-cpu-llcc-bw/devfreq/*cpu-cpu-llcc-bw
	do
		echo "bw_hwmon" > $cpubw/governor
		echo "2288 4577 7110 9155 12298 14236" > $cpubw/bw_hwmon/mbps_zones
		echo 4 > $cpubw/bw_hwmon/sample_ms
		echo 68 > $cpubw/bw_hwmon/io_percent
		echo 20 > $cpubw/bw_hwmon/hist_memory
		echo 0 > $cpubw/bw_hwmon/hyst_length
		echo 80 > $cpubw/bw_hwmon/down_thres
		echo 0 > $cpubw/bw_hwmon/guard_band_mbps
		echo 250 > $cpubw/bw_hwmon/up_scale
		echo 1600 > $cpubw/bw_hwmon/idle_mbps
		echo 50 > $cpubw/polling_interval
	done

	for llccbw in $device/*cpu-llcc-ddr-bw/devfreq/*cpu-llcc-ddr-bw
	do
		echo "bw_hwmon" > $llccbw/governor
		echo "1144 1720 2086 2929 3879 5931 6881 8137" > $llccbw/bw_hwmon/mbps_zones
		echo 4 > $llccbw/bw_hwmon/sample_ms
		echo 68 > $llccbw/bw_hwmon/io_percent
		echo 20 > $llccbw/bw_hwmon/hist_memory
		echo 0 > $llccbw/bw_hwmon/hyst_length
		echo 80 > $llccbw/bw_hwmon/down_thres
		echo 0 > $llccbw/bw_hwmon/guard_band_mbps
		echo 250 > $llccbw/bw_hwmon/up_scale
		echo 1600 > $llccbw/bw_hwmon/idle_mbps
		echo 40 > $llccbw/polling_interval
	done

	for npubw in $device/*npu*-npu-ddr-bw/devfreq/*npu*-npu-ddr-bw
	do
		echo 1 > /sys/devices/virtual/npu/msm_npu/pwr
		echo "bw_hwmon" > $npubw/governor
		echo "1144 1720 2086 2929 3879 5931 6881 8137" > $npubw/bw_hwmon/mbps_zones
		echo 4 > $npubw/bw_hwmon/sample_ms
		echo 80 > $npubw/bw_hwmon/io_percent
		echo 20 > $npubw/bw_hwmon/hist_memory
		echo 10 > $npubw/bw_hwmon/hyst_length
		echo 30 > $npubw/bw_hwmon/down_thres
		echo 0 > $npubw/bw_hwmon/guard_band_mbps
		echo 250 > $npubw/bw_hwmon/up_scale
		echo 0 > $npubw/bw_hwmon/idle_mbps
		echo 40 > $npubw/polling_interval
		echo 0 > /sys/devices/virtual/npu/msm_npu/pwr
	done

	#Enable mem_latency governor for L3, LLCC, and DDR scaling
	for memlat in $device/*cpu*-lat/devfreq/*cpu*-lat
	do
		echo "mem_latency" > $memlat/governor
		echo 10 > $memlat/polling_interval
		echo 400 > $memlat/mem_latency/ratio_ceil
	done

	#Enable cdspl3 governor for L3 cdsp nodes
	for l3cdsp in $device/*cdsp-cdsp-l3-lat/devfreq/*cdsp-cdsp-l3-lat
	do
		echo "cdspl3" > $l3cdsp/governor
	done

	#Gold L3 ratio ceil
	echo 4000 > /sys/class/devfreq/soc:qcom,cpu6-cpu-l3-lat/mem_latency/ratio_ceil

	#Enable compute governor for gold latfloor
	for latfloor in $device/*cpu*-ddr-latfloor*/devfreq/*cpu-ddr-latfloor*
	do
		echo "compute" > $latfloor/governor
		echo 10 > $latfloor/polling_interval
	done

done

# cpuset parameters
echo 0-7 > /dev/cpuset/top-app/cpus
echo 0-5,7 > /dev/cpuset/foreground/cpus
echo 4-5 > /dev/cpuset/background/cpus
echo 2-5 > /dev/cpuset/system-background/cpus
echo 2-5 > /dev/cpuset/restricted/cpus

# schedtune parameters
echo 1 > /dev/stune/camera-daemon/schedtune.prefer_idle
echo 0 > /dev/stune/camera-daemon/schedtune.boost
echo 1 > /dev/stune/foreground/schedtune.prefer_idle
echo 0 > /dev/stune/foreground/schedtune.boost
echo 0 > /dev/stune/schedtune.prefer_idle
echo 0 > /dev/stune/schedtune.boost
echo 1 > /dev/stune/top-app/schedtune.prefer_idle
echo 1 > /dev/stune/top-app/schedtune.boost

# Turn on sleep modes
echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled

# Set Memory parameters
configure_memory_parameters

# Post-setup services
setprop vendor.post_boot.parsed 1
