#=============================================================================
# Copyright (c) 2022-2023 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
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
#=============================================================================

rev=`cat /sys/devices/soc0/revision`

# Configure RT parameters:
# Long running RT task detection is confined to consolidated builds.
# Set RT throttle runtime to 50ms more than long running RT
# task detection time.
# Set RT throttle period to 100ms more than RT throttle runtime.
long_running_rt_task_ms=1200
sched_rt_runtime_ms=`expr $long_running_rt_task_ms + 50`
sched_rt_runtime_us=`expr $sched_rt_runtime_ms \* 1000`
sched_rt_period_ms=`expr $sched_rt_runtime_ms + 100`
sched_rt_period_us=`expr $sched_rt_period_ms \* 1000`
echo $sched_rt_period_us > /proc/sys/kernel/sched_rt_period_us
echo $sched_rt_runtime_us > /proc/sys/kernel/sched_rt_runtime_us

if [ $rev == "1.0" ] || [ $rev == "1.1" ]; then
	echo 556800 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
	echo 576000 > /sys/devices/system/cpu/cpufreq/policy2/scaling_min_freq
	echo 576000 > /sys/devices/system/cpu/cpufreq/policy5/scaling_min_freq
	echo 729600 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
else
	echo 556800 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
	echo 614400 > /sys/devices/system/cpu/cpufreq/policy2/scaling_min_freq
	echo 499200 > /sys/devices/system/cpu/cpufreq/policy5/scaling_min_freq
	echo 672000 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
fi

# Setup cpu.shares to throttle background groups (dex2oat - 2.5% bg ~ 5% sysbg ~ 50% foreground ~ 60%).
echo "1024" > /dev/cpuctl/background/cpu.shares
echo "10240" > /dev/cpuctl/system-background/cpu.shares
echo "512" > /dev/cpuctl/dex2oat/cpu.shares
echo "16384" > /dev/cpuctl/foreground/cpu.shares
echo "20480" > /dev/cpuctl/system/cpu.shares

# We only have /dev/cpuctl/system/cpu.shares system and background groups holding tasks and the groups below are empty.
echo "20480" > /dev/cpuctl/camera-daemon/cpu.shares
echo "20480" > /dev/cpuctl/nnapi-hal/cpu.shares
echo "20480" > /dev/cpuctl/rt/cpu.shares
echo "20480" > /dev/cpuctl/top-app/cpu.shares

# Reduce vm stat interval to reduce jitter.
echo "20" > /proc/sys/vm/stat_interval

# Tune dirty data writebacks.
echo "52428800" > /proc/sys/vm/dirty_background_bytes
echo "209715200" > /proc/sys/vm/dirty_bytes

# Disable page cluster.
echo "0" > /proc/sys/vm/page-cluster

# Set compact_unevictable_allowed to 0 in order to avoid potential stalls that can occur during compactions of unevictable pages, preempt_rt sets it to 0.
echo "0" > /proc/sys/vm/compact_unevictable_allowed

# Set compaction_proactiveness to 0 in order to reduce cpu latency spikes.
echo "0" > /proc/sys/vm/compaction_proactiveness

# Disable oom dump tasks its not desirable for android where we have numerious tasks.
echo "0" > /proc/sys/vm/oom_dump_tasks

# Reset the RT boost, which is 1024 (max) by default.
echo 0 > /proc/sys/kernel/sched_util_clamp_min_rt_default

# configure bus-dcvs
bus_dcvs="/sys/devices/system/cpu/bus_dcvs"

for device in $bus_dcvs/*
do
	cat $device/hw_min_freq > $device/boost_freq
done

for ubwcpbw in $bus_dcvs/UBWCP/*bwmon-ubwcp
do
	echo "5931 7980 10437 16113" > $ubwcpbw/mbps_zones
	echo 4 > $ubwcpbw/sample_ms
	echo 80 > $ubwcpbw/io_percent
	echo 20 > $ubwcpbw/hist_memory
	echo 5 > $ubwcpbw/hyst_length
	echo 1 > $ubwcpbw/idle_length
	echo 30 > $ubwcpbw/down_thres
	echo 0 > $ubwcpbw/guard_band_mbps
	echo 250 > $ubwcpbw/up_scale
	echo 1600 > $ubwcpbw/idle_mbps
	echo 710000 > $ubwcpbw/max_freq
	echo 40 > $ubwcpbw/window_ms
done

for llccbw in $bus_dcvs/LLCC/*bwmon-llcc
do
	echo "4577 7110 9155 12298 14236 16265" > $llccbw/mbps_zones
	echo 4 > $llccbw/sample_ms
	echo 80 > $llccbw/io_percent
	echo 20 > $llccbw/hist_memory
	echo 5 > $llccbw/hyst_length
	echo 1 > $llccbw/idle_length
	echo 30 > $llccbw/down_thres
	echo 0 > $llccbw/guard_band_mbps
	echo 250 > $llccbw/up_scale
	echo 1600 > $llccbw/idle_mbps
	echo 806000 > $llccbw/max_freq
	echo 40 > $llccbw/window_ms
done

for ddrbw in $bus_dcvs/DDR/*bwmon-ddr
do
	echo "2086 5931 7980 10437 12157 14060 16113" > $ddrbw/mbps_zones
	echo 4 > $ddrbw/sample_ms
	echo 80 > $ddrbw/io_percent
	echo 20 > $ddrbw/hist_memory
	echo 5 > $ddrbw/hyst_length
	echo 1 > $ddrbw/idle_length
	echo 30 > $ddrbw/down_thres
	echo 0 > $ddrbw/guard_band_mbps
	echo 250 > $ddrbw/up_scale
	echo 1600 > $ddrbw/idle_mbps
	echo 2736000 > $ddrbw/max_freq
	echo 40 > $ddrbw/window_ms
done

for latfloor in $bus_dcvs/*/*latfloor
do
	echo 25000 > $latfloor/ipm_ceil
done

for l3gold in $bus_dcvs/L3/*gold
do
	echo 4000 > $l3gold/ipm_ceil
done

for l3prime in $bus_dcvs/L3/*prime
do
	echo 20000 > $l3prime/ipm_ceil
done

for qosgold in $bus_dcvs/DDRQOS/*gold
do
	echo 50 > $qosgold/ipm_ceil
done

for qosprime in $bus_dcvs/DDRQOS/*prime
do
	echo 100 > $qosprime/ipm_ceil
done

for ddrprime in $bus_dcvs/DDR/*prime
do
	echo 25 > $ddrprime/freq_scale_pct
	echo 1500 > $ddrprime/freq_scale_floor_mhz
	echo 2726 > $ddrprime/freq_scale_ceil_mhz
done

echo s2idle > /sys/power/mem_sleep
echo N > /sys/devices/system/cpu/qcom_lpm/parameters/sleep_disabled

echo 4 > /proc/sys/kernel/printk

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
	"1")
		echo "Enable console config to $console_config"
		echo 0 > /proc/sys/kernel/printk
	;;
	*)
		echo "Enable console config to $console_config"
	;;
esac

setprop vendor.post_boot.parsed 1
