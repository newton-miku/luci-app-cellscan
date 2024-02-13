#!/bin/ash

PROGRAM="RM520N_CELLSCAN"

lockfile=/tmp/cellscanlock

# 检查是否存在 /tmp/celltime 文件，以及文件中的时间戳
if [ -e /tmp/celltime ]; then
    celltime=$(cat /tmp/celltime)
    current_time=$(date +%s)
    time_difference=$((current_time - celltime))
    
    # 如果时间差小于20秒，则直接退出脚本
    if [ $time_difference -lt 20 ]; then
        echo "时间间隔小于20秒，使用缓存结果"
        exit 0
    fi
fi

if [ -e ${lockfile} ]; then
    if kill -9 $(cat ${lockfile}); then
        echo "Cell scanning is already Kill it."
        rm -f ${lockfile}
    else
        echo "Removing stale lock file."
        rm -f ${lockfile}
    fi
fi

echo $$ >${lockfile}
pid=$(cat ${lockfile})
>/tmp/kpcellinfo
echo "开始基站扫描...请坐和放宽"
# 获取当前时间的时间戳
timestamp=$(date +%s)
echo $timestamp > /tmp/celltime
echo -e 'at+qscan=3,0\r\n' >/dev/ttyUSB2

timeout 180 cat /dev/ttyUSB2 | while read line; do
    case "$line" in "+QSCAN"*)
        operatorCode=$(echo $line | awk -F ',' '{print $2$3}')
        case "$operatorCode" in
        "46000" | "46002" | "46007" | "46008" | "46020")
            operator="中国移动"
            ;;
        "46001" | "46006" | "46009")
            operator="中国联通"
            ;;
        "46003" | "46005" | "46011")
            operator="中国电信"
            ;;
        "46015")
            operator="中国广电"
            ;;
        *)
            operator="未知运营商"
            ;;
        esac
        echo "$line" | awk -F ',' -v operator="$operator" '{printf("%s,%s,%s,%s,%s,%s\n", $1, operator, $4, $5, $6, $7)}' >> /tmp/kpcellinfo
        ;;
    esac
    case "$line" in *"OK"*)
        echo "<br>基站扫描完成"
        # 格式化输出基站信息供用户选择
        # awk '{print NR, $0}' /tmp/kpcellinfo
        rm -f ${lockfile}
        kill -9 $pid
        exit 0
        ;;
    esac
done

rm -f ${lockfile}
